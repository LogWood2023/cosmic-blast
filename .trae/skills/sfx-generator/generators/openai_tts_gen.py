import io
import os
import time
import wave

from openai import OpenAI

from .base import BaseSFXGenerator, SFXGenerationRequest, SFXGenerationResult


class OpenAITTSGenerator(BaseSFXGenerator):
    def __init__(
        self,
        api_key: str | None = None,
        base_url: str | None = None,
        default_model: str = "gpt-4o-mini-tts",
    ):
        self.api_key = api_key or os.environ.get("OPENAI_API_KEY")
        if not self.api_key:
            raise ValueError("OPENAI_API_KEY 未设置。请在 .env 中设置 OPENAI_API_KEY 或通过 --openai-api-key 传入")

        self.default_model = default_model
        self.client = OpenAI(
            api_key=self.api_key,
            base_url=base_url or os.environ.get("OPENAI_BASE_URL"),
        )

    def generate(self, request: SFXGenerationRequest, max_retries: int = 3) -> SFXGenerationResult:
        model = request.model or self.default_model
        text = request.extra_params.get("text") or request.prompt
        voice = request.extra_params.get("voice") or "alloy"
        instructions = request.extra_params.get("instructions") or request.prompt
        speed = float(request.extra_params.get("speed") or 1.0)
        last_error = None

        for attempt in range(max_retries):
            try:
                response = self.client.audio.speech.create(
                    model=model,
                    voice=voice,
                    input=text,
                    instructions=instructions,
                    response_format="wav",
                    speed=max(0.25, min(4.0, speed)),
                )
                audio_data = response.read()
                sample_rate = self._read_sample_rate(audio_data)

                return SFXGenerationResult(
                    success=True,
                    audio_data=audio_data,
                    sample_rate=sample_rate,
                    metadata={
                        "backend": "openai_tts",
                        "model": model,
                        "voice": voice,
                        "text": text,
                        "instructions": instructions,
                        "speed": speed,
                        "attempt": attempt + 1,
                    },
                )
            except Exception as e:
                last_error = str(e)
                if attempt < max_retries - 1:
                    time.sleep(min(30, 2 ** attempt))

        return SFXGenerationResult(
            success=False,
            error_message=f"OpenAI TTS 生成失败（重试 {max_retries} 次后）: {last_error}",
            metadata={"backend": "openai_tts", "model": model, "voice": voice, "text": text},
        )

    def _read_sample_rate(self, audio_data: bytes) -> int:
        try:
            with wave.open(io.BytesIO(audio_data), "rb") as wf:
                return wf.getframerate()
        except Exception:
            return 24000
