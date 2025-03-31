import azure.durable_functions as df
from invoices.activities import validate_invoice, extract_invoice


def register_invoices(app: df.DFApp):
    """Register the invoice-related activities and workflows with the Durable Functions app."""
    app.register_functions(validate_invoice.bp)
    app.register_functions(extract_invoice.bp)
