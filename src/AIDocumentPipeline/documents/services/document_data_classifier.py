from azure.identity import DefaultAzureCredential, get_bearer_token_provider
from pdf2image import convert_from_bytes
import base64
from openai import AzureOpenAI
import io
from documents.models.document_classification import Classifications, ClassificationDefinitions
from shared.confidence.openai_confidence import evaluate_confidence as evaluate_confidence_openai
from shared.confidence.confidence_result import ConfidenceResult, OVERALL_CONFIDENCE_KEY

ClassificationConfidenceResult = ConfidenceResult[Classifications | None]


class DocumentDataClassifierOptions:
    """Defines the configuration options for classifying data from a document using Azure OpenAI."""

    def __init__(self, classification_definitions: ClassificationDefinitions, endpoint: str, deployment_name: str, max_tokens: int = 4096, temperature: float = 0.1, top_p: float = 0.1):
        """Initializes a new instance of the DocumentDataClassifierOptions class.

        :param classification_definitions: The classification definitions to use for classifying data from the document.
        :param endpoint: The Azure OpenAI endpoint to use for the request.
        :param deployment_name: The name of the model deployment to use for the request.
        :param max_tokens: The maximum number of tokens to generate in the response. Default is 4096.
        :param temperature: The sampling temperature for the model. Default is 0.1.
        :param top_p: The nucleus sampling parameter for the model. Default is 0.1.
        """

        self.system_prompt = f"""You are an AI assistant that helps detect the boundaries of sub-section or sub-documents using the provided classifications.

- A single classification may span multiple page images.
- A single page image may contain multiple classifications.
- If a page image does not contain a classification, ignore it.

## Classifications
{classification_definitions.model_dump_json()}
"""

        self.endpoint = endpoint
        self.deployment_name = deployment_name
        self.max_tokens = max_tokens
        self.temperature = temperature
        self.top_p = top_p


class DocumentDataClassifier:
    """Defines a class for classifying structured data from a document using Azure OpenAI GPT models that support image inputs."""

    def __init__(self, credential: DefaultAzureCredential):
        """Initializes a new instance of the DocumentDataClassifier class.

        :param credential: The Azure credential to use for authenticating with the Azure OpenAI service.
        """

        self.credential = credential

    def from_bytes(self, document_bytes: bytes, options: DocumentDataClassifierOptions) -> ClassificationConfidenceResult:
        """Classifies the specified document bytes using an Azure OpenAI model.

        :param document_bytes: The byte array content of the document to classify data from.
        :param options: The options for configuring the Azure OpenAI request for classifying data.
        :return: The classification result as a Classifications object.
        """

        client = self.__get_openai_client__(options)

        image_uris = self.__get_document_image_uris__(document_bytes)

        user_content = []

        for i, image_uri in enumerate(image_uris):
            user_content.append({
                "type": "text",
                "text": f"Page {i + 1}:"
            })

            user_content.append({
                "type": "image_url",
                "image_url": {
                    "url": image_uri
                }
            })

        classify_completion = client.beta.chat.completions.parse(
            model=options.deployment_name,
            messages=[
                {
                    "role": "system",
                    "content": options.system_prompt,
                },
                {
                    "role": "user",
                    "content": user_content
                }
            ],
            response_format=Classifications,
            max_tokens=4096,
            temperature=0.1,
            top_p=0.1,
            # Enabled to determine the confidence of the response.
            logprobs=True
        )

        response_obj = classify_completion.choices[0].message.parsed
        response_obj_dict = response_obj.model_dump()

        confidence_openai = evaluate_confidence_openai(
            extract_result=response_obj_dict,
            choice=classify_completion.choices[0]
        )

        return ClassificationConfidenceResult(
            data=response_obj,
            confidence_scores=confidence_openai,
            overall_confidence=confidence_openai[OVERALL_CONFIDENCE_KEY],
        )

    def __get_openai_client__(self, options: DocumentDataClassifierOptions) -> AzureOpenAI:
        token_provider = get_bearer_token_provider(
            self.credential, "https://cognitiveservices.azure.com/.default")

        client = AzureOpenAI(
            api_version="2024-12-01-preview",
            azure_endpoint=options.endpoint,
            azure_ad_token_provider=token_provider)

        return client

    def __get_document_image_uris__(self, document_bytes: bytes) -> list:
        """Converts the specified document bytes to images using the pdf2image library and returns the image URIs.

        To call this method, poppler-utils must be installed on the system.
        """

        pages = convert_from_bytes(document_bytes)

        image_uris = []
        for page in pages:
            byteIO = io.BytesIO()
            page.save(byteIO, format='PNG')
            base64_data = base64.b64encode(byteIO.getvalue()).decode('utf-8')
            image_uris.append(f"data:image/png;base64,{base64_data}")

        return image_uris
