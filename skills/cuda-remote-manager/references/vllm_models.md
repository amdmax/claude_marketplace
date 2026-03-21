# vLLM Model Guide

## Tested Models on RTX 5090

### ✓ Working Models

#### Qwen/Qwen2.5-Coder-7B-Instruct (Recommended)
- **Size**: 7B parameters
- **Context**: 128K (131,072 input tokens, 32,768 output tokens)
- **VRAM Usage**: ~14GB
- **Performance**: Fast, reliable
- **Command**:
```bash
scripts/start_vllm.sh Qwen/Qwen2.5-Coder-7B-Instruct 131072 0.85 8000
```

### ✗ Known Issues

#### Qwen/Qwen2.5-Coder-14B-Instruct
- **Issue**: Fails to load with negative KV cache memory
- **Error**: "Available KV cache memory: -2.41 GiB"
- **Attempts**: Tried 8K, 16K, 32K context with various GPU memory settings
- **Status**: Not working with vLLM 0.13.0 on RTX 5090

#### deepseek-ai/DeepSeek-R1-Distill-Qwen-32B
- **Issue**: Similar negative KV cache issue
- **Status**: Untested, likely same problem as 14B model
- **Reference**: https://github.com/vllm-project/vllm/issues/14452

#### deepseek-ai/DeepSeek-V3.2
- **Size**: 671B parameters (37B activated per token)
- **Requirement**: 8x GPUs with tensor parallelism
- **Status**: Too large for single RTX 5090

## Model Selection Guidelines

### For Single RTX 5090 (32GB)

**Optimal Choice**: Qwen/Qwen2.5-Coder-7B-Instruct with 128K context
- Best balance of capability and reliability
- Large context window for complex tasks
- Proven to work with current vLLM setup

**Alternative Models to Try**:
- Qwen/Qwen2.5-Coder-1.5B-Instruct (faster, less capable)
- Other 7B models from Qwen2.5 family
- Models specifically optimized for code generation

### Required Environment Variables

Always use these for RTX 5090:
```bash
VLLM_FLASH_ATTN_VERSION=2          # Flash Attention 2 for Blackwell
VLLM_ALLOW_LONG_MAX_MODEL_LEN=1   # Enable extended context
```

## Starting Different Models

### Pattern
```bash
ssh cuda-dev 'bash -c "source ~/vllm-env/bin/activate && cd ~/vllm-models && \
VLLM_FLASH_ATTN_VERSION=2 VLLM_ALLOW_LONG_MAX_MODEL_LEN=1 \
nohup python -m vllm.entrypoints.openai.api_server \
--model <MODEL_NAME> \
--host 0.0.0.0 \
--port 8000 \
--gpu-memory-utilization <0.8-0.9> \
--max-model-len <CONTEXT_SIZE> \
--tensor-parallel-size 1 \
> <LOG_FILE>.log 2>&1 &"'
```

### Examples

**128K Context (Recommended)**:
```bash
scripts/start_vllm.sh Qwen/Qwen2.5-Coder-7B-Instruct 131072 0.85 8000
```

**32K Context (Lower memory)**:
```bash
scripts/start_vllm.sh Qwen/Qwen2.5-Coder-7B-Instruct 32768 0.9 8000
```

**8K Context (Minimal memory)**:
```bash
scripts/start_vllm.sh Qwen/Qwen2.5-Coder-7B-Instruct 8192 0.9 8000
```

## Monitoring

### Check vLLM Logs
```bash
ssh cuda-dev 'tail -f ~/vllm-models/vllm-*.log'
```

### Check GPU Usage
```bash
ssh cuda-dev 'nvidia-smi'
```

### Check vLLM Process
```bash
ssh cuda-dev 'ps aux | grep "[p]ython -m vllm"'
```

## Troubleshooting

### Model Download Issues
- Models auto-download from HuggingFace on first use
- Requires internet connection on cuda-dev
- Downloads go to `~/.cache/huggingface/`

### Out of Memory Errors
- Reduce `--gpu-memory-utilization` (try 0.8 or 0.75)
- Reduce `--max-model-len` (try 32768 or 16384)
- Use smaller model variant

### Negative KV Cache Memory
- Known issue with RTX 5090 and certain model sizes
- No current workaround for 14B+ models
- Stick with 7B models until vLLM updates
