# Grok Imagine → ComfyUI handoff

This repo is a **local bridge**, not a replacement for Grok Imagine.

```
Grok Imagine (hero stills / identity)
        │
        ▼  drop PNG/JPG into input/
ComfyUI (this stack)
  • refine / upscale / face lock
  • Wan 2.1 or 2.2 image-to-video
        │
        ▼  read from output/
Grok Imagine Cinematic Studio
  • sequence, color, audio, delivery skills
```

---

## 1. Generate in Grok

1. Create hero stills with **Grok Imagine** (prefer Identity Lock / Character DNA when available).  
2. Export the highest-quality stills you can (PNG preferred).  
3. Keep a short motion note for each plate (camera + action) for the I2V prompt later.

## 2. Drop into this repo

```bash
cp /path/to/grok_still.png input/
# optional: clear names help workflows
# input/hero_01.png  input/hero_02.png
```

Host path `./input` is mounted to ComfyUI’s input folder.

## 3. Load a Grok-optimized workflow

Open http://localhost:8188 → **Workflow → Open** (or browse templates under User workflows):

| Workflow | When to use |
|----------|-------------|
| `01_grok_refine.json` | Light clean-up + 4× upscale of a Grok still |
| `04_face_detail_lock.json` | Stronger face restore while preserving identity |
| `05_cinematic_upscale.json` | Hero plate upscale + mild grade prep |
| `02_grok_to_video_wan21.json` | I2V with Wan 2.1 |
| `03_grok_to_video_wan22.json` | I2V with Wan 2.2 (**preferred**) |

**Always** set the Load Image node to your file under `input/`.

## 4. I2V prompt tips (motion only)

Do **not** re-describe the whole character. Grok already locked identity in the frame.

Prefer:

- Camera: slow push-in, gentle orbit, locked-off handheld breathe  
- Subject: blink, subtle breath, hair/cloth micro-motion  
- Environment: light flicker, particle drift, rain streak  

Avoid:

- “change outfit / age / ethnicity / face shape”  
- Hard cuts or multi-scene prompts in one short clip  

## 5. Pull outputs back to Studio

```bash
ls output/
# refined stills → Identity Lock / I2I refiner / Key Art
# mp4/webm     → Sequence Director / Assembly / AI Polish
```

Suggested Studio next steps:

1. **Reference Asset Curator** — tier plates (hero / standard)  
2. **Image-to-Video Specialist** — if you still need Grok-native video for hero shots  
3. **Sequence Director + Chain QA** — multi-clip continuity  
4. **AI Polish + cinematic-ffmpeg** — final delivery  

## 6. Quota hybrid rule of thumb

| Task | Prefer |
|------|--------|
| Hero character lock | Grok Imagine |
| Cheap animatic / pre-viz | Local draft upscale only |
| Long batch I2V when SuperGrok quota is tight | Local Wan 2.2 |
| Final emotional performance / native audio | Grok Imagine Video 1.5 when possible |

## 7. Troubleshooting handoff

| Symptom | Fix |
|---------|-----|
| Red missing nodes | `INSTALL_CUSTOM_NODES=1 docker compose up -d` or run `scripts/install-custom-nodes.sh` |
| Model not in dropdown | Check `docs/MODELS.md` paths; restart container |
| CUDA / GPU not found | Install [NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html); `nvidia-smi` on host |
| Empty custom_nodes after first start | Expected until install script runs; Manager is auto-seeded by entrypoint |

---

**Philosophy:** Grok owns identity and hero quality. ComfyUI extends and polishes. Never invert that order for production stills.
