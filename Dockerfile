# Grok Build exclusive: ComfyUI as post-process + video engine for Grok Imagine assets
# Base: official PyTorch CUDA runtime (NVIDIA GPU required for Wan I2V)
FROM pytorch/pytorch:2.6.0-cuda12.4-cudnn9-runtime

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    COMFYUI_DIR=/app \
    CLI_ARGS="--listen 0.0.0.0 --port 8188 --enable-cors-header"

WORKDIR /app

# System deps for OpenCV, git clones, and common custom-node builds
RUN apt-get update && apt-get install -y --no-install-recommends \
        git \
        git-lfs \
        wget \
        curl \
        ffmpeg \
        libgl1 \
        libglib2.0-0 \
        libsm6 \
        libxext6 \
        libxrender1 \
        libgomp1 \
        build-essential \
        python3-dev \
    && rm -rf /var/lib/apt/lists/* \
    && git lfs install

# Pin ComfyUI branch/tag via build-arg; default tracks master tip
ARG COMFYUI_REF=master
RUN git clone --depth 1 --branch "${COMFYUI_REF}" https://github.com/comfyanonymous/ComfyUI.git /app \
    && pip install --no-cache-dir -r /app/requirements.txt \
    && pip install --no-cache-dir \
        opencv-python-headless \
        imageio \
        imageio-ffmpeg \
        scikit-image \
        piexif \
    && (pip install --no-cache-dir onnxruntime-gpu || pip install --no-cache-dir onnxruntime)

# Seed Manager into a non-mounted path — entrypoint copies into volume if missing
RUN git clone --depth 1 https://github.com/ltdrdata/ComfyUI-Manager.git /opt/comfyui-seed/custom_nodes/ComfyUI-Manager \
    && if [ -f /opt/comfyui-seed/custom_nodes/ComfyUI-Manager/requirements.txt ]; then \
         pip install --no-cache-dir -r /opt/comfyui-seed/custom_nodes/ComfyUI-Manager/requirements.txt; \
       fi \
    && mkdir -p /app/custom_nodes \
    && cp -a /opt/comfyui-seed/custom_nodes/ComfyUI-Manager /app/custom_nodes/ComfyUI-Manager

# Default empty dirs (host volumes override these at runtime)
RUN mkdir -p \
    /app/models/checkpoints \
    /app/models/diffusion_models \
    /app/models/text_encoders \
    /app/models/vae \
    /app/models/clip_vision \
    /app/models/upscale_models \
    /app/models/loras \
    /app/models/facerestore_models \
    /app/models/embeddings \
    /app/input \
    /app/output \
    /app/user/default/workflows

COPY scripts/entrypoint.sh /entrypoint.sh
COPY scripts/install-custom-nodes.sh /app/scripts/install-custom-nodes.sh
RUN chmod +x /entrypoint.sh /app/scripts/install-custom-nodes.sh

EXPOSE 8188

HEALTHCHECK --interval=30s --timeout=10s --start-period=90s --retries=5 \
    CMD curl -fsS http://127.0.0.1:8188/ || exit 1

ENTRYPOINT ["/entrypoint.sh"]
CMD ["python", "main.py"]
