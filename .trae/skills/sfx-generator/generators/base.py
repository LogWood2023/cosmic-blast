from abc import ABC, abstractmethod
from dataclasses import dataclass, field
from typing import Optional


@dataclass
class SFXGenerationRequest:
    prompt: str
    duration: float = 5.0
    model: str = "facebook/musicgen-small"
    extra_params: dict = field(default_factory=dict)


@dataclass
class SFXGenerationResult:
    success: bool
    audio_data: Optional[bytes] = None
    sample_rate: Optional[int] = None
    error_message: Optional[str] = None
    metadata: dict = field(default_factory=dict)


class BaseSFXGenerator(ABC):
    @abstractmethod
    def generate(self, request: SFXGenerationRequest, max_retries: int = 3) -> SFXGenerationResult:
        pass
