import argparse
import base64
import json
import urllib.request


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--image", required=True)
    parser.add_argument("--prompt", required=True)
    parser.add_argument("--filename", required=True)
    parser.add_argument("--api-key", required=True)
    parser.add_argument("--size", default="1024x1024")
    args = parser.parse_args()

    boundary = "----packai-boundary"
    fields = {
        "model": "gpt-image-2",
        "prompt": args.prompt,
        "size": args.size,
    }
    body = bytearray()
    for name, value in fields.items():
        body.extend(f"--{boundary}\r\n".encode())
        body.extend(f'Content-Disposition: form-data; name="{name}"\r\n\r\n'.encode())
        body.extend(str(value).encode())
        body.extend(b"\r\n")
    with open(args.image, "rb") as f:
        data = f.read()
    body.extend(f"--{boundary}\r\n".encode())
    body.extend(b'Content-Disposition: form-data; name="image"; filename="input.png"\r\n')
    body.extend(b"Content-Type: image/png\r\n\r\n")
    body.extend(data)
    body.extend(b"\r\n")
    body.extend(f"--{boundary}--\r\n".encode())

    req = urllib.request.Request(
        "https://www.packyapi.com/v1/images/edits",
        data=bytes(body),
        headers={
            "Authorization": f"Bearer {args.api_key}",
            "Content-Type": f"multipart/form-data; boundary={boundary}",
        },
        method="POST",
    )
    with urllib.request.urlopen(req, timeout=180) as resp:
        payload = json.loads(resp.read().decode("utf-8"))
    item = payload["data"][0]
    if "b64_json" in item:
        img = base64.b64decode(item["b64_json"])
    else:
        with urllib.request.urlopen(item["url"], timeout=60) as img_resp:
            img = img_resp.read()
    with open(args.filename, "wb") as f:
        f.write(img)
    print(args.filename)


if __name__ == "__main__":
    main()
