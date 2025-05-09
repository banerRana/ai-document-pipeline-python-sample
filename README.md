# Azure AI Document Processing Pipeline using Python Durable Functions

[![Open in GitHub Codespaces](https://github.com/codespaces/badge.svg)](https://codespaces.new/jamesmcroft/azure-ai-document-pipeline-python-sample?quickstart=1)

This project is a customizable template for building and deploying AI-powered document processing pipelines using Durable Functions orchestrations, incorporating Azure AI services and Azure OpenAI LLMs. It provides a variety of serverless Function activities for document classification and structured data extraction to make it easy to build reliable and accurate workflows to solve complex document processing challenges. If you're looking to automate document processing tasks with AI, this project is a great starting point.

## Table of Contents

- [Why use this project?](#why-use-this-project)
- [Key features](#key-features)
- [Understanding the Pipeline](#understanding-the-pipeline)
  - [Flow](#flow)
  - [Python Pipeline Specifics](#python-pipeline-specifics)
  - [Azure Services](#azure-services)
- [Example pipeline output](#example-pipeline-output)
- [Pre-built Classification & Extraction Scenarios](#pre-built-classification--extraction-scenarios)
- [Additional Use Cases](#additional-use-cases)
- [Setup](#setup)
  - [Setup on GitHub Codespaces](#setup-on-github-codespaces)
  - [Setup on Local Machine](#setup-on-local-machine)
- [Run the sample](#run-the-sample)
  - [Setup the local environment](#setup-the-local-environment)
  - [Setup the complete Azure environment](#setup-the-complete-azure-environment)
  - [Testing the document processing pipeline](#testing-the-document-processing-pipeline)
    - [Via the HTTP trigger](#via-the-http-trigger)
    - [Via the Azure Storage queue](#via-the-azure-storage-queue)
- [FAQ](#faq)
- [Contributing](#contributing)
- [License](#license)

## Why use this project?

Many organizations are looking to automate manual document processing tasks that are time-consuming and error-prone. While it is possible to automate these tasks using existing tools and services, they often require significant effort to set up and maintain.

Large language models have emerged as a powerful tool for general-purpose document processing tasks, able to handle any variety of document type and structure. Utilizing models with multimodal capabilities, such as Azure OpenAI's GPT-4o, enhances the accuracy and reliability of classifying and extracting structure data from documents by incorporating both text and image data.

This project provides the techniques and patterns to combine the capabilities of traditional OCR analysis with the power of LLMs to build a robust document processing pipeline.

## Key features

- [**Durable Functions orchestration**](https://learn.microsoft.com/en-us/azure/azure-functions/durable/durable-functions-overview?tabs=in-process%2Cnodejs-v3%2Cv1-model&pivots=python): The project uses Durable Functions to orchestrate the document processing pipeline, allowing for stateful workflows and parallel processing of documents.
- [**Scalable containerized hosting**](https://learn.microsoft.com/en-us/azure/azure-functions/functions-deploy-container-apps?tabs=acr%2Cbash&pivots=programming-language-python): The project is designed to be deployed as a containerized application using Azure Container Apps, allowing for easy scaling and management of the document processing pipeline.
- **Document data processing**: Many of the core activites for document processing are included by default, and require minimal configuration to customize to your use cases. These include:
  - [**Document data classifier**](./src/AIDocumentPipeline/documents/services/document_data_classifier.py): A service that uses Azure OpenAI's GPT-4o model to classify documents based on their content. This service can be used to classify documents into any categories you define.
  - [**Document data extractor**](./src/AIDocumentPipeline/documents/services/document_data_extractor.py): A service that combines Azure OpenAI's GPT-4o model with Azure AI Document Intelligence to extract structured data from documents using a multimodal approach, combining text and images. This service can be used to extract any structured data you define from documents using Pydantic models to define the expected output schema.
- **Model confidence scores**: Combining Azure AI Document Intelligence's model internal confidence scores with Azure OpenAI's GPT-4o `logprobs` and structured outputs features, the pipeline is able to provide a confidence score for the overall document classification and extraction process. This allows you to validate the accuracy of the results and take action if the confidence score is below a certain threshold, such as sending alerts or raising exceptions for human review.
- **Data validation**: Data is validated at every step of the process, including sub-orchestrations, ensuring that you not only receive the final output, but also the intermediate data at every step of the process.
- **OpenTelemetry**: The pipeline is configured to also support OpenTelemetry for gathering logs, metrics, and traces of the pipeline. This allows for easy monitoring and debugging of the pipeline, as well as integration with Azure Monitor and other observability tools.
- **Flexible configuration**: Using Durable Functions and separating out concerns to individual activities, the pipeline can be easily configured to support any document processing use case. The modular and extensible approach allows you to add or remove activities as needed.
- **Secure backend**: Azure Managed Identity and Azure RBAC least privilege access is used to secure the pipeline and ensure that only authorized services can access the Azure resources used in the pipeline.
- **Infrastructure-as-code**: Azure Bicep modules and PowerShell deployment scripts are provided to define the Azure infrastructure for the document processing pipeline, allowing for easy deployment and management of the resources required.

## Understanding the Pipeline

![Azure AI Document Processing Pipeline](./assets/Flow.png)

This approach takes advantage of the following techniques for document data processing:

- [Document Classification with Azure OpenAI's GPT-4o Vision Capabilities](https://github.com/Azure-Samples/azure-ai-document-processing-samples/blob/main/samples/python/classification/document-classification-gpt-vision.ipynb)
- [Document Extraction using Multi-Modal (Text and Vision) Capabilities combining Azure AI Document Intelligence and Azure OpenAI's GPT-4o](https://github.com/Azure-Samples/azure-ai-document-processing-samples/blob/main/samples/python/extraction/multimodal/document-extraction-gpt-text-and-vision.ipynb)

### Flow

The pipeline is implemented using Durable Functions and consists of the following steps:

- Upload a batch of documents to an Azure Storage blob container.
- Once the documents are uploaded, send a message to the Azure Storage queue containing the container reference to trigger the document processing pipeline.
- The **[Process Document Batch workflow](./src/AIDocumentPipeline/documents/workflows/process_document_batch_workflow.py)** picks up the message from the queue and starts to process the request.
- Firstly, the batch document folders are retrieved from the blob container using the container reference in the message. **See [Get Document Folders](./src/AIDocumentPipeline/documents/activities/get_document_folders.py).**
  - _Note: Access to the Azure Storage account is established via a user-assigned managed identity when deployed in Azure_.
- The initial workflow then triggers the specific document processing workflow for each document folder in the batch in parallel using the **[Process Document workflow](./src/AIDocumentPipeline/documents/workflows/process_document_workflow.py)**. These process the folders as follows:
  - For each folder in the batch:
    - For each file in the folder:
      - Run the [`ClassifyDocument` activity](./src/AIDocumentPipeline/documents/activities/classify_document.py) to classify the content of the file using the [document data classifier service](./src/AIDocumentPipeline/documents/services/document_data_classifier.py), validating the classification against a pre-defined list in the pipeline.
      - If the classification is a valid extraction type, use the [document data extraction service](./src/AIDocumentPipeline/documents/services/document_data_extractor.py) using the Azure OpenAI GPT-4o model and the [strict Structured Outputs feature](https://learn.microsoft.com/en-us/azure/ai-services/openai/how-to/structured-outputs?tabs=python-secure%2Cdotnet-entra-id&pivots=programming-language-python) to extract data based on a JSON schema of a type.
        - In this example, the classification and extraction is setup for invoices, as defined in the [Invoice schema object](./src/AIDocumentPipeline/invoices/models/invoice.py). The invoice data is extracted using the [Invoice extraction activity](./src/AIDocumentPipeline/invoices/activities/extract_invoice.py) which uses the [document data extractor service](./src/AIDocumentPipeline/documents/services/document_data_extractor.py) to extract the data from the document.

Before continuing with this project, please ensure that you have understanding of the following concepts:

### Python Pipeline Specifics

- [Durable Functions](https://learn.microsoft.com/en-us/azure/azure-functions/durable/durable-functions-overview?tabs=in-process%2Cnodejs-v3%2Cv1-model&pivots=python)
- [Using Blueprints in Azure Functions for modular components](https://learn.microsoft.com/en-gb/azure/azure-functions/functions-reference-python?tabs=get-started%2Casgi%2Capplication-level&pivots=python-mode-decorators#blueprints)
- [Azure Functions as Containers](https://learn.microsoft.com/en-us/azure/azure-functions/functions-deploy-container-apps?tabs=acr%2Cbash&pivots=programming-language-python)

### Azure Services

- [Azure Container Apps](https://learn.microsoft.com/en-us/azure/azure-functions/functions-deploy-container-apps?tabs=acr%2Cbash&pivots=programming-language-csharp), used to host the containerized functions used in the document processing pipeline.
  - **Note**: By containerizing the functions app, you can integrate this specific orchestration pipeline into an existing microservices architecture or deploy it as a standalone service.
- [Azure AI Services](https://learn.microsoft.com/en-us/azure/ai-services/what-are-ai-services), a managed service for all Azure AI Services, including Azure OpenAI, deploying the latest GPT-4o model to support vision-based extraction techniques.
  - [Azure OpenAI](https://learn.microsoft.com/en-us/azure/ai-services/openai/overview)
  - [Azure AI Document Intelligence](https://learn.microsoft.com/en-us/azure/ai-services/document-intelligence/overview)
  - **Note**: The GPT-4o model is not available in all Azure OpenAI regions. For more information, see the [Azure OpenAI Service documentation](https://learn.microsoft.com/en-us/azure/ai-services/openai/concepts/models#standard-deployment-model-availability).
- [Azure Storage Account](https://learn.microsoft.com/en-us/azure/storage/common/storage-introduction), used to store the batch of documents to be processed and the extracted data from the documents. The storage account is also used to store the queue messages for the document processing pipeline.
- [Azure Storage Queues](https://learn.microsoft.com/en-us/azure/storage/queues/storage-queues-introduction), used to trigger the Durable Functions workflow for the document processing pipeline. The queue messages contain the container reference to the batch of documents to be processed.
  - **Note**: This component can be replaced with any trigger mechanism you desire that is supported by Azure Functions, including Azure Service Bus, Event Grid, or HTTP triggers.
- [Azure Monitor](https://learn.microsoft.com/en-us/azure/azure-monitor/overview), used to store logs and traces from the document processing pipeline for monitoring and troubleshooting purposes.
- [Azure Container Registry](https://learn.microsoft.com/en-us/azure/container-registry/container-registry-intro), used to store the container images for the document processing pipeline service that will be consumed by Azure Container Apps.
- [Azure User-Assigned Managed Identity](https://learn.microsoft.com/en-us/entra/identity/managed-identities-azure-resources/overview-for-developers?tabs=portal%2Cdotnet), used to authenticate the service deployed in the Azure Container Apps environment to securely access other Azure services without key-based authentication, including the Azure Storage account and Azure OpenAI service.
- [Azure Bicep](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/overview?tabs=bicep), used to create a repeatable infrastructure deployment for the Azure resources.

## Example pipeline output

Below is an example [invoice](./tests/InvoiceBatch/SharpConsulting/2024-05-16.pdf) that needs to be processed by the [document processing pipeline](./src/AIDocumentPipeline/documents/workflows/process_document_workflow.py). By combining the document's text from the Azure AI Document Intelligence `prebuilt-layout` analysis with the document page images using the Azure OpenAI GPT-4o model, the pipeline is able to extract structured data from the document with high accuracy and confidence. For more information on how the confidence scores are calculated, see the [FAQ](#how-are-confidence-scores-calculated) section.

![Example Invoice](./assets/Invoice.png)

```json
{
  "data": {
    "customer_name": "Sharp Consulting",
    "customer_tax_id": null,
    "customer_address": {
      "street": "73 Regal Way",
      "city": "Leeds",
      "state": null,
      "postal_code": "LS1 5AB",
      "country": "UK"
    },
    "shipping_address": null,
    "purchase_order": "15931",
    "invoice_id": "3847193",
    "invoice_date": null,
    "due_date": "2024-05-24",
    "vendor_name": "NEXGEN",
    "vendor_address": null,
    "vendor_tax_id": null,
    "remittance_address": null,
    "subtotal": null,
    "total_discount": null,
    "total_tax": null,
    "invoice_total": {
      "currency_code": "GBP",
      "amount": 293.52
    },
    "payment_term": null,
    "items": [
      {
        "product_code": "MA197",
        "description": "STRETCHWRAP ROLL",
        "quantity": 5,
        "tax": null,
        "unit_price": {
          "currency_code": "GBP",
          "amount": 16.62
        },
        "total": {
          "currency_code": "GBP",
          "amount": 83.1
        }
      },
      {
        "product_code": "ST4086",
        "description": "BALLPOINT PEN MED.",
        "quantity": 10,
        "tax": null,
        "unit_price": {
          "currency_code": "GBP",
          "amount": 2.49
        },
        "total": {
          "currency_code": "GBP",
          "amount": 24.9
        }
      },
      {
        "product_code": "JF9912413BF",
        "description": "BUBBLE FILM ROLL CL.",
        "quantity": 12,
        "tax": null,
        "unit_price": {
          "currency_code": "GBP",
          "amount": 15.46
        },
        "total": {
          "currency_code": "GBP",
          "amount": 185.52
        }
      }
    ]
  },
  "overall_confidence": 0.9886610106263585
}
```

## Pre-built Classification & Extraction Scenarios

The accelerator comes with a pre-built [document processing pipeline](./src/AIDocumentPipeline/documents/workflows/process_document_workflow.py) that will take the folders in an Azure Storage blob container and process each document. It will first classify the document into one of the defined categories in the pipeline, and then extract the structured data from the document using the Azure OpenAI GPT-4o model with multimodal capabilities.

The pipeline is currently configured to process the following document types:

| Document Type                                                                  | Description                                                                                                                                                  |
| ------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| [**Invoice**](./src/AIDocumentPipeline/invoices/activities/extract_invoice.py) | Using a [structured Invoice object](./src/AIDocumentPipeline/invoices/models/invoice.py), invoice documents can be extracted into a standard Invoice schema. |

The classification and extraction processes can be customized to suit your needs, either by modifying the existing code, or introducing new document types and workflows.

## Additional Use Cases

The pipeline can be extended to support any document processing use case, including:

- **Contracts**: Use natural language rules to extract inferred data points from clauses, such as exit dates, renewal terms, and other key information.
- **Bounded/continuous documents**: Ingest single PDFs that contain one or more documents, also known as continuous documents, detect the boundaries of each using classification techniques, and perform extractions on each sub-document.
- **General documents**: Regardless of the document type and format, whether PDF, Word, or scanned image, extract structured data from the files into your own defined schema.

## Setup

The repository contains a [devcontainer](./.devcontainer/README.md) that contains all the necessary tools and dependencies to run the code.

### Setup on GitHub Codespaces

[![Open in GitHub Codespaces](https://github.com/codespaces/badge.svg)](https://codespaces.new/jamesmcroft/azure-ai-document-pipeline-python-sample?quickstart=1)

> [!NOTE]
> After the environment has loaded, you may need to run the following command in the terminal to install the necessary Python dependencies: `pip --disable-pip-version-check --no-cache-dir install --user -r src/AIDocumentPipeline/requirements.txt`

Once the Dev Container is up and running, continue to the [run the sample](#run-the-sample) section.

### Setup on Local Machine

To use the Dev Container, you need to have the following tools installed on your local machine:

- Install [**Visual Studio Code**](https://code.visualstudio.com/download)
- Install [**Docker Desktop**](https://www.docker.com/products/docker-desktop)
- Install [**Remote - Containers**](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers) extension for Visual Studio Code

To setup a local development environment, follow these steps:

> [!IMPORTANT]
> Ensure that Docker Desktop is running on your local machine.

1. Clone the repository to your local machine.
2. Open the repository in Visual Studio Code.
3. Press `F1` to open the command palette and type `Dev Containers: Reopen in Container`.

> [!NOTE]
> After the environment has loaded, you may need to run the following command in the terminal to install the necessary Python dependencies: `pip --disable-pip-version-check --no-cache-dir install --user -r src/AIDocumentPipeline/requirements.txt`

Once the Dev Container is up and running, continue to the [run the sample](#run-the-sample) section.

## Run the sample

The sample project is designed to be deployed as a containerized application using Azure Container Apps. The deployment is defined using Azure Bicep in the [infra folder](./infra/).

The deployment is split into two parts, run by separate PowerShell scripts using the [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli):

- **[Core Infrastructure](./infra/core.bicep)**: Deploys all of the necessary core components that are required for the document processing pipeline, including the Azure AI services, Azure Storage account, Azure Container Registry, and Azure Container Apps environment. See [Deploy Core Infrastructure PowerShell script](./infra/Deploy-Infrastructure.ps1) for deployment via CLI.
- **[Application Deployment](./infra/apps/AIDocumentPipeline/app.bicep)**: Deploys the containerized application to the Azure Container Apps environment. See [Deploy App PowerShell script](./infra/apps/AIDocumentPipeline/Deploy-App.ps1) for deployment via CLI.

### Setup the local environment

To setup an environment locally, simply run the [Setup-Environment.ps1](./Setup-Environment.ps1) script from the root of the project:

> [!IMPORTANT]
> Docker Desktop must be running to setup the necessary local development environment.

```powershell
.\Setup-Environment.ps1 -DeploymentName <DeploymentName> -Location <Location> -IsLocal
```

> [!NOTE]
> The `-SkipInfrastructure` parameter can be used to skip the deployment of the core infrastructure components if they are already deployed. This will use the deployment outputs for the core Azure infrastructure components to configure the local development environment settings.
> E.g. `.\Setup-Environment.ps1 -DeploymentName <DeploymentName> -Location <Location> -IsLocal -SkipInfrastructure`

When configured for local development, you will be granted the following role-based access to your identity scoped to the specific Azure resources:

- **Azure Resource Group**:
  - **Role**: Contributor
- **Azure Key Vault**:
  - **Role**: Key Vault Secrets User
- **Azure AI Services**:
  - **Role**: Cognitive Services User
  - **Role**: Cognitive Services OpenAI User
- **Azure Storage Account**:
  - **Role**: Storage Account Contributor
  - **Role**: Storage Blob Data Contributor
  - **Role**: Storage File Data Privileged Contributor
  - **Role**: Storage Table Data Contributor
  - **Role**: Storage Queue Data Contributor
- **Azure Container Registry**:
  - **Role**: AcrPull
  - **Role**: AcrPush
- **Azure AI Hub/Project**:
  - **Role**: Azure ML Data Scientist

With the local development environment setup, you can open the solution in Visual Studio Code using the Dev Container. The Dev Container contains all the necessary tools and dependencies to run the sample project with F5 debugging support.

### Setup the complete Azure environment

To setup an environment in Azure, simply run the [Setup-Environment.ps1](./Setup-Environment.ps1) script from the root of the project:

```powershell
.\Setup-Environment.ps1 -DeploymentName <DeploymentName> -Location <Location>
```

> [!NOTE]
> The `-SkipInfrastructure` parameter can be used to skip the deployment of the core infrastructure components if they are already deployed. This will skip the core infrastructure deployment and only deploy the application to the Azure Container Apps environment.
> E.g. `.\Setup-Environment.ps1 -DeploymentName <DeploymentName> -Location <Location> -SkipInfrastructure`

When deployed to Azure, the application is assigned a user-assigned managed identity to securely access the Azure resources used in the pipeline. The managed identity is assigned the following role-based access to your identity scoped to the specific Azure resources:

- **Azure Container Registry**:
  - **Role**: AcrPull
- **Azure Storage Account**:
  - **Role**: Storage Account Contributor
  - **Role**: Storage Blob Data Contributor
  - **Role**: Storage File Data Privileged Contributor
  - **Role**: Storage Table Data Contributor
  - **Role**: Storage Queue Data Contributor
- **Azure AI Services**
  - **Role**: Cognitive Services User
  - **Role**: Cognitive Services OpenAI User

### Testing the document processing pipeline

Once an environment is setup, you can run the document processing pipeline by uploading a batch of documents to the Azure Storage blob container and sending a message via a HTTP request or Azure Storage queue containing the container reference.

A batch of invoices is provided in the tests [Invoice Batch folder](./tests/InvoiceBatch/) which can be uploaded into an Azure Storage blob container, locally via Azurite, or in the deployed Azure Storage account.

These files can be uploaded using the Azure VS Code extension or the Azure Storage Explorer.

![Azurite Local Blob Storage Upload](./assets/Local-Blob-Upload.png)

> [!NOTE]
> Upload all of the individual folders into the container, not the individual files. This sample processed a container that contains multiple folders, each representing a customer's data to be processed which may contain one or more invoices.

#### Via the HTTP trigger

To send via HTTP, open the [`tests/HttpTrigger.rest`](./tests/HttpTrigger.rest) file and use the request to trigger the pipeline.

```http
POST http://localhost:7071/api/process-documents
Content-Type: application/json

{
    "container_name": "invoices"
}
```

To run in Azure, replace `http://localhost:7071` with the `appInfo.value.url` value from the [`./infra/apps/AIDocumentPipeline/AppOutputs.json`](./infra/apps/AIDocumentPipeline/AppOutputs.json) file after deployment.

#### Via the Azure Storage queue

To send via the Azure Storage queue, run the [`tests/QueueTrigger.ps1`](./tests/QueueTrigger.ps1) PowerShell script to trigger the pipeline.

This will add the following message to the **invoices** queue in the Azure Storage account, Base64 encoded:

```json
{
  "container_name": "invoices"
}
```

To run in Azure, replace the `az storage message put` command with the following:

```powershell
az storage message put `
    --content $Base64EncodedMessage `
    --queue-name "invoices" `
    --account-name "<storage-account-name>" `
    --auth-mode login `
    --time-to-live 86400
```

The `--account-name` parameter should be replaced with the name of the Azure Storage account deployed in the environment found in the `environmentInfo.value.azureStorageAccount` value from the [`./infra/InfrastructureOutputs.json`](./infra/InfrastructureOutputs.json) file after deployment.

## FAQ

### How are confidence scores calculated?

For Azure OpenAI, confidence scores can be calculated by first enabling the `logprobs` feature in the model request. This will return the log probabilities of the tokens generated by the model, which can be used to calculate a confidence score for structured outputs of the model by comparing the key-value pairs to their generated tokens log probabilities.

> [!NOTE]
> See the [`openai_confidence`](./src/AIDocumentPipeline/shared/confidence/openai_confidence.py) module for the implementation of calculating the confidence score for the Azure OpenAI model using a structured output.

> [!IMPORTANT]
> Do not use prompting to generate confidence scores as part of the generated output, as this will not be a reliable source of truth. The `logprobs` feature is the only reliable technique, using the model's internal mechanisms for evaluating the probability of the tokens that it generates.

For Azure AI Document Intelligence, confidence scores are automatically calculated and returned by models for the words detected in the document. These scores can be combined with the Azure OpenAI model confidence scores to calculate an overall confidence score when combining the two techniques for higher accuracy extractions.

> [!NOTE]
> See the [`document_intelligence_confidence`](./src/AIDocumentPipeline/shared/confidence/document_intelligence_confidence.py) module for the implementation of calculating the confidence score for the Azure AI Document Intelligence model using a structured output.

## Contributing

This project welcomes contributions and suggestions. If you have any issues or feature requests, please open an issue on the GitHub repository.

If you would like to contribute to the project, please fork the repository and create a pull request with your changes. Please ensure that your code follows the existing coding style and includes appropriate tests.

## License

This project is licensed under the MIT License. See the [LICENSE](./LICENSE) file for details.
