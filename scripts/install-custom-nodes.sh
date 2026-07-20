#!/usr/bin/env bash
# Install minimal custom nodes for the Grok → ComfyUI refine / face / video pipeline.
# Safe to re-run (skips existing dirs). Run on host against ./custom_nodes or inside container.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
NODES_DIR="${COMFYUI_CUSTOM_NODES:-${ROOT}/custom_nodes}"
mkdir -p "${NODES_DIR}"
cd "${NODES_DIR}"

clone_node() {
  local repo_url="$1"
  local dir_name="$2"
  if [ -d "${dir_name}/.git" ]; then
    echo "[skip] ${dir_name} already present"
    return 0
  fi
  echo "[clone] ${dir_name}"
  git clone --depth 1 "${repo_url}" "${dir_name}"
  if [ -f "${dir_name}/requirements.txt" ]; then
    echo "[pip] ${dir_name}"
    pip install --no-cache-dir -r "${dir_name}/requirements.txt" || true
  fi
  if [ -f "${dir_name}/install.py" ]; then
    python "${dir_name}/install.py" || true
  fi
}

echo "=== Grok pipeline custom nodes → ${NODES_DIR} ==="

# Manager (in-UI installs)
clone_node "https://github.com/ltdrdata/ComfyUI-Manager.git" "ComfyUI-Manager"

# Video helpers (optional; native Wan nodes are in core ComfyUI)
clone_node "https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite.git" "ComfyUI-VideoHelperSuite"

# Face restore / detail (04_face_detail_lock)
clone_node "https://github.com/ltdrdata/ComfyUI-Impact-Pack.git" "ComfyUI-Impact-Pack"
clone_node "https://github.com/cubiq/ComfyUI_FaceAnalysis.git" "ComfyUI_FaceAnalysis" || true

# Image tooling (crop, blend, color)
clone_node "https://github.com/cubiq/ComfyUI_essentials.git" "ComfyUI_essentials"

# GGUF loaders for low-VRAM Wan quantizations (optional)
clone_node "https://github.com/city96/ComfyUI-GGUF.git" "ComfyUI-GGUF"

# Advanced Wan wrapper (optional; core native Wan is preferred for official templates)
if [ "${INSTALL_WAN_WRAPPER:-0}" = "1" ]; then
  clone_node "https://github.com/kijai/ComfyUI-WanVideoWrapper.git" "ComfyUI-WanVideoWrapper"
fi

echo "=== Done. Restart ComfyUI to load new nodes. ==="
echo "Tip: place models per docs/MODELS.md before running video workflows."
