#!/bin/bash
# 01_setup_python.sh — Install Python 3.11 and bootstrap pip
set -e
echo "======================================"
echo " STEP 1: Python 3.11 Setup"
echo "======================================"

# Detect architecture
ARCH=$(uname -m)
echo "→ Architecture: $ARCH"

# Install Python 3.11 via Homebrew if not present
if ! command -v python3.11 &>/dev/null; then
  echo "→ Installing Python 3.11 via Homebrew..."
  brew install python@3.11
else
  echo "→ Python 3.11 already installed: $(python3.11 --version)"
fi

# Add to PATH based on architecture
if [ "$ARCH" = "arm64" ]; then
  BREW_PYTHON_PATH="/opt/homebrew/opt/python@3.11/bin"
else
  BREW_PYTHON_PATH="/usr/local/opt/python@3.11/bin"
fi

if [ -d "$BREW_PYTHON_PATH" ]; then
  export PATH="$BREW_PYTHON_PATH:$PATH"
  # Add to zprofile if not already there
  if ! grep -q "python@3.11" ~/.zprofile 2>/dev/null; then
    echo "export PATH=\"$BREW_PYTHON_PATH:\$PATH\"" >> ~/.zprofile
    echo "→ Added Python 3.11 to ~/.zprofile"
  fi
fi

# Bootstrap pip if missing
if ! python3.11 -m pip --version &>/dev/null; then
  echo "→ pip not found — bootstrapping with get-pip.py..."
  curl -fsSL https://bootstrap.pypa.io/get-pip.py -o /tmp/get-pip.py
  python3.11 /tmp/get-pip.py
  rm /tmp/get-pip.py
else
  echo "→ pip available: $(python3.11 -m pip --version)"
fi

# Install huggingface_hub (provides hf CLI)
echo "→ Installing huggingface_hub..."
python3.11 -m pip install --upgrade huggingface_hub

# Add user scripts bin to PATH so 'hf' CLI works
USER_BIN=$(python3.11 -m site --user-base)/bin
export PATH="$USER_BIN:$PATH"
if ! grep -q "site --user-base" ~/.zprofile 2>/dev/null; then
  echo 'export PATH="$(python3.11 -m site --user-base)/bin:$PATH"' >> ~/.zprofile
fi

echo ""
echo "✅ DONE: Python setup complete"
python3.11 --version
python3.11 -m pip --version
echo "hf CLI: $(hf --version 2>/dev/null || echo 'restart terminal to activate PATH')"
