---
name: "game-asset-generator"
description: "Generates game-ready assets by chaining packAI image generation with automatic background removal. Invoke when user wants transparent-background game art."
---

# Game Asset Generator (游戏素材生成)

Generates game-ready visual assets with transparent backgrounds. Chains:
1. **Generate image** via packAI API (using Python scripts in `packy-image-gen/scripts/`)
2. **Remove background** via visual segmentation API (抠图)

**CRITICAL: Always download every generated image to the local working directory. Use Python scripts for image generation — the verified approach.**

## When to Invoke

**MUST invoke when user asks to:**
- "生成游戏素材" / "create game asset" / "生成角色" / "生成精灵"
- Generate character sprites, item icons needing transparent background
- Create cutout-ready game illustrations

## API Configuration

### packAI (Image Generation) — Verified

| Setting | Value |
|---------|-------|
| API Base | `https://www.packyapi.com` |
| API Key | `sk-wTwkLXXqN7rdPn6SjqVimZLGmH1unO3SudZF6GVi6bwNzIWq` |
| Model | `gpt-image-2` |
| Auth | `Authorization: Bearer {KEY}` |

### Two Endpoints (Crucial!)

| Mode | Endpoint | Use For |
|------|----------|---------|
| 文生图 | `POST /v1/images/generations` (JSON) | Generate from text |
| 图生图 | `POST /v1/images/edits` (multipart/form-data) | Edit with reference image |

**⚠️ `/v1/images/generations` does NOT support image-to-image. Any `image_url` passed to it is silently ignored. Only `/v1/images/edits` with actual file upload works for image editing.**

### Python Scripts

| Script | Path | Purpose |
|--------|------|---------|
| Text-to-Image | `packy-image-gen/scripts/generate_image.py` | `POST /v1/images/generations` |
| Image-to-Image | `packy-image-gen/scripts/generate_image_edit.py` | `POST /v1/images/edits` |

### Visual Segmentation (Background Removal) — Verified

| Setting | Value |
|---------|-------|
| Task Endpoint | `POST https://techsz.aoscdn.com/api/tasks/visual/segmentation` |
| Poll Endpoint | `GET https://techsz.aoscdn.com/api/tasks/visual/segmentation/{task_id}` |
| API Key | `wxdn1p112mmgdlwdu` |
| Auth | `X-API-KEY: {KEY}` |

---

## Pipeline Part 1: Generate Base Image (文生图)

Use the Python script — it handles request building, encoding, download, and saving automatically.

### Step 1: Run the Python script

```bash
python "ABSOLUTE_PATH\packy-image-gen\scripts\generate_image.py" \
  --prompt "CHARACTER_DESCRIPTION" \
  --filename "ABSOLUTE_PATH\original.png" \
  --api-key "sk-wTwkLXXqN7rdPn6SjqVimZLGmH1unO3SudZF6GVi6bwNzIWq" \
  --size "1024x1024"
```

The script outputs the saved file path on success.

### Step 2: Verify the output

```powershell
Get-Item "ABSOLUTE_PATH\original.png" | Select-Object Name, Length, LastWriteTime
```

### Step 3: Proceed to Background Removal (Pipeline Part 3)

The `original.png` from Step 1 is fed into the segmentation pipeline below.

---

## Pipeline Part 2: Image Variation (图生图, optional)

If the user wants to edit/transform the generated asset (color change, style change, add elements):

```bash
python "ABSOLUTE_PATH\packy-image-gen\scripts\generate_image_edit.py" \
  --image "ABSOLUTE_PATH\original.png" \
  --prompt "EDIT_INSTRUCTION" \
  --filename "ABSOLUTE_PATH\edited.png" \
  --api-key "sk-wTwkLXXqN7rdPn6SjqVimZLGmH1unO3SudZF6GVi6bwNzIWq" \
  --size "auto"
```

Then use `edited.png` as the input for background removal below.

### Edit Prompt Example

```
"Change the outfit color from black to red. Keep the same character, same pose, same background, same lighting. Only change the color."
```

---

## Pipeline Part 3: Background Removal (抠图)

### Step 4: Create Segmentation Task

