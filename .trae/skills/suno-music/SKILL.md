---
name: "suno-music"
description: "Generates AI music using SUNO API. Invoke when user asks to generate music, create a song, or compose AI music with SUNO."
---

# SUNO Music Generation (SUNO音乐生成)

Generates AI-powered music using the SUNO music generation API at `mcp.suno.cn`.

## When to Invoke

**MUST invoke when user asks to:**
- "生成音乐" / "做一首歌" / "generate music" / "create a song"
- Use SUNO for AI music composition
- Create background music or soundtracks

## API Configuration (Verified)

| Setting | Value |
|---------|-------|
| API Base | `https://mcp.suno.cn` |
| API Key | `sk-78833c47f71bfbbf623606b0c7f31ec68686ba33e1cf5a65cdb6ff71048d` |
| Auth Header | `Authorization: Bearer {API_KEY}` |
| Env Var | `SUNO_CN_API_KEY` |

## Verified Endpoints

### 1. Generate Music

**Endpoint:** `POST https://mcp.suno.cn/mcp/api/generate`

**Request:**

```powershell
$env:SUNO_CN_API_KEY = "sk-78833c47f71bfbbf623606b0c7f31ec68686ba33e1cf5a65cdb6ff71048d"

$body = @{
    prompt = "MUSIC_DESCRIPTION_OR_LYRICS"
    mv = "chirp-fenix"
    title = "SONG_TITLE"
    tags = "STYLE_TAGS"
    instrumental = $true   # $true = pure music, $false = with vocal
    custom_mode = $false   # $true = custom lyrics, $false = AI generates lyrics
} | ConvertTo-Json

Invoke-RestMethod -Uri "https://mcp.suno.cn/mcp/api/generate" -Method Post -Headers @{
    "Authorization" = "Bearer $env:SUNO_CN_API_KEY"
    "Content-Type" = "application/json; charset=utf-8"
} -Body $body
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| prompt | string | Yes | Music description or full lyrics (if custom_mode=true) |
| mv | string | No | Model: chirp-fenix(v5.5)/chirp-crow(v5)/chirp-bluejay(v4.5+)/chirp-v4(v4)/chirp-v3-5(v3.5). Also aliases: v5.5, v5, v4.5 |
| title | string | No | Song title |
| tags | string | No | Style tags like "pop", "electronic", "orchestral" |
| custom_mode | boolean | No | true = custom lyrics mode, default false |
| instrumental | boolean | No | true = instrumental (no vocals), default false |

**Response:**
```json
{
  "serial_nos": ["2053691864116105216", "2053691864116105217"],
  "message": "..."
}
```
- `serial_nos` — Array of task IDs (usually 2)
- Generating takes 30-60 seconds

### 2. Query Task Status

**Endpoint:** `GET https://mcp.suno.cn/mcp/api/task/{serial_no}?wait=45`

```powershell
Invoke-RestMethod -Uri "https://mcp.suno.cn/mcp/api/task/{serial_no}?wait=45" -Headers @{
    "Authorization" = "Bearer $env:SUNO_CN_API_KEY"
} -TimeoutSec 60
```

**Response when complete:**
```json
{
  "tasks": [{
    "status": "success",
    "title": "Song Title",
    "duration": 172.8,
    "play_url": "https://mcp.suno.cn/mcp/audio?t=..."
  }]
}
```

| Field | Description |
|-------|-------------|
| status | "success" = done, "processing"/"queued" = still working |
| title | Song title |
| duration | Length in seconds |
| play_url | Direct audio playback URL |

## Full Workflow

1. User provides: music description/style/mood, or lyrics
2. Set `$env:SUNO_CN_API_KEY` to the API key
3. POST to `/mcp/api/generate` with appropriate parameters
4. Extract `serial_nos` from response
5. GET `/mcp/api/task/{serial_no}?wait=45` — this blocks up to 45s waiting for result
6. Extract `play_url` and `title` from response
7. Present play_url to user

## Verified Test Result

```
Prompt: "Theme music for a white-haired high school girl anime character, 
         melancholic piano with epic orchestral buildup"
Model: chirp-fenix (v5.5)
Tags: anime soundtrack orchestral piano
Instrumental: true

Result: 2 tracks generated (172.8s each), status=success
Play: https://mcp.suno.cn/mcp/audio?t=...
```

## Notes

- NOT MCP JSON-RPC — this is standard HTTP REST API
- Always use `?wait=45` on task queries for efficient polling
- The API key must be set as environment variable `SUNO_CN_API_KEY`
- Two tracks are generated per prompt
- Tracks typically ~2-3 minutes each
