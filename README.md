# Docling-Serve Jetson GPU Docker

A repository for building and running [docling-serve](https://github.com/docling-project/docling-serve) with full GPU acceleration on NVIDIA Jetson devices (Orin Nano, Orin NX, Xavier, etc.).  

The orin nano has an 8GB GPU memory with CUDA built in.  Perfect for docling testing to offload your host system.

## Why build locally?
Standard Docling images are built for x86_64. Building directly on your Jetson ensures:
1. The image is optimized for your **ARM64** architecture.
2. The models are pre-baked for your specific **JetPack** version.
3. You get the latest **CUDA** optimizations for your Orin/Xavier GPU.

## Prerequisites
- **Hardware:** NVIDIA Jetson (tested on Orin Nano).
- **Software:** 
  - JetPack 6.x (L4T R36.x) installed.
  - [NVIDIA Container Runtime](https://github.com/NVIDIA/nvidia-container-runtime) configured.
  - Docker OCI support enabled (add `"features": { "containerd-snapshotter": true }` to your `/etc/docker/daemon.json`).

## Quick Start

### 1. Build the Image
Clone this repo and run the build script. This will clone the latest docling-serve, apply compatibility patches for Jetson, and bake the models into the image.

```bash
./build.sh
```

### 2. Run with Docker Compose
We've included a compose file to handle the NVIDIA runtime and port mapping automatically:

```bash
docker compose up -d
```

Access the UI at: `http://localhost:5001/ui`

## Technical Details
This build applies a critical patch to the `transformers` library. NVIDIA's optimized Torch builds for Jetson (currently 2.6.0a0) are occasionally missing internal symbols used by the very latest RT-DETR v2 models. Our `Dockerfile` automatically patches the source to ensure these models load correctly on your GPU.

## Contributing
If you find a JetPack version or model that requires a new patch, please open an Issue or PR!
