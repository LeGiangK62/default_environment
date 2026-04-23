# Quantum + GNN environment

Conda environment `quantum_ml` (Python 3.11, PyTorch 2.5.0) for quantum ML (PennyLane/Qiskit) and GNNs (PyTorch Geometric).

## Install (one command, auto-detects GPU/Mac/CPU)

```bash
./install.sh
```

The script will:
1. Detect the backend -- `nvidia-smi` present -> `gpu`; macOS (`Darwin`) -> `mac`; otherwise -> `cpu`.
2. Create the conda env `quantum_ml` if it does not exist.
3. Install the matching PyTorch 2.5.0 build (CUDA 12.1 / `cpuonly` / default for Mac MPS).
4. Install `requirements-common.txt` (numpy, PennyLane, Qiskit, `torch-geometric`, ...).
5. Install the PyG C++ extensions (`pyg_lib`, `torch_scatter`, `torch_sparse`, `torch_cluster`, `torch_spline_conv`) from the matching wheel URL (`+cu121` or `+cpu`). macOS skips this step because PyG does not ship prebuilt wheels there -- the pure-Python `torch-geometric` package still works for most models.

Override the env name if desired:
```bash
ENV_NAME=my_env ./install.sh
```

## Manual Installation

If you would rather run the steps yourself, pick the backend that matches your machine.

### 1. Create and activate the conda env (all backends)

```bash
conda create -n quantum_ml python=3.11 -y
conda activate quantum_ml
```

### 2. Install PyTorch + PyG extensions based on backend

**GPU (Linux/Windows with CUDA 12.1):**
```bash
conda install -y pytorch=2.5.0 torchvision torchaudio pytorch-cuda=12.1 -c pytorch -c nvidia
pip install -r requirements-common.txt
pip install -r requirements-gpu.txt
```

**CPU-only (Linux/Windows without a GPU):**
```bash
conda install -y pytorch=2.5.0 torchvision torchaudio cpuonly -c pytorch
pip install -r requirements-common.txt
pip install -r requirements-cpu.txt
```

**macOS (Apple Silicon / Intel):**
```bash
conda install -y pytorch=2.5.0 torchvision torchaudio -c pytorch
pip install -r requirements-common.txt
# PyG extensions have no prebuilt wheels on macOS -- skip, or build from source if needed.
```

## Verify

```bash
conda activate quantum_ml
python check.py
```

## Layout

| File | When it is used |
| --- | --- |
| `install.sh` | Entry point; detects backend and drives the files below |
| `requirements-common.txt` | Always installed (numpy, scipy, jupyter, PennyLane, Qiskit, `torch-geometric`, ...) |
| `requirements-gpu.txt` | Installed only with CUDA (PyG extensions `+cu121`) |
| `requirements-cpu.txt` | Installed only on CPU-only Linux/Windows (PyG extensions `+cpu`) |
| `check.py` | Smoke test: imports + CUDA availability |

## When you have no GPU

- **Linux/Windows without a GPU**: the script picks the `cpu` path and installs `cpuonly` PyTorch + `+cpu` wheels. Any code that does not call `.cuda()` works as-is.
- **macOS**: the `mac` path installs the default PyTorch build (MPS-capable) and skips the PyG extensions. If your model needs `torch_scatter`/`torch_sparse`, build them from source:
  ```bash
  pip install git+https://github.com/rusty1s/pytorch_scatter.git
  pip install git+https://github.com/rusty1s/pytorch_sparse.git
  ```

## Force a backend (debug)

Edit the `detect_backend` function in `install.sh` to hard-code `gpu`/`cpu`/`mac` when you want to test a different path.
