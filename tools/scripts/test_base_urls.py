
import os
from openai import OpenAI

api_key = os.environ.get("PACKY_API_KEY", "")
base_url = "https://www.packyapi.com/v1"

models_to_test = [
    "gpt-image-2",
    "default/gpt-image-2",
    "general/gpt-image-2",
    "gen/gpt-image-2",
    "gpt-image-3",
    "dall-e-3",
]

for model in models_to_test:
    print(f"\nTesting model: {model}")
    try:
        client = OpenAI(
            api_key=api_key,
            base_url=base_url,
            timeout=120.0,
        )
        
        response = client.images.generate(
            model=model,
            prompt="simple pixel art test item on bright green background",
            n=1,
            size="512x512",
        )
        print(f"SUCCESS! Got response!")
        print(f"  data: {response}")
        if hasattr(response, "data") and len(response.data) > 0:
            print(f"  image exists!")
    except Exception as e:
        print(f"ERROR: {e}")

print("\nAll models tested!")
