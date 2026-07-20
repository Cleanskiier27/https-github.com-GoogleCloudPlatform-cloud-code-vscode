#!/usr/bin/env bash
set -euo pipefail

echo "Checking for nvcc..."
if command -v nvcc >/dev/null 2>&1; then
  echo "nvcc found — will attempt to compile CUDA kernel (optional)"
  nvcc -c src/cuda_kernels.cu -o src/cuda_kernels.o || true
  echo "CUDA object built at src/cuda_kernels.o"
else
  echo "nvcc not found — skipping CUDA compile"
fi

echo "Running node-gyp build (may compile the addon)"
node-gyp configure build

echo "Done"
