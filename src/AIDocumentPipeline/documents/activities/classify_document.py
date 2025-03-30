"""Classifies a document using a pre-defined set of categories.

This module provides the blueprint for an Azure Function activity that classifies a document using Azure OpenAI.
"""

from __future__ import annotations
from pydantic import Field
from documents.services.document_data_classifier import DocumentDataClassifier, DocumentDataClassifierOptions
from documents.models.document_classification import Classifications, ClassificationDefinitions
from shared.workflows.base_request import BaseRequest
from shared.workflows.validation_result import ValidationResult
from storage.services.azure_storage_client_factory import AzureStorageClientFactory
import shared.identity as identity
from shared import app_settings
import azure.durable_functions as df
import logging
from typing import Optional

name = "ClassifyDocument"
bp = df.Blueprint()
storage_factory = AzureStorageClientFactory(identity.default_credential)
document_classifier = DocumentDataClassifier(identity.default_credential)


@bp.function_name(name)
@bp.activity_trigger(input_name="input", activity=name)
def run(input: Request) -> Optional[Classifications]:
    """Classifies a document using Azure OpenAI.

    :param input: The request containing the container name and blob name of the document.
    :return: The classifications if successful; otherwise, None.
    """

    validation_result = input.validate()
    if not validation_result.is_valid:
        logging.error(f"Invalid input: {validation_result.to_str()}")
        return None

    blob_content = storage_factory.get_blob_content(
        app_settings.azure_storage_account, input.container_name, input.blob_name)

    data = document_classifier.from_bytes(
        blob_content,
        DocumentDataClassifierOptions(
            classification_definitions=input.classification_definitions,
            endpoint=app_settings.azure_openai_endpoint,
            deployment_name=app_settings.azure_openai_chat_deployment,
            max_tokens=4096,
            temperature=0.1,
            top_p=0.1
        ))

    return data


class Request(BaseRequest):
    """Defines the request payload for the `ClassifyDocument` activity."""

    container_name: str = Field(
        description="The name of the container within the storage account.")
    blob_name: str = Field(
        description="The name of the document blob to classify.")
    classification_definitions: ClassificationDefinitions = Field(
        description="The classification definitions to use for classifying the document.")

    def validate(self) -> ValidationResult:
        result = ValidationResult()

        if not self.container_name:
            result.add_error("container_name is required")

        if not self.blob_name:
            result.add_error("blob_name is required")

        if not self.classification_definitions or not self.classification_definitions.classifications or len(self.classification_definitions.classifications) == 0:
            result.add_error("classification_definitions is required")

        return result

    @staticmethod
    def to_json(obj: Request) -> str:
        """
        Convert the Request object to a JSON string.

        For more information on this serialization method for Azure Functions, see:
        https://learn.microsoft.com/en-us/azure/azure-functions/durable/durable-functions-serialization-and-persistence?tabs=python
        """
        return obj.model_dump_json()

    @staticmethod
    def from_json(json_str: str) -> Request:
        """
        Convert a JSON string to an Request object.

        For more information on this serialization method for Azure Functions, see:
        https://learn.microsoft.com/en-us/azure/azure-functions/durable/durable-functions-serialization-and-persistence?tabs=python
        """
        return Request.model_validate_json(json_str)
