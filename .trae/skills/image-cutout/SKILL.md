---
name: "image-cutout"
description: "Removes backgrounds from images using visual segmentation API. Invoke when user asks to remove background, cut out an image, or do image matting."
---

# Image Cutout (抠图)

Uses the visual segmentation API from techsz.aoscdn.com to remove image backgrounds.

## When to Invoke

**MUST invoke when user asks to:**
- "抠图" / "去背景" / "remove background"
- Cut out subject from an image
- Extract foreground from an image

## API Configuration (Verified)

| Setting | Value |
|---------|-------|
| API Base | `https://techsz.aoscdn.com` |
| API Key | `wxdn1p112mmgdlwdu` |
| Auth Header | `X-API-KEY: {API_KEY}` |

## Step 1: Create Segmentation Task

**Endpoint:** `POST https://techsz.aoscdn.com/api/tasks/visual/segmentation`

### Request

```bash
curl -k 'https://techsz.aoscdn.com/api/tasks/visual/segmentation' \
  -H 'X-API-KEY: wxdn1p112mmgdlwdu' \
  -F 'sync=0' \
  -F 'image_url=IMAGE_URL'
```

### Response

```json
{
  "status": 200,
  "message": "success",
  "data": {
    "task_id": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
  }
}
```

- `data.task_id` — Used for polling in Step 2 (**primary field to extract**)

## Step 2: Poll for Result

**Endpoint:** `GET https://techsz.aoscdn.com/api/tasks/visual/segmentation/{task_id}`

### Request

```bash
curl -k 'https://techsz.aoscdn.com/api/tasks/visual/segmentation/{task_id}' \
  -H 'X-API-KEY: wxdn1p112mmgdlwdu'
```

### Response States

| `data.state` | Meaning | Action |
|-------------|---------|--------|
| `2` or `4` | Processing | Continue polling |
| `1` | **Completed** ✅ | Extract `data.image` URL |
| `-1`, `-2`, `-3` | Failed | Check `data.state_detail` for reason |

### Success Response

```json
{
  "status": 200,
  "data": {
    "state": 1,
    "state_detail": "Complete",
    "image": "https://wxtechsz.oss-cn-shenzhen.aliyuncs.com/tasks/output/...",
    "foreground_rect": { "x": 0, "y": 16, "width": 400, "height": 584 }
  }
}
```

- `data.image` — The cutout image URL (**primary result**)

### Polling Rules

| Rule | Value |
|------|-------|
| Poll interval | 2 seconds |
| Max polling duration | 30 seconds (15 polls) |
| Stop condition | `data.state == 1` (success) or `state < 0` (error) |

## Full Workflow

1. User provides an image URL
2. POST to create a segmentation task (`sync=0`)
3. Extract `data.task_id` from the response
4. Poll `GET /api/tasks/visual/segmentation/{task_id}` every 2s
5. When `data.state == 1`, extract `data.image` URL
6. Return the cutout image URL to the user

## Notes

- The cutout image URL from OSS has a time-limited signature (~1 hour expiration)
- Save the image locally if long-term storage is needed
