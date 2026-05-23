import argparse
import json
import os
import time
import urllib.parse
import urllib.request


def request_json(req):
    with urllib.request.urlopen(req, timeout=60) as resp:
        return json.loads(resp.read().decode("utf-8"))


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--image", required=True)
    parser.add_argument("--filename", required=True)
    parser.add_argument("--api-key", required=True)
    parser.add_argument("--image-url", default="")
    args = parser.parse_args()

    image_url = args.image_url
    if not image_url:
        raise SystemExit("segmentation API requires --image-url")

    data = urllib.parse.urlencode({"sync": "0", "image_url": image_url}).encode("utf-8")
    req = urllib.request.Request(
        "https://techsz.aoscdn.com/api/tasks/visual/segmentation",
        data=data,
        headers={"X-API-KEY": args.api_key, "Content-Type": "application/x-www-form-urlencoded"},
        method="POST",
    )
    payload = request_json(req)
    task_id = payload["data"]["task_id"]
    result = None
    for _ in range(15):
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
    image = result.get("data", {}).get("image") if result else None
    if not image:
        raise SystemExit("segmentation timed out")
    os.makedirs(os.path.dirname(args.filename), exist_ok=True)
    with urllib.request.urlopen(image, timeout=60) as resp:
        content = resp.read()
    with open(args.filename, "wb") as f:
        f.write(content)
    print(args.filename)


if __name__ == "__main__":
    main()
