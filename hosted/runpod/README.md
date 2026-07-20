# RunPod (or similar GPU cloud) — Grok ComfyUI

## Quick template settings

| Field | Value |
|-------|--------|
| Container image | `ghcr.io/finecomputer14451/comfyui-grok-build:latest` |
| Container disk | ≥ 40 GB (models are larger) |
| Volume | Mount network volume at `/workspace` |
| Expose HTTP | Port **8188** |
| Docker command | leave default (image `ENTRYPOINT`) or `/entrypoint.sh python main.py` |
| Env | `INSTALL_CUSTOM_NODES=1` |

## Suggested GPU

| Workload | GPU |
|----------|-----|
| Refine / upscale only | 8–12 GB VRAM |
| Wan 2.2 TI2V 5B | ≥ 12 GB (16+ better) |
| Wan 2.2 14B I2V fp16 | 24 GB+ (4090 / A6000 / L40) |

## First boot

1. Start pod with the image above  
2. Open the HTTP service on port 8188  
3. In a web terminal on the pod:

```bash
# if scripts are in the image
/app/scripts/download-models.sh minimal
# optional video stack
/app/scripts/download-models.sh wan22-5b
```

Or download into the network volume:

```bash
export COMFYUI_MODELS=/workspace/models
# copy download-models.sh from the repo or image
```

4. Upload Grok stills to `/workspace/input` (or ComfyUI input)  
5. Load workflows from the user workflows folder  

## Security

RunPod URLs are semi-public. Prefer:

- RunPod **HTTP auth** / proxy auth if available  
- Or put Cloudflare Access in front of a custom domain tunnel from a trusted host  
- Do not leave an open unauthenticated ComfyUI on the public internet without auth  

## Alternative: Vast.ai

Same image + expose `8188`, attach a disk for `/workspace` or bind-mount models.
