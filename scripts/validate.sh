#!/usr/bin/env bash
# Offline scaffold validation (no Docker/GPU required).
# Exit 0 if the Grok→ComfyUI repo layout is coherent.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT}"
FAIL=0

ok()   { echo "  OK  $*"; }
fail() { echo "  FAIL $*"; FAIL=1; }

echo "=== validate: comfyui-grok-image-video-setup ==="
echo "root: ${ROOT}"
echo

echo "[1] required files"
for f in \
  README.md Dockerfile docker-compose.yml docker-compose.hosted.yml .gitignore \
  scripts/entrypoint.sh scripts/install-custom-nodes.sh scripts/download-models.sh \
  scripts/hosted-up.sh scripts/install-local.sh scripts/validate.sh \
  docs/MODELS.md docs/GROK_HANDOFF.md docs/HOSTED.md \
  hosted/Caddyfile hosted/Caddyfile.public hosted/runpod/start.sh \
  .github/workflows/validate.yml .github/workflows/publish-image.yml
do
  if [ -f "$f" ]; then ok "$f"; else fail "missing $f"; fi
done

echo
echo "[2] workflow JSONs"
for w in \
  workflows/01_grok_refine.json \
  workflows/02_grok_to_video_wan21.json \
  workflows/03_grok_to_video_wan22.json \
  workflows/04_face_detail_lock.json \
  workflows/05_cinematic_upscale.json
do
  if [ ! -f "$w" ]; then
    fail "missing $w"
    continue
  fi
  if python3 -c "import json; json.load(open('$w'))" 2>/dev/null; then
    ok "$w"
  else
    fail "invalid JSON $w"
  fi
done

echo
echo "[3] shell scripts (bash -n)"
for s in scripts/*.sh; do
  if bash -n "$s" 2>/dev/null; then
    ok "$s"
  else
    fail "syntax $s"
  fi
  if [ ! -x "$s" ]; then
    fail "not executable $s"
  else
    ok "executable $s"
  fi
done

echo
echo "[4] directory placeholders"
for d in input output custom_nodes models/upscale_models models/diffusion_models \
         models/text_encoders models/vae models/clip_vision; do
  if [ -d "$d" ]; then ok "dir $d"; else fail "missing dir $d"; fi
done

echo
echo "[5] docker-compose shape"
if grep -q 'comfyui-grok' docker-compose.yml && grep -q '8188' docker-compose.yml; then
  ok "compose service + port 8188"
else
  fail "compose missing expected service/port"
fi
if grep -q 'build:' docker-compose.yml && grep -q 'Dockerfile' docker-compose.yml; then
  ok "compose builds Dockerfile"
else
  fail "compose not configured to build Dockerfile"
fi

echo
echo "[6] Dockerfile shape"
if grep -q 'comfyanonymous/ComfyUI' Dockerfile && grep -q 'ENTRYPOINT' Dockerfile; then
  ok "Dockerfile clones ComfyUI + ENTRYPOINT"
else
  fail "Dockerfile missing ComfyUI clone or ENTRYPOINT"
fi

echo
echo "[7] download-models profiles"
if ./scripts/download-models.sh list 2>/dev/null | grep -q 'wan22-i2v'; then
  ok "download-models profiles listed"
else
  fail "download-models list broken"
fi

echo
echo "[8] hosted stack markers"
if grep -q 'caddy' docker-compose.hosted.yml && grep -q 'cloudflared' docker-compose.hosted.yml; then
  ok "hosted compose has caddy + cloudflared"
else
  fail "hosted compose missing proxy/tunnel services"
fi
if grep -q 'ghcr.io' docs/HOSTED.md && grep -q 'HOSTED_BASIC_HASH' .env.example; then
  ok "hosted docs + env example"
else
  fail "hosted docs/env incomplete"
fi
if grep -q 'Publish GHCR' .github/workflows/publish-image.yml; then
  ok "publish-image workflow present"
else
  fail "publish-image workflow missing"
fi

echo
if [ "$FAIL" -ne 0 ]; then
  echo "=== VALIDATION FAILED ==="
  exit 1
fi
echo "=== VALIDATION PASSED ==="
exit 0
