import argparse
import base64
import json
import urllib.request
from pathlib import Path


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--prompt", required=True)
    parser.add_argument("--filename", required=True)
    parser.add_argument("--api-key", required=True)
    parser.add_argument("--size", default="1024x1024")
    args = parser.parse_args()

    payload = json.dumps({
        "model": "gpt-image-2",
        "prompt": args.prompt,
        "size": args.size,
    }).encode("utf-8")
    req = urllib.request.Request(
        "https://www.packyapi.com/v1/images/generations",
        data=payload,
        headers={
            "Authorization": f"Bearer {args.api_key}",
            "Content-Type": "application/json",
        },
        method="POST",
    )
    with urllib.request.urlopen(req, timeout=300) as resp:
        payload = json.loads(resp.read().decode("utf-8"))
    item = payload["data"][0]
    if "b64_json" in item:
        img = base64.b64decode(item["b64_json"])
    else:
        with urllib.request.urlopen(item["url"], timeout=120) as img_resp:
            img = img_resp.read()
    out = Path(args.filename)
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_bytes(img)
    print(out)


if __name__ == "__main__":
    main()
