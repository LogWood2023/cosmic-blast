import io
import math
import random
import struct
import wave

from .base import BaseSFXGenerator, SFXGenerationRequest, SFXGenerationResult


class ProceduralSFXGenerator(BaseSFXGenerator):
    def __init__(self, sample_rate: int = 44100):
        self.sample_rate = sample_rate

    def generate(self, request: SFXGenerationRequest, max_retries: int = 3) -> SFXGenerationResult:
        prompt = request.prompt.lower()
        duration = max(0.2, min(request.duration, 8.0))
        category = request.extra_params.get("category", "other")

        try:
            if category == "explosion" or any(k in prompt for k in ["explosion", "blast", "boom", "bomb"]):
                samples = self._explosion(duration)
                kind = "explosion"
            elif category == "weapon" or any(k in prompt for k in ["laser", "shot", "gun", "blaster"]):
                samples = self._weapon(duration, prompt)
                kind = "weapon"
            elif category == "impact" or any(k in prompt for k in ["impact", "hit", "collision", "thud"]):
                samples = self._impact(duration)
                kind = "impact"
            elif category == "ui" or any(k in prompt for k in ["click", "chime", "button", "power-up", "powerup"]):
                samples = self._ui(duration, prompt)
                kind = "ui"
            elif category in {"vehicle", "creature", "ambient", "environment"}:
                samples = self._texture(duration, category)
                kind = category
            else:
                samples = self._texture(duration, "other")
                kind = "other"

            samples = self._normalize(samples, 0.88)
            audio_data = self._to_wav(samples)
            return SFXGenerationResult(
                success=True,
                audio_data=audio_data,
                sample_rate=self.sample_rate,
                metadata={
                    "backend": "procedural",
                    "kind": kind,
                    "prompt": request.prompt,
                    "duration": duration,
                },
            )
        except Exception as e:
            return SFXGenerationResult(
                success=False,
                error_message=f"本地程序化音效生成失败: {e}",
                metadata={"backend": "procedural", "prompt": request.prompt},
            )

    def _explosion(self, duration: float) -> list[float]:
        n = int(duration * self.sample_rate)
        samples = []
        low_phase = random.random() * math.tau
        rumble_phase = random.random() * math.tau
        boom_freq = random.uniform(45, 75)
        rumble_freq = random.uniform(18, 32)
        crack_time = random.uniform(0.015, 0.04)

        last_noise = 0.0
        for i in range(n):
            t = i / self.sample_rate
            x = i / max(1, n - 1)
            attack = min(1.0, t / crack_time)
            body_env = math.exp(-5.2 * x)
            rumble_env = math.exp(-2.4 * x)
            tail_env = math.exp(-8.0 * max(0.0, x - 0.18))

            noise = random.uniform(-1.0, 1.0)
            last_noise = last_noise * 0.78 + noise * 0.22
            crunchy = math.tanh((noise * 0.65 + last_noise * 1.3) * 2.4)

            boom = math.sin(low_phase + math.tau * boom_freq * t) * body_env
            rumble = math.sin(rumble_phase + math.tau * rumble_freq * t) * rumble_env
            crack = crunchy * body_env * attack
            debris = random.uniform(-1.0, 1.0) * tail_env * 0.18

            sample = crack * 0.82 + boom * 0.75 + rumble * 0.42 + debris
            sample = math.tanh(sample * 1.35)
            samples.append(sample)
        return samples

    def _weapon(self, duration: float, prompt: str) -> list[float]:
        n = int(duration * self.sample_rate)
        samples = []
        laser = "laser" in prompt or "blaster" in prompt
        base = random.uniform(700, 1150) if laser else random.uniform(160, 260)
        sweep = random.uniform(900, 1600) if laser else random.uniform(60, 120)
        phase = 0.0
        for i in range(n):
            x = i / max(1, n - 1)
            env = math.exp(-12.0 * x)
            freq = base + sweep * math.exp(-7.0 * x)
            phase += math.tau * freq / self.sample_rate
            tone = math.sin(phase) + 0.4 * math.sin(phase * 2.01)
            noise = random.uniform(-1.0, 1.0) * math.exp(-22.0 * x)
            samples.append(math.tanh((tone * 0.65 + noise * 0.55) * env * 1.8))
        return samples

    def _impact(self, duration: float) -> list[float]:
        n = int(duration * self.sample_rate)
        samples = []
        phase = random.random() * math.tau
        freq = random.uniform(90, 160)
        for i in range(n):
            x = i / max(1, n - 1)
            env = math.exp(-14.0 * x)
            ring_env = math.exp(-5.0 * x)
            phase += math.tau * freq / self.sample_rate
            click = random.uniform(-1.0, 1.0) * env
            ring = math.sin(phase) * ring_env * 0.45
            samples.append(math.tanh((click + ring) * 1.6))
        return samples

    def _ui(self, duration: float, prompt: str) -> list[float]:
        n = int(duration * self.sample_rate)
        samples = []
        chime = "chime" in prompt or "power" in prompt or "ascending" in prompt
        freqs = [660, 880, 1320] if chime else [880, 1320]
        for i in range(n):
            t = i / self.sample_rate
            x = i / max(1, n - 1)
            env = math.exp(-8.5 * x)
            sample = 0.0
            for idx, freq in enumerate(freqs):
                delay = idx * 0.055 if chime else idx * 0.012
                if t >= delay:
                    local = (t - delay) / max(0.001, duration - delay)
                    sample += math.sin(math.tau * freq * t) * math.exp(-10.0 * local) * 0.45
            samples.append(sample * env)
        return samples

    def _texture(self, duration: float, category: str) -> list[float]:
        n = int(duration * self.sample_rate)
        samples = []
        phase = random.random() * math.tau
        freq_map = {
            "vehicle": random.uniform(55, 120),
            "creature": random.uniform(45, 95),
            "ambient": random.uniform(90, 180),
            "environment": random.uniform(80, 140),
            "other": random.uniform(180, 360),
        }
        freq = freq_map.get(category, 180)
        last = 0.0
        for i in range(n):
            x = i / max(1, n - 1)
            env = math.sin(math.pi * min(1.0, x)) ** 0.35
            phase += math.tau * freq / self.sample_rate
            noise = random.uniform(-1.0, 1.0)
            last = last * 0.92 + noise * 0.08
            tone = math.sin(phase + last * 0.8)
            samples.append((tone * 0.35 + last * 0.65) * env * 0.45)
        return samples

    def _normalize(self, samples: list[float], peak: float) -> list[float]:
        max_amp = max((abs(s) for s in samples), default=1.0)
        if max_amp <= 0.00001:
            return samples
        scale = peak / max_amp
        return [max(-1.0, min(1.0, s * scale)) for s in samples]

    def _to_wav(self, samples: list[float]) -> bytes:
        buf = io.BytesIO()
        with wave.open(buf, "wb") as wf:
            wf.setnchannels(1)
            wf.setsampwidth(2)
            wf.setframerate(self.sample_rate)
            frames = bytearray()
            for sample in samples:
                value = int(max(-1.0, min(1.0, sample)) * 32767)
                frames.extend(struct.pack("<h", value))
            wf.writeframes(bytes(frames))
        return buf.getvalue()
