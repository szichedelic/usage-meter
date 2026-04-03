#!/bin/bash
set -e

VENV_DIR="$HOME/.usage-meter/venv"
PROFILE_DIR="$HOME/.usage-meter/profiles"

mkdir -p "$PROFILE_DIR"

if [ ! -d "$VENV_DIR" ]; then
    echo "Creating virtual environment..."
    python3 -m venv "$VENV_DIR"
fi

echo "Installing dependencies..."
"$VENV_DIR/bin/pip" install -q -r "$(dirname "$0")/../scraper/requirements.txt"

echo "Setting up Camoufox..."
"$VENV_DIR/bin/python" -c "import camoufox; print('Camoufox ready')"

echo "Setup complete."
