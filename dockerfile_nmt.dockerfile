# CUDA 12.6 base image (matches your system)
FROM nvidia/cuda:12.6.0-runtime-ubuntu20.04

# Set environment variables
ENV PYTHONUNBUFFERED=1
ENV DEBIAN_FRONTEND=noninteractive
ENV CUDA_VISIBLE_DEVICES=0

# Set CUDA environment variables
ENV CUDA_HOME=/usr/local/cuda
ENV PATH=${CUDA_HOME}/bin:${PATH}
ENV LD_LIBRARY_PATH=${CUDA_HOME}/lib64:${LD_LIBRARY_PATH}

# Install system dependencies
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    python3-venv \
    curl \
    wget \
    git \
    && rm -rf /var/lib/apt/lists/*

# Create working directory
WORKDIR /app

# Copy requirements and install Python dependencies
COPY requirements.txt .

# Install PyTorch with CUDA 12.6 support
RUN pip3 install --no-cache-dir torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu126

# Install other dependencies
RUN pip3 install --no-cache-dir -r requirements.txt

# Copy application code and fine-tuned model
COPY app/ ./app/
COPY finetuned_en_fr/ ./finetuned_en_fr/

# Create a test script to verify GPU access
RUN echo '#!/bin/bash\n\
echo "=== GPU Configuration Test ===\n\
nvidia-smi\n\
echo "CUDA Version:"\n\
nvcc --version || echo "nvcc not available"\n\
echo "Python CUDA check:"\n\
python3 -c "import torch; print(f\"PyTorch version: {torch.__version__}\"); print(f\"CUDA available: {torch.cuda.is_available()}\"); print(f\"CUDA version: {torch.version.cuda}\"); [torch.cuda.is_available()] and print(f\"GPU device: {torch.cuda.get_device_name(0)}\")"\n\
echo "=== Test Complete ==="' > /app/test_gpu.sh && chmod +x /app/test_gpu.sh

# Expose port
EXPOSE 8000

# Health check with GPU verification
HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8000/health || exit 1

# Start the application with multiple workers for parallel processing
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000", "--workers", "2"]