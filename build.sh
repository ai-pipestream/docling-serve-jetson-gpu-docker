#!/bin/bash
set -e

IMAGE_NAME="docling-serve-jetson"

echo "🚀 Starting Jetson-optimized build for Docling..."
docker build \
  --platform linux/arm64 \
  -t $IMAGE_NAME:latest \
  .

echo ""
echo "✅ Build complete!"
echo "You can now start the service with: docker compose up -d"
