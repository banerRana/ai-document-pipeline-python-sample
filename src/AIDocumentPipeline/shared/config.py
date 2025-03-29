"""Environment variable configuration for the Azure Functions.

This module provides a configuration object that reads environment variables from the `local.settings.json` file when running locally, and from the Azure Function App settings when running in Azure.
"""

import os

otlp_exporter_endpoint = os.environ.get("OTLP_EXPORTER_ENDPOINT", None)
openai_endpoint = os.environ.get("AZURE_OPENAI_ENDPOINT", None)
openai_completion_deployment = os.environ.get(
    "AZURE_OPENAI_CHAT_DEPLOYMENT", None)
managed_identity_client_id = os.environ.get("AZURE_CLIENT_ID", None)
invoices_storage_account_name = os.environ.get(
    "AZURE_STORAGE_ACCOUNT", None)
invoices_queue_connection = os.environ.get(
    "AZURE_STORAGE_QUEUES_CONNECTION_STRING", None)
