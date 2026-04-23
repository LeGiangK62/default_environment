#!/usr/bin/env bash
set -euo pipefail

ENV_NAME="${ENV_NAME:-quantum_ml}"
PYTHON_VERSION="3.11"
TORCH_VERSION="2.5.0"

OS_KERNEL="$(uname)"
case "$OS_KERNEL" in
    Darwin)            OS_LABEL="macOS" ;;
    Linux)             OS_LABEL="Linux" ;;
    MINGW*|MSYS*|CYGWIN*) OS_LABEL="Windows" ;;
    *)                 OS_LABEL="$OS_KERNEL" ;;
esac

if command -v nvidia-smi >/dev/null 2>&1 && nvidia-smi >/dev/null 2>&1; then
    HAS_NVIDIA_GPU=1
else
    HAS_NVIDIA_GPU=0
fi

detect_backend() {
    # macOS -> always the "mac" path (no CUDA wheels upstream).
    # Linux or Windows with an NVIDIA GPU -> "gpu" path (CUDA 12.1).
    # Linux or Windows without a GPU      -> "cpu" path.
    if [[ "$OS_KERNEL" == "Darwin" ]]; then
        echo "mac"
    elif [[ "$HAS_NVIDIA_GPU" == "1" ]]; then
        echo "gpu"
    else
        echo "cpu"
    fi
}

BACKEND="$(detect_backend)"
echo "==> OS:       $OS_LABEL"
if [[ "$HAS_NVIDIA_GPU" == "1" ]]; then
    echo "==> NVIDIA GPU: yes (nvidia-smi OK)"
else
    echo "==> NVIDIA GPU: no"
fi
echo "==> Backend:  $BACKEND"

if ! command -v conda >/dev/null 2>&1; then
    echo "ERROR: conda not found. Install Miniconda/Anaconda first." >&2
    exit 1
fi

# shellcheck disable=SC1091
source "$(conda info --base)/etc/profile.d/conda.sh"

if conda env list | awk 'NF && $1 !~ /^#/ {print $1}' | grep -Fxq "$ENV_NAME"; then
    echo "==> Env '$ENV_NAME' already exists, reusing it."
else
    echo "==> Creating env '$ENV_NAME' (Python $PYTHON_VERSION)..."
    conda create -n "$ENV_NAME" "python=$PYTHON_VERSION" -y
fi

conda activate "$ENV_NAME"

echo "==> Installing PyTorch $TORCH_VERSION ($BACKEND)..."
case "$BACKEND" in
    gpu)
        conda install -y \
            "pytorch=$TORCH_VERSION" torchvision torchaudio \
            pytorch-cuda=12.1 \
            -c pytorch -c nvidia
        ;;
    cpu)
        conda install -y \
            "pytorch=$TORCH_VERSION" torchvision torchaudio cpuonly \
            -c pytorch
        ;;
    mac)
        # Mac: the default PyTorch wheel picks MPS/CPU at runtime.
        conda install -y \
            "pytorch=$TORCH_VERSION" torchvision torchaudio \
            -c pytorch
        ;;
esac

echo "==> Installing common pip dependencies..."
pip install -r requirements-common.txt

echo "==> Installing PyG C++ extensions for $BACKEND..."
case "$BACKEND" in
    gpu)
        pip install -r requirements-gpu.txt
        ;;
    cpu)
        pip install -r requirements-cpu.txt
        ;;
    mac)
        # PyG does not publish prebuilt wheels for macOS (Apple Silicon/Intel).
        # The pure-Python torch-geometric package is already installed via
        # requirements-common.txt and works for most models. The C++ extensions
        # (pyg_lib, torch_scatter, ...) are only needed for specific ops;
        # build from source if required, e.g.:
        #   pip install git+https://github.com/rusty1s/pytorch_scatter.git
        echo "    (skipped -- no prebuilt wheels on macOS; build from source if needed)"
        ;;
esac

echo ""
echo "==> Done."
echo "    Activate:  conda activate $ENV_NAME"
echo "    Verify:    python check.py"
