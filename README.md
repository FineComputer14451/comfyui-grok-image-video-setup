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

## Prerequisites

- Linux host with **NVIDIA GPU** + recent drivers
- [Docker](https://docs.docker.com/engine/install/) + [Docker Compose](https://docs.docker.com/compose/)
- [NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html)
- Confirm GPU passthrough: `nvidia-smi` and `docker run --rm --gpus all nvidia/cuda:12.4.1-base-ubuntu22.04 nvidia-smi`

CPU-only is possible but **not** practical for Wan I2V.

---

## Quick Start (Recommended Path)

### 1. Generate in Grok
Create your best stills with Grok Imagine (use Character DNA / Identity Lock if available).

### 2. Clone this repo
```bash
git clone https://github.com/FineComputer14451/comfyui-grok-image-video-setup.git
cd comfyui-grok-image-video-setup
```

### 3. Launch with Docker (recommended)
```bash
# First build (pulls PyTorch + clones ComfyUI — several minutes)
docker compose up -d --build

# Optional: also install recommended custom nodes on first start
INSTALL_CUSTOM_NODES=1 docker compose up -d --build
```

Open → http://localhost:8188

Stop:
```bash
docker compose down
```

### 3b. Local install (no Docker)
```bash
./scripts/install-local.sh
./scripts/download-models.sh minimal
./scripts/run-local.sh   # created by install-local.sh
```
Still requires a suitable Python + (for video) CUDA PyTorch stack.

Validate the repo offline anytime:
```bash
./scripts/validate.sh
```

### 4. Drop Grok images into `input/`
Then load a workflow from the **Workflows** menu (user folder) or open files under `workflows/`.

### 5. Install models
```bash
# Upscaler for refine workflows (small)
./scripts/download-models.sh minimal

# Optional: Wan 2.2 lighter 5B video stack, or full 14B I2V
./scripts/download-models.sh wan22-5b
# ./scripts/download-models.sh wan22-i2v
```

Full paths and profiles: **[docs/MODELS.md](docs/MODELS.md)**.  
Handoff guide: **[docs/GROK_HANDOFF.md](docs/GROK_HANDOFF.md)**.

---

## Included Workflows (Grok-Optimized)

| File | Purpose |
|------|---------|
| `01_grok_refine.json` | Clean up + upscale a Grok Imagine still |
| `02_grok_to_video_wan21.json` | Image-to-Video using Wan 2.1 (Comfy-Org template) |
| `03_grok_to_video_wan22.json` | Image-to-Video using Wan 2.2 (preferred, Comfy-Org template) |
| `04_face_detail_lock.json` | Face-preserving refine path (optional Impact Pack restore) |
| `05_cinematic_upscale.json` | High-end upscale + resolution target for grade prep |

All workflows are designed so the **first image you load is a Grok Imagine output**.

---

## Recommended Local Models

Place models under `models/` (gitignored):

**For refinement**
- Any high-quality upscaler (`4x-UltraSharp`, RealESRGAN, etc.) → `models/upscale_models/`
- Face restoration weights if you enable Impact Pack → `models/facerestore_models/`

**For video (Wan 2.2 preferred)**
- `wan2.2_i2v_*_14B_*.safetensors` → `models/diffusion_models/`
- `umt5_xxl_fp8_e4m3fn_scaled.safetensors` → `models/text_encoders/`
- `wan_2.1_vae.safetensors` → `models/vae/`

Full links and VRAM notes: **[docs/MODELS.md](docs/MODELS.md)**.

---

## Custom nodes

Minimal set (Manager, VideoHelperSuite, Impact Pack, essentials, GGUF):

```bash
./scripts/install-custom-nodes.sh
# or INSTALL_CUSTOM_NODES=1 docker compose up -d
```

Optional Kijai Wan wrapper: `INSTALL_WAN_WRAPPER=1` (native ComfyUI Wan nodes are preferred for the bundled templates).

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
├── .dockerignore
├── .env.example
├── workflows/                 # Grok-optimized JSON workflows
├── scripts/
│   ├── entrypoint.sh
│   ├── install-custom-nodes.sh
│   ├── download-models.sh
│   ├── install-local.sh
│   └── validate.sh
├── docs/
│   ├── MODELS.md
│   └── GROK_HANDOFF.md
├── input/                     # Drop Grok Imagine images here
├── output/
├── custom_nodes/              # Populated at install (gitignored)
└── models/                    # Local models (gitignored)
```

---

## Troubleshooting

| Issue | What to try |
|-------|-------------|
| Build fails on torch/CUDA | Need NVIDIA drivers + container toolkit; base image is CUDA 12.4 |
| UI up but GPU not used | `docker compose exec comfyui-grok python -c "import torch; print(torch.cuda.is_available())"` |
| Missing nodes (red) | `INSTALL_CUSTOM_NODES=1 docker compose up -d` then restart |
| Model missing in dropdown | Check folder under `models/` per MODELS.md; restart container |
| Port 8188 in use | Change host port in `docker-compose.yml` (`"8189:8188"`) |

Logs:
```bash
docker compose logs -f comfyui-grok
```

---

## Status

**v1.0.0 – Exclusive Grok Build Edition**  
Focused purely on the hybrid workflow: **Grok Imagine → ComfyUI refine/video → back to Cinematic Studio**.

Scaffold includes Docker + local install paths, Grok-optimized workflows, model downloader, and CI validation.

If you are not using Grok Imagine as your primary image generator, this repo is not for you.