```powershell
$segResponse = Invoke-RestMethod `
  -Uri "https://techsz.aoscdn.com/api/tasks/visual/segmentation" `
  -Method Post `
  -Headers @{"X-API-KEY"="wxdn1p112mmgdlwdu"} `
  -Body @{sync=0; image_url="$IMAGE_URL"}
```

Extract `$segResponse.data.task_id`.

**NOTE:** The segmentation API requires an online image URL. After Part 1, the generated image has an online URL from packAI. If you only have a local file and no URL, first upload it somewhere or use the packAI-generated URL.

### Step 5: Poll for Segmentation Result

```powershell
$taskId = "TASK_ID_FROM_STEP4"
$segResult = Invoke-RestMethod -Uri "https://techsz.aoscdn.com/api/tasks/visual/segmentation/$taskId" -Headers @{"X-API-KEY"="wxdn1p112mmgdlwdu"}
```

| `data.state` | Meaning | Action |
|-------------|---------|--------|
| `2` or `4` | Processing | Wait 2 seconds and poll again |
| `1` | **Done** ✅ | Extract `data.image` URL |
| `<0` (negative) | Failed ❌ | Report error, return original only |

### Polling Rules

| Rule | Value |
|------|-------|
| Interval | 2 seconds |
| Max duration | 30 seconds (15 polls) |

### Step 6: Download Cutout Image

```powershell
Invoke-WebRequest -Uri "$CUTOUT_IMAGE_URL" -OutFile "ABSOLUTE_PATH\cutout.png"
```

### Step 7: Present Results

Present to user:
1. **Local original file** — with path and file size
2. **Local cutout file** — transparent background, game-ready, with path and file size
3. **Online URLs** — for reference only (may expire)

---

## Full Pipeline Summary

```
User Prompt → [generate_image.py] → original.png (saved to local)
                                        ↓
                 (optional) [generate_image_edit.py] → edited.png
                                        ↓
                 [POST segmentation task] → Poll → [Download cutout.png]
                                        ↓
                                  Present results
```

---

## Troubleshooting

| Problem | Cause | Solution |
|---------|-------|----------|
| Python script fails | Missing Python or dependencies | Use standard library only — scripts work with any Python 3.x |
| PowerShell escaping errors | JSON in command-line is unreliable | Use Python scripts instead — they handle all encoding |
| Segmentation polling timeout | Processing takes longer than expected | Wait additional 5-10 seconds; return original if still not done |
| HTTP 503 from packAI | Temporary API unavailability | Retry after a few seconds |
| 图生图结果与原图无关 | Used `/v1/images/generations` instead of `/v1/images/edits` | Use `generate_image_edit.py` (multipart upload to `/v1/images/edits`) |
| Cutout is wrong/subject not detected | Segmentation API failed | Return the original image |

## Notes

- **ALWAYS** use `generate_image.py` for text-to-image — Python scripts are the verified reliable approach
- **ALWAYS** use `generate_image_edit.py` for image-to-image — `/v1/images/generations` does NOT do image editing
- **NEVER** use `data:image/png;base64,...` as `image_url` — it silently fails on both endpoints
- **NEVER** pass `image_url` to `/v1/images/generations` expecting image-to-image — use `/v1/images/edits`
- **ALWAYS** download images to local immediately (Python scripts already do this)
- The segmentation API requires an online image URL — use the packAI-generated URL from Part 1
- Online image URLs may expire; local files are the permanent copies

## Verified Test Results

| Test | Prompt | Pipeline | Result |
|------|--------|----------|--------|
| Game sprite | "白色长直发女高中生, anime art style, game character sprite" | Python + Segmentation | ✅ Generated + cutout, ~10s |
| Gothic Lolita | "三次元黑色洛丽塔风格女性" | Python | ✅ Generated, ~2MB PNG |
| Gothic Lolita 全身 | "三次元黑色洛丽塔站立全身像" | Python | ✅ Generated, ~1.9MB PNG |
| 黑色→粉色 | Edit with reference image | Python `/v1/images/edits` | ✅ 正确编辑, ~2.1MB PNG |
