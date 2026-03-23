#!/bin/bash
# Start vLLM server on cuda-dev with specified model

set -e

MODEL="${1:-Qwen/Qwen2.5-Coder-7B-Instruct}"
MAX_LEN="${2:-131072}"
GPU_UTIL="${3:-0.85}"
PORT="${4:-8000}"

# Stop any existing vLLM process
ssh cuda-dev 'pkill -f "python -m vllm" || true'

# Start vLLM with Flash Attention 2 for RTX 5090 compatibility
ssh cuda-dev "bash -c \"source ~/vllm-env/bin/activate && cd ~/vllm-models && \
VLLM_FLASH_ATTN_VERSION=2 VLLM_ALLOW_LONG_MAX_MODEL_LEN=1 \
nohup python -m vllm.entrypoints.openai.api_server \
--model ${MODEL} \
--host 0.0.0.0 \
--port ${PORT} \
--gpu-memory-utilization ${GPU_UTIL} \
--max-model-len ${MAX_LEN} \
--tensor-parallel-size 1 \
> vllm-$(basename ${MODEL})-${MAX_LEN}.log 2>&1 &\""

echo "vLLM server starting with:"
echo "  Model: ${MODEL}"
echo "  Max length: ${MAX_LEN}"
echo "  GPU utilization: ${GPU_UTIL}"
echo "  Port: ${PORT}"
echo ""
echo "Check logs: ssh cuda-dev 'tail -f ~/vllm-models/vllm-*.log'"
