import azure.functions as func
import azure.durable_functions as df
from documents.setup import register_documents
from invoices.setup import register_invoices
from storage.setup import register_storage

app = df.DFApp(http_auth_level=func.AuthLevel.ANONYMOUS)

# Register the modular orchestration and activity functions
register_storage(app)
register_invoices(app)
register_documents(app)
