#!/usr/bin/env bash
# RunPod / Vast-style GPU pod entrypoint wrapper for the Grok ComfyUI image.
# Expected env (RunPod):
#   PORT / PUBLIC_PORT optional; ComfyUI always listens 8188 inside container
set -euo pipefail

export INSTALL_CUSTOM_NODES="${INSTALL_CUSTOM_NODES:-1}"
export CLI_ARGS="${CLI_ARGS:---listen 0.0.0.0 --port 8188 --enable-cors-header --preview-method auto}"

# Persist paths commonly used on RunPod network volumes
mkdir -p /workspace/models /workspace/input /workspace/output /workspace/custom_nodes /workspace/workflows

# If image entrypoint exists, prefer it with workspace mounts already bound by pod template
if [ -x /entrypoint.sh ]; then
  # Symlink workspace data into /app if volumes are on /workspace
  for pair in models input output custom_nodes; do
    if [ -d "/workspace/${pair}" ] && [ ! -L "/app/${pair}" ]; then
      # Prefer workspace contents when /app path is empty-ish
      if [ -z "$(ls -A /app/${pair} 2>/dev/null | head -1)" ]; then
        rm -rf "/app/${pair}"
        ln -s "/workspace/${pair}" "/app/${pair}"
      fi
    fi
  done
  if [ -d /workspace/workflows ]; then
    mkdir -p /app/user/default
    if [ ! -e /app/user/default/workflows ]; then
      ln -s /workspace/workflows /app/user/default/workflows
    fi
  fi
  exec /entrypoint.sh python main.py
fi

cd /app
exec python main.py ${CLI_ARGS}
