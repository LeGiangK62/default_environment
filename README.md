# Quantum + GNN environment

Môi trường conda `quantum_ml` (Python 3.11, PyTorch 2.5.0) cho quantum ML (PennyLane/Qiskit) và GNN (PyTorch Geometric).

## Cách cài (1 lệnh, tự detect GPU/Mac/CPU)

```bash
./install.sh
```

Script sẽ:
1. Detect backend — `nvidia-smi` có GPU → `gpu`; Mac (`Darwin`) → `mac`; còn lại → `cpu`.
2. Tạo conda env `quantum_ml` nếu chưa có.
3. Cài PyTorch 2.5.0 phù hợp với backend (CUDA 12.1 / `cpuonly` / default cho Mac MPS).
4. Cài `requirements-common.txt` (numpy, PennyLane, Qiskit, `torch-geometric`, ...).
5. Cài PyG C++ extensions (`pyg_lib`, `torch_scatter`, `torch_sparse`, `torch_cluster`, `torch_spline_conv`) từ wheel URL tương ứng (`+cu121` hoặc `+cpu`). Mac bỏ qua bước này vì PyG không ship prebuilt wheels — `torch-geometric` pure-Python vẫn hoạt động cho phần lớn model.

Đổi tên env nếu muốn:
```bash
ENV_NAME=my_env ./install.sh
```

## Verify

```bash
conda activate quantum_ml
python check.py
```

## Layout

| File | Dùng khi |
| --- | --- |
| `install.sh` | Entry point, detect backend và gọi các file bên dưới |
| `requirements-common.txt` | Luôn cài (numpy, scipy, jupyter, PennyLane, Qiskit, `torch-geometric`, ...) |
| `requirements-gpu.txt` | Chỉ cài khi có CUDA (PyG extensions `+cu121`) |
| `requirements-cpu.txt` | Chỉ cài khi CPU-only Linux/Windows (PyG extensions `+cpu`) |
| `check.py` | Smoke-test import + CUDA availability |

## Khi không có GPU

- **Linux/Windows không GPU**: script tự chọn `cpu` path → cài `cpuonly` PyTorch + `+cpu` wheels. Code không dùng `.cuda()` vẫn chạy bình thường.
- **Mac**: chọn `mac` path → PyTorch bản default (hỗ trợ MPS), bỏ PyG extensions. Nếu model cần `torch_scatter`/`torch_sparse`, build from source:
  ```bash
  pip install git+https://github.com/rusty1s/pytorch_scatter.git
  pip install git+https://github.com/rusty1s/pytorch_sparse.git
  ```

## Force backend (debug)

Sửa hàm `detect_backend` trong `install.sh` để return hard-coded `gpu`/`cpu`/`mac` nếu muốn test path khác.
