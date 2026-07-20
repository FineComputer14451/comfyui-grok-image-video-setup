# Hosted setup — Grok ComfyUI bridge

Run the refine/video engine on a **remote GPU host** and reach it from Grok Build / any browser with auth.

```
Grok Imagine stills
        │  upload / sync to input/
        ▼
┌─────────────────────────────┐
│  Hosted GPU node            │
│  ComfyUI :8188 (internal)   │
│  Caddy :443 + basic auth    │
│  optional Cloudflare Tunnel │
└─────────────────────────────┘
        │
        ▼
Browser / Studio handoff ← output/
```

---

## Option A — Prebuilt image (fastest)

Image (published by CI on `main` / tags):

```text
ghcr.io/finecomputer14451/comfyui-grok-build:latest
```

On a GPU host with Docker + NVIDIA Container Toolkit:

```bash
git clone https://github.com/FineComputer14451/comfyui-grok-image-video-setup.git
cd comfyui-grok-image-video-setup

# Auth to GHCR if the package is private (public packages pull without login)
# echo $GHCR_TOKEN | docker login ghcr.io -u USER --password-stdin

export IMAGE=ghcr.io/finecomputer14451/comfyui-grok-build:latest
docker pull "$IMAGE"

cp .env.example .env
# set HOSTED_DOMAIN, HOSTED_BASIC_USER, HOSTED_BASIC_HASH (see below)

./scripts/download-models.sh minimal
# optional: ./scripts/download-models.sh wan22-5b

./scripts/hosted-up.sh
```

Open `https://YOUR_DOMAIN` (or host IP) and sign in with basic auth.

---

## Option B — Build on the host

```bash
cp .env.example .env
# edit .env
./scripts/hosted-up.sh
# builds from Dockerfile if IMAGE is not pre-pulled
```

Compose files:

| File | Role |
|------|------|
| `docker-compose.yml` | ComfyUI + GPU + volumes |
| `docker-compose.hosted.yml` | Hides 8188, adds Caddy (+ tunnel profile) |

---

## Basic auth password hash

```bash
docker run --rm caddy:2.9-alpine caddy hash-password --plaintext 'choose-a-long-password'
```

Put the hash in `.env`:

```env
HOSTED_BASIC_USER=grok
HOSTED_BASIC_HASH='$2a$14$....'
HOSTED_DOMAIN=comfyui.example.com
HOSTED_EMAIL=you@example.com
```

For a **public domain** with Let's Encrypt, mount `hosted/Caddyfile.public` instead of `hosted/Caddyfile` (see comment in `docker-compose.hosted.yml` / swap volume).

---

## Cloudflare Tunnel (no open ports)

1. Zero Trust → Networks → Tunnels → Create → Docker  
2. Copy the token into `.env`:

```env
CLOUDFLARE_TUNNEL_TOKEN=eyJ...
```

3. Start with tunnel profile:

```bash
./scripts/hosted-up.sh
# or:
docker compose -f docker-compose.yml -f docker-compose.hosted.yml --profile tunnel up -d
```

Point the tunnel public hostname to `http://caddy:80` (service name on the compose network).  
Optionally put **Cloudflare Access** in front for SSO.

---

## Option C — RunPod / Vast.ai

See **[hosted/runpod/README.md](../hosted/runpod/README.md)**.

Summary:

- Image: `ghcr.io/finecomputer14451/comfyui-grok-build:latest`
- Expose **8188**
- Network volume at `/workspace` for models
- GPU: 24GB+ for Wan 2.2 14B; 12–16GB for 5B / upscale-only

---

## Grok handoff on a hosted box

1. Generate stills in Grok Imagine  
2. Upload to hosted `input/` (SCP, RunPod file browser, rclone, etc.)  
3. Run refine / Wan workflows in the UI  
4. Download from `output/` back into Cinematic Studio  

Details: [GROK_HANDOFF.md](GROK_HANDOFF.md)

---

## Environment reference

| Variable | Default | Meaning |
|----------|---------|---------|
| `IMAGE` | `comfyui-grok-build:latest` | Container image |
| `HOSTED_DOMAIN` | `localhost` | Caddy site address |
| `HOSTED_EMAIL` | `admin@example.com` | ACME email (public TLS) |
| `HOSTED_BASIC_USER` | `grok` | Basic auth user |
| `HOSTED_BASIC_HASH` | _(required)_ | Caddy bcrypt hash |
| `HOSTED_HTTP_PORT` | `80` | Host HTTP port |
| `HOSTED_HTTPS_PORT` | `443` | Host HTTPS port |
| `CLOUDFLARE_TUNNEL_TOKEN` | empty | Enables tunnel profile when set |
| `INSTALL_CUSTOM_NODES` | `1` (hosted) | Clone recommended nodes on boot |

---

## Security checklist

- [ ] Never publish raw `:8188` to the open internet without auth  
- [ ] Use strong basic auth **or** Cloudflare Access  
- [ ] Prefer tunnel over opening 443 on unknown VPS firewalls  
- [ ] Keep models/volumes on encrypted disks when multi-tenant  
- [ ] Rotate passwords when sharing screenshots of `.env`  

---

## Troubleshooting

| Issue | Fix |
|-------|-----|
| GHCR pull denied | `docker login ghcr.io`; package visibility (public/private) |
| Caddy 401 loop | Regenerate `HOSTED_BASIC_HASH`; quote carefully in `.env` |
| No GPU in container | Install NVIDIA Container Toolkit; `nvidia-smi` on host |
| WebSocket drops | Proxy already sets long timeouts; check CDN buffer settings |
| Image build OOM in CI | Use published `:latest` instead of building on small VPS |
