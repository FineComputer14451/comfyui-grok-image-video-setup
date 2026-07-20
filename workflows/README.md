# Workflows (Grok-optimized)

| File | Source | Purpose |
|------|--------|---------|
| `01_grok_refine.json` | Local (core nodes) | Clean + upscale Grok still |
| `02_grok_to_video_wan21.json` | Comfy-Org `image_to_video_wan` | Wan 2.1 I2V |
| `03_grok_to_video_wan22.json` | Comfy-Org `video_wan2_2_14B_i2v` | Wan 2.2 I2V (preferred) |
| `04_face_detail_lock.json` | Local (core + optional Impact) | Face-preserving refine |
| `05_cinematic_upscale.json` | Local (core nodes) | Hero upscale + 1080p target |

Mounted to ComfyUI user workflows: `./workflows` → `/app/user/default/workflows`.

Always set **Load Image** to a file from `input/` produced by Grok Imagine.
