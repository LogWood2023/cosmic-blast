import os
import time
import io
import wave
from huggingface_hub import InferenceClient

from .base import BaseSFXGenerator, SFXGenerationRequest, SFXGenerationResult


class HuggingFaceSFXGenerator(BaseSFXGenerator):
    def __init__(
        self,
        hf_token: str | None = None,
        default_model: str = "facebook/musicgen-small",
    ):
        self.hf_token = hf_token or os.environ.get("HF_TOKEN") or os.environ.get("HUGGINGFACE_HUB_TOKEN")
        if not self.hf_token:
            raise ValueError(
                "HF_TOKEN 未设置。请设置环境变量 HF_TOKEN 或 HUGGINGFACE_HUB_TOKEN"
            )

        self.default_model = default_model
        self.client = InferenceClient(
            model=default_model,
            token=self.hf_token,
            timeout=120,
        )

    def _get_client(self, model: str) -> InferenceClient:
        return InferenceClient(
            model=model,
            token=self.hf_token,
            timeout=120,
        )

    def generate(
        self,
        request: SFXGenerationRequest,
        max_retries: int = 3,
    ) -> SFXGenerationResult:
        model = request.model or self.default_model
        last_error = None

        for attempt in range(max_retries):
            try:
                client = self._get_client(model)

                prompt = request.prompt
                duration_hint = f"[{request.duration:.1f}s] {prompt}"
                full_prompt = duration_hint

                audio_bytes = client.text_to_audio(
                    prompt=full_prompt,
                )

                if audio_bytes and len(audio_bytes) > 100:
                    wav_bytes, sample_rate = self._ensure_wav_format(audio_bytes, request.duration)

                    return SFXGenerationResult(
                        success=True,
                        audio_data=wav_bytes,
                        sample_rate=sample_rate,
                        metadata={
                            "model": model,
                            "prompt": request.prompt,
                            "duration": request.duration,
                            "attempt": attempt + 1,
                        },
                    )
                elif audio_bytes and len(audio_bytes) <= 100:
                    last_error = "API 返回的音频数据太短，可能是模型暂不支持"
                    if attempt < max_retries - 1:
                        time.sleep(2 ** attempt)
                        continue
                else:
                    last_error = "API 返回空音频数据"
                    if attempt < max_retries - 1:
                        time.sleep(2 ** attempt)
                        continue

            except Exception as e:
                last_error = str(e)
                if "429" in str(e) or "rate limit" in str(e).lower():
                    wait_time = min(60, 5 * (2 ** attempt))
                    time.sleep(wait_time)
                elif attempt < max_retries - 1:
                    wait_time = 2 ** attempt
                    time.sleep(wait_time)

        return SFXGenerationResult(
            success=False,
            error_message=f"生成失败（重试 {max_retries} 次后）: {last_error}",
            metadata={"prompt": request.prompt, "model": model},
        )

    def generate_with_fallback(
        self,
        request: SFXGenerationRequest,
        model_chain: list[str],
        max_retries: int = 2,
    ) -> SFXGenerationResult:
        errors = []
        for model in model_chain:
            current_request = SFXGenerationRequest(
                prompt=request.prompt,
                duration=request.duration,
                model=model,
                extra_params=request.extra_params,
            )
            result = self.generate(current_request, max_retries=max_retries)
            if result.success:
                result.metadata["selected_model"] = model
                result.metadata["model_chain"] = model_chain
                return result
            errors.append(f"{model}: {result.error_message}")

        return SFXGenerationResult(
            success=False,
            error_message="所有候选模型都生成失败: " + " | ".join(errors),
            metadata={
                "prompt": request.prompt,
                "model_chain": model_chain,
                "errors": errors,
            },
        )

    def _ensure_wav_format(self, audio_bytes: bytes, target_duration: float) -> tuple[bytes, int]:
        try:
            with wave.open(io.BytesIO(audio_bytes), "rb") as wf:
                sample_rate = wf.getframerate()
                n_channels = wf.getnchannels()
                sample_width = wf.getsampwidth()
                frames = wf.readframes(wf.getnframes())
            return audio_bytes, sample_rate
        except Exception:
            pass

        sample_rate = 32000
        n_channels = 1
        sample_width = 2

        if len(audio_bytes) < 44:
            num_samples = int(target_duration * sample_rate)
            raw_data = audio_bytes
        else:
            raw_data = audio_bytes

        buf = io.BytesIO()
        with wave.open(buf, "wb") as wf:
            wf.setnchannels(n_channels)
            wf.setsampwidth(sample_width)
            wf.setframerate(sample_rate)
            wf.writeframes(raw_data)

        return buf.getvalue(), sample_rate
