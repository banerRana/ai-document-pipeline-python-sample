"""Defines the configuration settings for the Azure Functions application.

The variables are defined by environment variables configured in the from the `local.settings.json` file when running locally, and from the Azure Function App settings when running in Azure.
"""

import os

otel_exporter_otlp_endpoint = os.environ.get(
    "OTEL_EXPORTER_OTLP_ENDPOINT", None)
azure_aiservices_endpoint = os.environ.get(
    "AZURE_AISERVICES_ENDPOINT", None)
azure_openai_endpoint = os.environ.get("AZURE_OPENAI_ENDPOINT", None)
azure_openai_chat_deployment = os.environ.get(
    "AZURE_OPENAI_CHAT_DEPLOYMENT", None)
azure_client_id = os.environ.get("AZURE_CLIENT_ID", None)
azure_storage_account = os.environ.get(
    "AZURE_STORAGE_ACCOUNT", None)
azure_storage_queues_connection_string = os.environ.get(
    "AZURE_STORAGE_QUEUES_CONNECTION_STRING", None)
