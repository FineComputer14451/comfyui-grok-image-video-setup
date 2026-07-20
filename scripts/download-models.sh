#!/usr/bin/env bash
# Download recommended local models for the Grok → ComfyUI pipeline.
# Models are large; pick a profile. Safe to re-run (skips existing files unless --force).
#
# Usage:
#   ./scripts/download-models.sh                  # interactive-ish: minimal + shared
#   ./scripts/download-models.sh minimal          # upscaler only
#   ./scripts/download-models.sh shared           # umT5 + Wan VAE
#   ./scripts/download-models.sh wan22-5b         # shared + Wan 2.2 TI2V 5B (lighter VRAM)
#   ./scripts/download-models.sh wan22-i2v        # shared + Wan 2.2 14B I2V (heavy)
#   ./scripts/download-models.sh refine           # minimal upscaler set
#   ./scripts/download-models.sh all              # minimal + wan22-i2v (very large)
#   ./scripts/download-models.sh list
#   ./scripts/download-models.sh wan22-5b --force
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MODELS="${COMFYUI_MODELS:-${ROOT}/models}"
FORCE=0
PROFILE="${1:-minimal}"

if [ "${2:-}" = "--force" ] || [ "${1:-}" = "--force" ]; then
  FORCE=1
fi
if [ "${1:-}" = "--force" ]; then
  PROFILE="${2:-minimal}"
fi

# --- URLs (Comfy-Org / community HF) ---
URL_UMT5="https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors"
URL_VAE_21="https://huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_Repackaged/resolve/main/split_files/vae/wan_2.1_vae.safetensors"
URL_VAE_22="https://huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_Repackaged/resolve/main/split_files/vae/wan2.2_vae.safetensors"
URL_WAN22_I2V_HIGH="https://huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_Repackaged/resolve/main/split_files/diffusion_models/wan2.2_i2v_high_noise_14B_fp16.safetensors"
URL_WAN22_I2V_LOW="https://huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_Repackaged/resolve/main/split_files/diffusion_models/wan2.2_i2v_low_noise_14B_fp16.safetensors"
URL_WAN22_5B="https://huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_Repackaged/resolve/main/split_files/diffusion_models/wan2.2_ti2v_5B_fp16.safetensors"
URL_CLIP_VISION="https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/clip_vision/clip_vision_h.safetensors"
# UltraSharp (Kim2091) — common ComfyUI upscaler
URL_ULTRASHARP="https://huggingface.co/Kim2091/UltraSharp/resolve/main/4x-UltraSharp.pth"
# RealESRGAN x4plus
URL_REALESRGAN="https://github.com/xinntao/Real-ESRGAN/releases/download/v0.1.0/RealESRGAN_x4plus.pth"

have_downloader() {
  if command -v wget >/dev/null 2>&1; then
    echo wget
  elif command -v curl >/dev/null 2>&1; then
    echo curl
  else
    echo ""
  fi
}

download() {
  local url="$1"
  local dest="$2"
  local dir
  dir="$(dirname "${dest}")"
  mkdir -p "${dir}"

  if [ -f "${dest}" ] && [ "${FORCE}" -eq 0 ]; then
    local sz
    sz="$(wc -c <"${dest}" | tr -d ' ')"
    if [ "${sz}" -gt 1000000 ]; then
      echo "[skip] $(basename "${dest}") already exists ($(numfmt --to=iec "${sz}" 2>/dev/null || echo "${sz} bytes"))"
      return 0
    fi
    echo "[warn] $(basename "${dest}") looks incomplete (${sz} bytes) — re-downloading"
  fi

  local tmp="${dest}.partial"
  local tool
  tool="$(have_downloader)"
  if [ -z "${tool}" ]; then
    echo "[error] need wget or curl" >&2
    exit 1
  fi

  echo "[get] $(basename "${dest}")"
  echo "      ← ${url}"

  if [ "${tool}" = "wget" ]; then
    wget -c --show-progress -O "${tmp}" "${url}"
  else
    curl -fL --retry 3 --retry-delay 2 -C - -o "${tmp}" "${url}"
  fi

  mv -f "${tmp}" "${dest}"
  echo "[ok]  ${dest} ($(du -h "${dest}" | cut -f1))"
}

print_list() {
  cat <<'EOF'
Profiles:
  minimal     4x-UltraSharp upscaler only (~64MB) — for 01/04/05 refine workflows
  refine      UltraSharp + RealESRGAN x4plus
  shared      umT5 text encoder + wan_2.1_vae (~large; required for Wan video)
  wan22-5b    shared + Wan 2.2 TI2V 5B (lighter; ~8GB+ VRAM friendly)
  wan22-i2v   shared + Wan 2.2 14B I2V high/low noise (heavy; ~24GB+ VRAM)
  wan21-clip  CLIP Vision H (often needed for Wan 2.1 I2V template)
  all         refine + wan22-i2v + clip vision  (very large multi-GB download)

Env:
  COMFYUI_MODELS=/path/to/models   override models root (default: ./models)

Flags:
  --force     re-download even if file exists
EOF
}

do_minimal() {
  download "${URL_ULTRASHARP}" "${MODELS}/upscale_models/4x-UltraSharp.pth"
}

do_refine() {
  do_minimal
  download "${URL_REALESRGAN}" "${MODELS}/upscale_models/RealESRGAN_x4plus.pth"
}

do_shared() {
  download "${URL_UMT5}" "${MODELS}/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors"
  download "${URL_VAE_21}" "${MODELS}/vae/wan_2.1_vae.safetensors"
}

do_wan22_5b() {
  do_shared
  download "${URL_VAE_22}" "${MODELS}/vae/wan2.2_vae.safetensors"
  download "${URL_WAN22_5B}" "${MODELS}/diffusion_models/wan2.2_ti2v_5B_fp16.safetensors"
}

do_wan22_i2v() {
  do_shared
  echo "[note] Wan 2.2 14B I2V fp16 is very large (tens of GB). Prefer a fast link / HF token if rate-limited."
  download "${URL_WAN22_I2V_HIGH}" "${MODELS}/diffusion_models/wan2.2_i2v_high_noise_14B_fp16.safetensors"
  download "${URL_WAN22_I2V_LOW}" "${MODELS}/diffusion_models/wan2.2_i2v_low_noise_14B_fp16.safetensors"
}

do_wan21_clip() {
  download "${URL_CLIP_VISION}" "${MODELS}/clip_vision/clip_vision_h.safetensors"
}

echo "=== Grok ComfyUI model downloader ==="
echo "Models root: ${MODELS}"
echo "Profile:     ${PROFILE}"
echo

case "${PROFILE}" in
  list|-h|--help|help)
    print_list
    exit 0
    ;;
  minimal)
    do_minimal
    ;;
  refine)
    do_refine
    ;;
  shared)
    do_shared
    ;;
  wan22-5b)
    do_wan22_5b
    ;;
  wan22-i2v|wan22)
    do_wan22_i2v
    ;;
  wan21-clip)
    do_wan21_clip
    ;;
  all)
    do_refine
    do_wan22_i2v
    do_wan21_clip
    ;;
  *)
    echo "[error] unknown profile: ${PROFILE}" >&2
    print_list
    exit 1
    ;;
esac

echo
echo "=== Done ==="
echo "Next:"
echo "  1. docker compose up -d --build"
echo "  2. Open http://localhost:8188"
echo "  3. Drop Grok stills into input/ and load workflows/"
echo "See docs/MODELS.md for full placement notes."
