import os
import time
import base64
import requests
from openai import OpenAI

from .base import BaseGenerator, GenerationRequest, GenerationResult


class PackyAPIGenerator(BaseGenerator):
    def __init__(
        self,
        api_key: str | None = None,
        base_url: str = "https://www.packyapi.com",
        default_model: str = "gpt-image-2",
    ):
        self.api_key = api_key or os.environ.get("PACKY_API_KEY", "")
        if not self.api_key:
            raise ValueError(
                "PACKY_API_KEY 未设置。请设置环境变量 PACKY_API_KEY 或在初始化时传入 api_key"
            )

        self.base_url = base_url
        self.default_model = default_model
        
        # 检查 base_url 是否已经包含 /v1
        if "/v1" in self.base_url:
            final_base_url = self.base_url
        else:
            final_base_url = f"{self.base_url}/v1"
            
        # 创建 OpenAI 客户端
        self.client = OpenAI(
            api_key=self.api_key,
            base_url=final_base_url,
            timeout=120.0,
        )

    def generate(
        self,
        request: GenerationRequest,
        max_retries: int = 3,
    ) -> GenerationResult:
        model = request.model or self.default_model
        last_error = None

        for attempt in range(max_retries):
            try:
                response = self.client.images.generate(
                    model=model,
                    prompt=request.prompt,
                    n=request.n,
                    size=request.size,
                    response_format="url",
                    **request.extra_params,
                )

                image_data = None
                image_url = None

                # Debug output disabled for cleaner logs

                if hasattr(response, "data") and len(response.data) > 0:
                    item = response.data[0]
                    if hasattr(item, "url") and item.url:
                        image_url = item.url
                        image_data = self._download_image(image_url)
                    elif hasattr(item, "b64_json") and item.b64_json:
                        image_data = base64.b64decode(item.b64_json)

                if image_data:
                    return GenerationResult(
                        success=True,
                        image_data=image_data,
                        image_url=image_url,
                        metadata={
                            "model": model,
                            "size": request.size,
                            "prompt": request.prompt,
                            "attempt": attempt + 1,
                        },
                    )
                else:
                    last_error = "API 返回成功但无图像数据"
                    if attempt < max_retries - 1:
                        time.sleep(2 ** attempt)
                        continue

            except Exception as e:
                import traceback
                traceback.print_exc()
                last_error = str(e)
                if attempt < max_retries - 1:
                    wait_time = 2 ** attempt
                    time.sleep(wait_time)

        return GenerationResult(
            success=False,
            error_message=f"生成失败（重试 {max_retries} 次后）: {last_error}",
            metadata={"prompt": request.prompt, "model": model},
        )

    def _download_image(self, url: str) -> bytes | None:
        try:
            resp = requests.get(url, timeout=60)
            resp.raise_for_status()
            return resp.content
        except Exception:
            return None
