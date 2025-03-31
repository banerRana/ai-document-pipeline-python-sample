from __future__ import annotations
from typing import Optional
from pydantic import BaseModel, Field


class Classification(BaseModel):
    """
    A class representing a classification of a collection of page images from a document.
    """

    classification: Optional[str] = Field(
        description='Classification of the page, e.g., invoice, receipt, etc.'
    )
    image_range_start: Optional[int] = Field(
        description='If a single document associated with the classification spans multiple pages, this field specifies the start of the image range, e.g., 1.'
    )
    image_range_end: Optional[int] = Field(
        description='If a single document associated with the classification spans multiple pages, this field specifies the end of the image range, e.g., 20.'
    )

    @staticmethod
    def to_json(obj: Classification) -> str:
        return obj.model_dump_json()

    @staticmethod
    def from_json(json_str: str) -> Classification:
        return Classification.model_validate_json(json_str)


class Classifications(BaseModel):
    """
    A class representing a list of document page image classifications.
    """

    page_classifications: list[Classification] = Field(
        description='List of document page image classifications.'
    )

    @staticmethod
    def to_json(obj: Classifications) -> str:
        return obj.model_dump_json()

    @staticmethod
    def from_json(json_str: str) -> Classifications:
        return Classifications.model_validate_json(json_str)


class ClassificationDefinition(BaseModel):
    """
    A class representing the definition of a classification.
    """

    classification: str = Field(
        description='Classification of the page, e.g., invoice, receipt, etc.'
    )
    description: str = Field(
        description='Description of the classification.'
    )

    @staticmethod
    def to_json(obj: ClassificationDefinition) -> str:
        return obj.model_dump_json()

    @staticmethod
    def from_json(json_str: str) -> ClassificationDefinition:
        return ClassificationDefinition.model_validate_json(json_str)


class ClassificationDefinitions(BaseModel):
    """
    A class representing a list of classification definitions.
    """

    classifications: list[ClassificationDefinition] = Field(
        description='List of classification definitions.'
    )

    @staticmethod
    def to_json(obj: ClassificationDefinitions) -> str:
        return obj.model_dump_json()

    @staticmethod
    def from_json(json_str: str) -> ClassificationDefinitions:
        return ClassificationDefinitions.model_validate_json(json_str)
