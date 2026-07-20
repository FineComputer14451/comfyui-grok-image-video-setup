# Grok Build → ComfyUI Image & Video Pipeline

**Exclusive for Grok Build / SuperGrokPro users**

This is **not** a general ComfyUI repository.

It is a specialized local bridge designed exclusively for people who generate images and video with **Grok Imagine** and want to take those assets further with local ComfyUI power.

### What this repo is for

| Stage | Tool | Purpose |
|-------|------|---------|
| 1. Hero generation | **Grok Imagine** | Highest quality stills & character lock |
| 2. Refinement | This ComfyUI setup | Upscale, detail, consistency, face fix |
| 3. Video | This ComfyUI setup | Image-to-Video with Wan 2.1 / 2.2 |
| 4. Final polish | Grok Cinematic Studio skills | Color, audio, sequence, delivery |

### Design Philosophy
- Grok Imagine is the source of truth for image quality and character identity.
- ComfyUI is used only as a **post-processing + video engine**.
- No attempt to replace Grok. Only enhance and extend it.
- Optimized for SuperGrokPro quota + local GPU hybrid workflow.

---

## Quick Start (Recommended Path)

### 1. Generate in Grok
Create your best stills with Grok Imagine (use Character DNA / Identity Lock if available).

### 2. Clone this repo
```bash
git clone https://github.com/FineComputer14451/comfyui-grok-image-video-setup.git
cd comfyui-grok-image-video-setup
```

### 3. Launch with Docker (easiest)
```bash
docker compose up -d --build
```
Open → http://localhost:8188

### 4. Drop Grok images into `input/`
Then load one of the workflows from the `workflows/` folder.

---

## Included Workflows (Grok-Optimized)

| File | Purpose |
|------|---------|
| `01_grok_refine.json` | Clean up + upscale a Grok Imagine still |
| `02_grok_to_video_wan21.json` | Image-to-Video using Wan 2.1 |
| `03_grok_to_video_wan22.json` | Image-to-Video using Wan 2.2 (preferred) |
| `04_face_detail_lock.json` | Heavy face restoration while keeping Grok identity |
| `05_cinematic_upscale.json` | High-end upscale + film grain + final grade prep |

All workflows are designed so the **first image you load is a Grok Imagine output**.

---

## Recommended Local Models

Place models in the correct folders under `models/`:

**For refinement**
- Any high-quality upscaler (4x-UltraSharp, RealESRGAN, etc.)
- Face restoration models (CodeFormer / GFPGAN via nodes)

**For video (Wan)**
- `wan2.1_i2v_720p_14B` or newer Wan 2.2 variants
- Matching VAE + CLIP Vision models

See `docs/MODELS.md` for exact download links and placement.

---

## Grok Build Integration Notes

This repo is intentionally lightweight so it works well inside Grok Build / Computer environments:

- Minimal custom nodes (only what is necessary)
- Clear folder structure for Grok → ComfyUI handoff
- Designed to be used after you run cinematic skills (Identity Lock, I2V Specialist, etc.)
- Outputs are ready for the next stage of the Grok Imagine Cinematic Studio pipeline

---

## Directory Structure

```
comfyui-grok-image-video-setup/
├── README.md
├── docker-compose.yml
├── Dockerfile
├── .gitignore
├── workflows/                 # Grok-optimized JSON workflows
├── scripts/
│   └── install-custom-nodes.sh
├── docs/
│   ├── MODELS.md
│   └── GROK_HANDOFF.md
├── input/                     # Drop Grok Imagine images here
├── output/
└── models/                    # Local models (gitignored)
```

---

## Status

**v1.0 – Exclusive Grok Build Edition**  
Focused purely on the hybrid workflow: **Grok Imagine → ComfyUI refine/video → back to Cinematic Studio**.

If you are not using Grok Imagine as your primary image generator, this repo is not for you.
