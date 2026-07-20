#!/usr/bin/env bash
# Entrypoint for comfyui-grok-build container
set -euo pipefail

COMFYUI_DIR="${COMFYUI_DIR:-/app}"
cd "${COMFYUI_DIR}"

# Ensure volume-mounted dirs exist
mkdir -p \
  models/checkpoints \
  models/diffusion_models \
  models/text_encoders \
  models/vae \
  models/clip_vision \
  models/upscale_models \
  models/loras \
  models/facerestore_models \
  models/embeddings \
  input \
  output \
  custom_nodes \
  user/default/workflows

# Seed ComfyUI-Manager when the host volume is empty / missing Manager
if [ ! -d custom_nodes/ComfyUI-Manager ] && [ -d /opt/comfyui-seed/custom_nodes/ComfyUI-Manager ]; then
  echo "[entrypoint] Seeding ComfyUI-Manager into custom_nodes volume..."
  cp -a /opt/comfyui-seed/custom_nodes/ComfyUI-Manager custom_nodes/ComfyUI-Manager
fi

# Optional first-boot install of recommended Grok-pipeline nodes
if [ "${INSTALL_CUSTOM_NODES:-0}" = "1" ]; then
  echo "[entrypoint] INSTALL_CUSTOM_NODES=1 — running install-custom-nodes.sh"
  bash /app/scripts/install-custom-nodes.sh || true
fi

# shellcheck disable=SC2206
EXTRA_ARGS=(${CLI_ARGS:-})

echo "[entrypoint] Starting ComfyUI (Grok Build exclusive pipeline)"
echo "[entrypoint] Working dir: ${COMFYUI_DIR}"
echo "[entrypoint] Extra args: ${EXTRA_ARGS[*]:-<none>}"

if [ "$#" -eq 0 ]; then
  exec python main.py "${EXTRA_ARGS[@]}"
fi

# CMD ["python", "main.py"] → append CLI_ARGS
if [ "$1" = "python" ] && [ "${2:-}" = "main.py" ]; then
  shift 2
  exec python main.py "${EXTRA_ARGS[@]}" "$@"
fi

exec "$@"
