import argparse
import json
import os
import time
import urllib.request


def request_json(req):
    with urllib.request.urlopen(req, timeout=90) as resp:
        return json.loads(resp.read().decode("utf-8"))


def multipart(fields, files, boundary):
    body = bytearray()
    for name, value in fields.items():
        body.extend(f"--{boundary}\r\n".encode())
        body.extend(f'Content-Disposition: form-data; name="{name}"\r\n\r\n'.encode())
        body.extend(str(value).encode())
        body.extend(b"\r\n")
    for name, path in files.items():
        with open(path, "rb") as f:
            data = f.read()
        body.extend(f"--{boundary}\r\n".encode())
        body.extend(f'Content-Disposition: form-data; name="{name}"; filename="{os.path.basename(path)}"\r\n'.encode())
        body.extend(b"Content-Type: image/png\r\n\r\n")
        body.extend(data)
        body.extend(b"\r\n")
    body.extend(f"--{boundary}--\r\n".encode())
    return bytes(body)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--image", required=True)
    parser.add_argument("--filename", required=True)
    parser.add_argument("--api-key", required=True)
    args = parser.parse_args()

    boundary = "----cutout-boundary"
    body = multipart({"sync": "0"}, {"image_file": args.image}, boundary)
    req = urllib.request.Request(
        "https://techsz.aoscdn.com/api/tasks/visual/segmentation",
        data=body,
        headers={"X-API-KEY": args.api_key, "Content-Type": f"multipart/form-data; boundary={boundary}"},
        method="POST",
    )
    payload = request_json(req)
    task_id = payload["data"]["task_id"]
    result = None
    for _ in range(20):
        time.sleep(2)
        poll = urllib.request.Request(
            f"https://techsz.aoscdn.com/api/tasks/visual/segmentation/{task_id}",
            headers={"X-API-KEY": args.api_key},
        )
        result = request_json(poll)
        state = result.get("data", {}).get("state")
        if state == 1:
            break
        if isinstance(state, int) and state < 0:
            raise SystemExit(json.dumps(result, ensure_ascii=False))
    image_url = result.get("data", {}).get("image") if result else None
    if not image_url:
        raise SystemExit("segmentation timed out")
    with urllib.request.urlopen(image_url, timeout=90) as resp:
        data = resp.read()
    os.makedirs(os.path.dirname(args.filename), exist_ok=True)
    with open(args.filename, "wb") as f:
        f.write(data)
    print(args.filename)


if __name__ == "__main__":
    main()
