# CUDA Development Machine Specifications

## Hardware

- **Host**: cuda-dev (m@192.168.250.179)
- **GPU**: NVIDIA GeForce RTX 5090, 32GB GDDR7
- **Architecture**: Blackwell (sm_120)
- **RAM**: 96GB
- **OS**: Debian

## CUDA Environment

- **Driver**: 580.82.07
- **CUDA Version**: 13.0 (from driver)
- **CUDA Toolkit**: 13.1 installed at `/usr/local/cuda-13.1/`
- **Compiler**: nvcc (release 13.1, V13.1.80)
- **Architecture Flag**: `-arch=sm_120` for RTX 5090

## SSH Configuration

SSH alias `cuda-dev` is configured in `~/.ssh/config`:

```
Host cuda-dev
  HostName 192.168.250.179
  User m
  ForwardAgent yes
  ServerAliveInterval 60
  ServerAliveCountMax 3
```

## Project Directories

- **CUDA Learning**: `/home/m/cuda-learning/`
- **vLLM Models**: `/home/m/vllm-models/`
- **vLLM Environment**: `/home/m/vllm-env/` (Python virtual environment)

## vLLM Configuration

### Current Setup

- **Model**: Qwen/Qwen2.5-Coder-7B-Instruct
- **Context Window**: 128K (131,072 input tokens, 32,768 output tokens)
- **Server**: http://192.168.250.179:8000
- **API**: OpenAI-compatible

### RTX 5090 Compatibility

The RTX 5090 (Blackwell architecture) requires special configuration for vLLM:

- `VLLM_FLASH_ATTN_VERSION=2` - Flash Attention 3 doesn't support Blackwell yet
- `VLLM_ALLOW_LONG_MAX_MODEL_LEN=1` - Enables extended context windows beyond model defaults

### Known Limitations

- **14B+ Models**: DeepSeek-R1-Distill-Qwen-32B and Qwen2.5-Coder-14B fail to load with vLLM 0.13.0 on RTX 5090
  - Error: Negative KV cache memory despite sufficient VRAM
  - GitHub Issue: https://github.com/vllm-project/vllm/issues/14452
  - Workaround: Use 7B models with extended context

## LiteLLM Proxy

### Local Setup

- **URL**: http://localhost:4000
- **Config**: `/Users/thesolutionarchitect/Documents/source/litellm/cuda_vllm_config.yaml`
- **API Key**: `sk-litellm-cuda`
- **Models**: `qwen-coder`, `qwen-coder-7b`

### Architecture

```
User → LiteLLM (localhost:4000) → vLLM (192.168.250.179:8000) → RTX 5090
```

## VS Code Remote Development

### Required Extensions

- Remote - SSH (`ms-vscode-remote.remote-ssh`)
- C/C++ (`ms-vscode.cpptools`)
- C/C++ Extension Pack (`ms-vscode.cpptools-extension-pack`)
- Nsight Visual Studio Code Edition (`nvidia.nsight-vscode-edition`)

### Workspace

- **File**: `/home/m/cuda-learning/cuda-remote.code-workspace`
- **Compiler Path**: `/usr/local/cuda-13.1/bin/nvcc`
- **Include Path**: `/usr/local/cuda-13.1/include`

### macOS Requirement

VS Code requires "Local Network" permission in System Settings → Privacy & Security → Local Network to connect to local IP addresses like 192.168.250.179.
