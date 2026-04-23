import torch
import torch_geometric
import pennylane as qml
import qiskit

print(f"✓ PyTorch: {torch.__version__}")
print(f"✓ CUDA: {torch.cuda.is_available()}")
print(f"✓ Torch-Geometric: {torch_geometric.__version__}")
print(f"✓ Pennylane: {qml.__version__}")
print(f"✓ Qiskit: {qiskit.__version__}")