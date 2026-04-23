#!/usr/bin/env bash
set -euo pipefail

ENV_NAME="${ENV_NAME:-quantum_ml}"
PYTHON_VERSION="3.11"
TORCH_VERSION="2.5.0"

detect_backend() {
    if [[ "$(uname)" == "Darwin" ]]; then
        echo "mac"
    elif command -v nvidia-smi >/dev/null 2>&1 && nvidia-smi >/dev/null 2>&1; then
        echo "gpu"
    else
        echo "cpu"
    fi
}

BACKEND="$(detect_backend)"
echo "==> Detected backend: $BACKEND"

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
        # Mac: PyTorch wheel tự chọn MPS/CPU lúc runtime
        conda install -y \
            "pytorch=$TORCH_VERSION" torchvision torchaudio \
            -c pytorch
        ;;
esac

echo "==> Installing common pip deps..."
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
        # PyG không publish prebuilt wheels cho Mac (Apple Silicon/Intel).
        # torch-geometric (pure Python) đã cài ở requirements-common.txt và dùng được
        # cho phần lớn model; các extension (pyg_lib, torch_scatter, ...) chỉ cần
        # nếu bạn dùng các op cụ thể — lúc đó build from source:
        #   pip install git+https://github.com/rusty1s/pytorch_scatter.git
        echo "    (skipped — Mac không có prebuilt wheels; build from source nếu cần)"
        ;;
esac

echo ""
echo "==> Done."
echo "    Activate:  conda activate $ENV_NAME"
echo "    Verify:    python check.py"
