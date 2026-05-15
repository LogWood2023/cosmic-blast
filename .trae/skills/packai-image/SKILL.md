---
name: "packai-image"
description: "Generates AI images using packAI API. Supports text-to-image (via /v1/images/generations) and image-to-image/editing (via /v1/images/edits). Invoke when user asks to generate images, create AI artwork, edit images, or produce illustrations."
---

# packAI Image Generation (packAI生成图片)

Generates images using the packAI API at packyapi.com. Supports both **text-to-image** (文生图) and **image-to-image** (图生图).

**CRITICAL: Always download the generated image to the local working directory after generation.**

## When to Invoke

**MUST invoke when user asks to:**
- "生成图片" / "画一张图" / "generate image" / "create artwork"
- "图生图" / "用这张图生成" / "image-to-image" / "编辑图片" / "换颜色" / "改风格"
- Create AI-generated illustrations or images

## Two Distinct Endpoints (Crucial!)

| Mode | Endpoint | Content-Type | Use For |
|------|----------|-------------|---------|
| 文生图 | `POST /v1/images/generations` | `application/json` | Generate from text only |
| 图生图 | `POST /v1/images/edits` | `multipart/form-data` | Edit/transform with a reference image |

**⚠️ `/v1/images/generations` does NOT support true image-to-image editing.** Any `image_url` passed to it may be ignored. Always use `/v1/images/edits` for image editing tasks.

## API Configuration (Verified)

| Setting | Value |
|---------|-------|
| API Base | `https://www.packyapi.com` |
| API Key | `sk-wTwkLXXqN7rdPn6SjqVimZLGmH1unO3SudZF6GVi6bwNzIWq` |
| Model | `gpt-image-2` |
| Auth Header | `Authorization: Bearer {API_KEY}` |
| Scripts Dir | `{workspace}\packy-image-gen\scripts\` |
| Text-to-Image Script | `generate_image.py` |
| Image-to-Image Script | `generate_image_edit.py` |

---

## Text-to-Image (文生图)

Generate an image from a text prompt only. Use the Python script for reliability:

### Step 1: Call the API via Python script

```bash
python "ABSOLUTE_PATH\packy-image-gen\scripts\generate_image.py" \
  --prompt "YOUR_PROMPT" \
  --filename "output.png" \
  --api-key "sk-wTwkLXXqN7rdPn6SjqVimZLGmH1unO3SudZF6GVi6bwNzIWq" \
  --size "1024x1024"
```

### Step 2: Verify the file

Run `Get-Item` on the output file to confirm size and existence.

### Step 3: Present results

Show local path, file size, and the original prompt used.

---

## Image-to-Image / 图生图 (Verified Working)

Edit or transform an existing image. **MUST use the `/v1/images/edits` endpoint via `multipart/form-data` — this uploads the image file directly.**

### Step 1: Run the Python script

```bash
python "ABSOLUTE_PATH\packy-image-gen\scripts\generate_image_edit.py" \
  --image "ABSOLUTE_PATH\reference.png" \
  --prompt "EDIT_INSTRUCTION" \
  --filename "ABSOLUTE_PATH\output.png" \
  --api-key "sk-wTwkLXXqN7rdPn6SjqVimZLGmH1unO3SudZF6GVi6bwNzIWq" \
  --size "auto"
```

### Step 2: Wait for completion

The `/v1/images/edits` endpoint takes 30-90 seconds. The script has a 360s timeout.

### Step 3: Verify and present

Confirm the file was saved, report size and path.

### Edit Prompt Tips

For best results with image editing, be explicit about:
- **What to change**: "change the dress color from black to pink"
- **What to keep**: "keep the same person, same face, same pose, same background"
- **Scope**: "only change X, do not modify anything else"

Example:
```
"Change the black Gothic Lolita dress to pink. Keep everything else exactly the same - same person, same face, same pose, same background, same lighting, same composition. Only change the dress color from black to pink."
```

---

## Why Our First Two Attempts Failed

| Attempt | Endpoint | Method | Result |
|---------|----------|--------|--------|
| 1st | `/v1/images/generations` | `data:image/png;base64,...` as `image_url` | ❌ API silently ignored base64, pure text-to-image |
| 2nd | `/v1/images/generations` | Online URL as `image_url` | ❌ API ignored reference, pure text-to-image |
| 3rd (correct!) | `/v1/images/edits` | `multipart/form-data` with file upload | ✅ True image editing |

**Root cause**: `/v1/images/generations` does not perform true image-to-image. The `image_url` parameter, if it exists, has no editing effect on this endpoint. Only `/v1/images/edits` with actual file upload via multipart/form-data produces reference-based edits.

---

## Troubleshooting

| Problem | Cause | Solution |
|---------|-------|----------|
| PowerShell escaping errors | JSON with complex prompts breaks in command-line | Use Python scripts instead |
| HTTP 503 | Temporary API unavailability | Retry after a few seconds |
| 图生图结果与原图无关 | Used `/v1/images/generations` instead of `/v1/images/edits` | Use `generate_image_edit.py` with `--image` parameter |
| `/v1/images/edits` 超时 | High-quality processing takes time | Wait up to 90 seconds; timeout is set to 360s |

## Verified Test History

| Test | Type | Endpoint | Result |
|------|------|----------|--------|
| "三次元黑色洛丽塔女性" | Text-to-image | `/v1/images/generations` | ✅ ~2MB |
| "三次元黑色洛丽塔站立全身像" | Text-to-image | `/v1/images/generations` | ✅ ~1.9MB |
| 黑色→粉色 (base64) | Image-to-image | `/v1/images/generations` | ❌ 参考图被忽略 |
| 黑色→粉色 (online URL) | Image-to-image | `/v1/images/generations` | ❌ 参考图被忽略 |
| 黑色→粉色 (file upload) | Image-to-image | `/v1/images/edits` | ✅ 正确编辑, ~2.1MB |

## Notes

- **ALWAYS** use the Python scripts in `packy-image-gen/scripts/` — they handle upload, encoding, and format correctly
- **NEVER** use `/v1/images/generations` for image-to-image — it does not work
- **ALWAYS** use `/v1/images/edits` + `multipart/form-data` for any image editing task
- **ALWAYS** download the image to local immediately (scripts already do this)
- Be explicit in edit prompts about what to change vs. what to preserve
