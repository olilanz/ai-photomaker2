#!/bin/bash

set -euo pipefail  # Exit on error, show commands, handle pipes safely

echo "🔧 Starting PM2 container startup script..."

# Set up environment variables
PM2_AUTO_UPDATE=${PM2_AUTO_UPDATE:-0}

CACHE_HOME="/workspace/cache"
export HF_HOME="${CACHE_HOME}/huggingface"
export TORCH_HOME="${CACHE_HOME}/torch"
INSIGHTFACE_HOME="${CACHE_HOME}/insightface"
OUTPUT_HOME="/workspace/output"

echo "📂 Setting up cache directories..."
mkdir -p "${CACHE_HOME}" "${HF_HOME}" "${TORCH_HOME}" "${INSIGHTFACE_HOME}" "${OUTPUT_HOME}"

# Clone or update HVGP
PM2_HOME="${CACHE_HOME}/PM2"
if [ ! -d "$PM2_HOME" ]; then
    echo "📥 Unpacking PM2 repository..."
    mkdir -p "$PM2_HOME"
    tar -xzvf PM2.tar.gz --strip-components=1 -C "$PM2_HOME"
fi
if [[ "$PM2_AUTO_UPDATE" == "1" ]]; then
    echo "🔄 Updating the PM2 repository..."
    git -C "$PM2_HOME" reset --hard
    git -C "$PM2_HOME" pull
fi

# Ensure symlinks for models & output
ln -sfn "${INSIGHTFACE_HOME}" ~/.insightface

# Virtual environment setup
VENV_HOME="${CACHE_HOME}/venv"
echo "📦 Setting up Python virtual environment..."
if [ ! -d "$VENV_HOME" ]; then
    # Create virtual environment, but re-use globally installed packages if available (e.g. via base container)
    python3 -m venv "$VENV_HOME" --system-site-packages
fi
source "${VENV_HOME}/bin/activate"

# Ensure latest pip version
pip install --no-cache-dir --upgrade pip wheel

# install a few modules with specific version requirements
echo "📦 Installing Python dependencies..."
pip install --no-cache-dir \
    gradio==4.44.1 \
    devicetorch \
    torchvision

# Install required dependencies
pip install --no-cache-dir -r "$PM2_HOME/requirements.txt"
pip install --no-cache-dir \
    onnxruntime-gpu

# PhotoMaker is loaded as a Python Module - directly out of the git repo
export PYTHONPATH="$PM2_HOME"

# patching the start-up function, so that the script listens on the public network interface
if grep -q 'demo.launch(server_name="0.0.0.0", server_port=7860)' "$PM2_HOME/app.py"; then
    echo "Launch function is already patched."
else
    # Replace demo.launch() with demo.launch(server_name="0.0.0.0", server_port=7860)
    sed -i 's/demo.launch()/demo.launch(server_name="0.0.0.0", server_port=7860)/g' "$PM2_HOME/app.py"
    echo "Launch function patched with server_name=\"0.0.0.0\", server_port=7860."
fi

# Start the service
echo "🚀 Starting HVGP service..."
cd  "$PM2_HOME"
python3 -u app.py 2>&1 | tee "${CACHE_HOME}/output.log"
echo "❌ The HVGP service has terminated."
