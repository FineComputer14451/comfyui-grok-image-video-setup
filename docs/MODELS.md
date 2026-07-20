# Models — placement & downloads

Grok Imagine remains the **source of truth** for stills. Local models here are only for:

1. **Refinement / upscale / face detail** of Grok stills  
2. **Image-to-video** (Wan 2.1 / 2.2) from those stills  

Models are **not** committed to git. Place them under `models/` on the host (bind-mounted into the container).

---

## Folder map

```
models/
├── diffusion_models/     # Wan I2V / T2V weights
├── text_encoders/        # umT5 etc.
├── vae/                  # Wan VAE
├── clip_vision/          # Wan 2.1 CLIP Vision (if required by workflow)
├── upscale_models/       # RealESRGAN, 4x-UltraSharp, etc.
├── facerestore_models/   # CodeFormer / GFPGAN (for Impact Pack / face nodes)
├── loras/                # Optional distill / lightning LoRAs
├── checkpoints/          # Optional SDXL etc. (not required for core Grok path)
└── embeddings/
```

---

## A. Refinement & face (small — start here)

| File | Folder | Purpose |
|------|--------|---------|
| `4x-UltraSharp.pth` | `upscale_models/` | Clean Grok still upscale (`01`, `05`) |
| `RealESRGAN_x4plus.pth` | `upscale_models/` | Alternate general upscaler |
| CodeFormer / GFPGAN weights | `facerestore_models/` | Face restore (`04`) via Impact Pack |

**Upscaler downloads (examples):**

- [4x-UltraSharp](https://huggingface.co/Kim2091/UltraSharp) (place `.pth` in `upscale_models/`)
- [Real-ESRGAN](https://github.com/xinntao/Real-ESRGAN/releases)

Face models depend on which custom node you use (Impact Pack, Reactor, etc.). Install nodes with:

```bash
./scripts/install-custom-nodes.sh
# or: INSTALL_CUSTOM_NODES=1 docker compose up -d --build
```

---

## B. Wan 2.2 Image-to-Video (preferred)

Official Comfy-Org repackaged files (see [Wan 2.2 docs](https://docs.comfy.org/tutorials/video/wan/wan2_2)):

| File | Folder |
|------|--------|
| `wan2.2_i2v_high_noise_14B_fp16.safetensors` | `diffusion_models/` |
| `wan2.2_i2v_low_noise_14B_fp16.safetensors` | `diffusion_models/` |
| `umt5_xxl_fp8_e4m3fn_scaled.safetensors` | `text_encoders/` |
| `wan_2.1_vae.safetensors` | `vae/` |

**Direct links (Hugging Face — Comfy-Org):**

- [high noise 14B fp16](https://huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_Repackaged/resolve/main/split_files/diffusion_models/wan2.2_i2v_high_noise_14B_fp16.safetensors)
- [low noise 14B fp16](https://huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_Repackaged/resolve/main/split_files/diffusion_models/wan2.2_i2v_low_noise_14B_fp16.safetensors)
- [umT5 fp8](https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors)
- [Wan VAE](https://huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_Repackaged/resolve/main/split_files/vae/wan_2.1_vae.safetensors)

**VRAM:** 14B fp16 is heavy (≈24GB+ recommended). For tighter VRAM:

- Use **fp8_scaled** variants from the same HF repo when available  
- Or **GGUF** quants + [ComfyUI-GGUF](https://github.com/city96/ComfyUI-GGUF) (`INSTALL_CUSTOM_NODES=1`)  
- Or the lighter **Wan 2.2 TI2V 5B** hybrid (fits ~8GB with offload):
  - `wan2.2_ti2v_5B_fp16.safetensors` → `diffusion_models/`
  - `wan2.2_vae.safetensors` → `vae/`
  - same `umt5_xxl_fp8_e4m3fn_scaled.safetensors`

Workflow: `workflows/03_grok_to_video_wan22.json` (official 14B I2V template, Grok-first).

---

## C. Wan 2.1 Image-to-Video (fallback)

Workflow: `workflows/02_grok_to_video_wan21.json` (official `image_to_video_wan` template).

Typical layout (names may vary by repackage):

```
models/
├── diffusion_models/
│   └── wan2.1_i2v_720p_14B_fp8_scaled.safetensors   # or fp16
├── text_encoders/
│   └── umt5_xxl_fp8_e4m3fn_scaled.safetensors
├── clip_vision/
│   └── clip_vision_h.safetensors
└── vae/
    └── wan_2.1_vae.safetensors
```

Comfy-Org repackage:  
https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged

---

## D. Quick download helpers

Use the bundled script (resumable, skips existing files):

```bash
./scripts/download-models.sh list

# Start here — upscaler for refine workflows 01/04/05 (~64MB)
./scripts/download-models.sh minimal

# Upscalers only (UltraSharp + RealESRGAN)
./scripts/download-models.sh refine

# Shared text encoder + VAE for Wan
./scripts/download-models.sh shared

# Lighter video path (~8GB+ VRAM with offload)
./scripts/download-models.sh wan22-5b

# Full Wan 2.2 14B I2V (heavy — tens of GB, ~24GB+ VRAM)
./scripts/download-models.sh wan22-i2v

# Everything refine + 14B I2V + clip vision
./scripts/download-models.sh all
```

Manual one-offs:

```bash
mkdir -p models/text_encoders models/vae models/diffusion_models models/upscale_models

wget -c -O models/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors \
  "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors"

wget -c -O models/vae/wan_2.1_vae.safetensors \
  "https://huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_Repackaged/resolve/main/split_files/vae/wan_2.1_vae.safetensors"
```

---

## E. What you do **not** need

- Full SD1.5 / SDXL stacks for the core Grok path  
- Training data or fine-tunes of Grok  
- Cloud API keys for local Wan generation  

Grok Imagine (cloud) → drop stills in `input/` → ComfyUI refine/i2v → `output/` → back to Cinematic Studio skills.
