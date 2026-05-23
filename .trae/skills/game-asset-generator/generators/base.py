from abc import ABC, abstractmethod
from dataclasses import dataclass, field
from typing import Optional


@dataclass
class GenerationRequest:
    prompt: str
    size: str = "1024x1024"
    model: str = "gpt-image2"
    n: int = 1
    extra_params: dict = field(default_factory=dict)


@dataclass
class GenerationResult:
    success: bool
    image_data: Optional[bytes] = None
    image_url: Optional[str] = None
    error_message: Optional[str] = None
    metadata: dict = field(default_factory=dict)


class BaseGenerator(ABC):
    @abstractmethod
    def generate(self, request: GenerationRequest) -> GenerationResult:
        pass
