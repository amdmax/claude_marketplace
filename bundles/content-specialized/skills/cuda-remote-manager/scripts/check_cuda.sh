#!/bin/bash
# Check CUDA environment and GPU status on cuda-dev

echo "=== GPU Status ==="
ssh cuda-dev 'nvidia-smi'

echo ""
echo "=== CUDA Toolkit ==="
ssh cuda-dev '/usr/local/cuda-13.1/bin/nvcc --version'

echo ""
echo "=== vLLM Status ==="
if ssh cuda-dev 'pgrep -f "python -m vllm" > /dev/null'; then
    echo "✓ vLLM is running"
    ssh cuda-dev 'ps aux | grep "[p]ython -m vllm"'
else
    echo "✗ vLLM is not running"
fi

echo ""
echo "=== Disk Space ==="
ssh cuda-dev 'df -h ~/vllm-models'
