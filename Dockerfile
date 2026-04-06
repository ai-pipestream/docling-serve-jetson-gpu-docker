FROM nvcr.io/nvidia/pytorch:24.12-py3-igpu

LABEL maintainer="ai-pipestream"
LABEL description="Jetson-optimized Docker image for docling-serve with full GPU support"

ENV DEBIAN_FRONTEND=noninteractive \
    NVIDIA_VISIBLE_DEVICES=all \
    NVIDIA_DRIVER_CAPABILITIES=compute,utility,video \
    PYTHONIOENCODING=utf-8 \
    PIP_BREAK_SYSTEM_PACKAGES=1 \
    DOCLING_SERVE_ARTIFACTS_PATH=/opt/app-root/src/.cache/docling/models

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    tesseract-ocr libtesseract-dev libleptonica-dev libgl1 libglib2.0-0 git cmake build-essential curl \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Bypass EXTERNALLY-MANAGED for Python 3.12
RUN rm -f /usr/lib/python3.12/EXTERNALLY-MANAGED 2>/dev/null || true

# Install uv for dependency management
COPY --from=ghcr.io/astral-sh/uv:latest /uv /usr/bin/uv

WORKDIR /opt/app-root/src

# Clone the original docling-serve repo to get the latest source
RUN git clone https://github.com/docling-project/docling-serve.git .

# 1. Install project and dependencies into SYSTEM python
# We force transformers >= 4.49.0 to support RT-DETR v2
RUN uv pip install --system "transformers>=4.49.0" .[ui,easyocr,rapidocr] && \
    uv pip uninstall --system tensorflow tensorflow-cpu tensorflow-gpu tensorflow-intel tensorflow-rocm || true

# 2. PATCH transformers to fix RT-DETR v2 model loading on NVIDIA's Torch builds
# This fixes the 'ImportError: cannot import name TransformGetItemToIndex'
RUN sed -i 's/from torch._dynamo._trace_wrapped_higher_order_op import TransformGetItemToIndex/TransformGetItemToIndex = None/g' /usr/local/lib/python3.12/dist-packages/transformers/masking_utils.py

# 3. Download models (pre-baking them into the image for Jetson performance)
RUN echo "Downloading models..." && \
    HF_HUB_DOWNLOAD_TIMEOUT="90" \
    HF_HUB_ETAG_TIMEOUT="90" \
    docling-tools models download -o "${DOCLING_SERVE_ARTIFACTS_PATH}" layout tableformer picture_classifier rapidocr easyocr

EXPOSE 5001

# Run using the entry point script
CMD ["docling-serve", "run", "--host", "0.0.0.0"]
