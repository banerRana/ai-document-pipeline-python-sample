"""Processes a document in a folder in a Storage container.

The workflows orchestrate the detection of the document type, and if it's an invoice, extract the invoice data from the folder and save the extracted data to a database.
"""

from __future__ import annotations
from invoices.activities import validate_invoice
from invoices.models.invoice import Invoice
from storage.activities import write_bytes_to_blob
from invoices.activities import extract_invoice
from shared.workflows.workflow_result import WorkflowResult
from documents.activities import classify_document
from documents.models.document_classification import Classifications, ClassificationDefinitions, ClassificationDefinition
from documents.models.document_folder import DocumentFolder
from documents.models.document_batch_request import DocumentBatchRequest
import azure.durable_functions as df
from azure.durable_functions.models.Task import TaskBase
import azure.functions as func
import logging
from documents.activities import get_document_folders
from shared import app_settings

name = "ProcessDocumentWorkflow"
bp = df.Blueprint()


@bp.function_name(name)
@bp.orchestration_trigger(context_name="context", orchestration=name)
def run(context: df.DurableOrchestrationContext):
    # Step 1: Extract the input from the context
    input: DocumentFolder = context.get_input()
    result = WorkflowResult(name=input.name)

    # Step 2: Validate the input
    validation_result = input.validate()
    if not validation_result.is_valid:
        result.merge(validation_result)
        return result

    result.add_message("DocumentFolder.validate", "input is valid")

    # Step 3: Process each file
    for document in input.document_file_names:
        # Classify the document
        classification: Classifications = yield context.call_activity(
            classify_document.name,
            classify_document.Request(
                container_name=input.container_name,
                blob_name=document,
                classification_definitions=ClassificationDefinitions(
                    classifications=[
                        ClassificationDefinition(
                            classification="Invoice",
                            description="A document that serves as a bill for goods or services provided, often used for payment processing and record-keeping."
                        ),
                        ClassificationDefinition(
                            classification="Email",
                            description="A digital message sent electronically, typically containing text, images, or attachments."
                        ),
                        ClassificationDefinition(
                            classification="None",
                            description="No classification available for the document."
                        ),
                    ])))

        if not classification:
            result.add_error(
                classify_document.name,
                f"Failed to classify document {document}.")
            continue

        document_classification_stored = yield context.call_activity(
            write_bytes_to_blob.name,
            write_bytes_to_blob.Request(
                storage_account_name=app_settings.azure_storage_account,
                container_name=input.container_name,
                blob_name=f"{document}.Classification.json",
                content=classification.model_dump_json().encode("utf-8"),
                overwrite=True))

        if not document_classification_stored:
            result.add_error(
                write_bytes_to_blob.name,
                f"Failed to store classification for {document}.")
            continue

        if len(classification.page_classifications) == 0:
            result.add_message(
                classify_document.name,
                f"Document {document} has no valid classifications.")
            continue

        for page_classification in classification.page_classifications:
            result.add_message(
                classify_document.name,
                f"Document {document} classified as {page_classification.classification} from page {page_classification.image_range_start} to {page_classification.image_range_end}.")

            # If the document is classified as an invoice, extract the invoice data
            if page_classification.classification == "Invoice":
                invoice: Invoice = yield context.call_activity(
                    extract_invoice.name,
                    extract_invoice.Request(
                        container_name=input.container_name,
                        blob_name=document,
                        page_range_start=page_classification.image_range_start,
                        page_range_end=page_classification.image_range_end))

                if not invoice:
                    result.add_error(
                        extract_invoice.name,
                        f"Failed to extract invoice data for {document} from page {page_classification.image_range_start} to {page_classification.image_range_end}.")
                    continue

                invoice_stored = yield context.call_activity(
                    write_bytes_to_blob.name,
                    write_bytes_to_blob.Request(
                        storage_account_name=app_settings.azure_storage_account,
                        container_name=input.container_name,
                        blob_name=f"{document}.{page_classification.image_range_start}-{page_classification.image_range_end}.Data.json",
                        content=invoice.model_dump_json().encode("utf-8"),
                        overwrite=True))

                if not invoice_stored:
                    result.add_error(
                        write_bytes_to_blob.name,
                        f"Failed to store invoice data for {document} from page {page_classification.image_range_start} to {page_classification.image_range_end}.")
                    continue

                invoice_validation: validate_invoice.Result = yield context.call_activity(
                    validate_invoice.name,
                    validate_invoice.Request(
                        name=document,
                        data=invoice))

                result.merge(invoice_validation)

                yield context.call_activity(
                    write_bytes_to_blob.name,
                    write_bytes_to_blob.Request(
                        storage_account_name=app_settings.azure_storage_account,
                        container_name=input.container_name,
                        blob_name=f"{document}.{page_classification.image_range_start}-{page_classification.image_range_end}.Validation.json",
                        content=validate_invoice.Result.to_json(
                            invoice_validation).encode("utf-8"),
                        overwrite=True))
            else:
                result.add_message(
                    classify_document.name,
                    f"Skipping {page_classification.classification} document {document}.")
                continue

    return result.model_dump()
