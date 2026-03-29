# 🛠️ Detailed Installation Guide

This guide ensures your environment is perfectly tuned for **Python 3.11.9** and **Node 20.18.1**—the recommended stack for Coozila! Video Studio.

## 1. Prerequisites
Ensure you have `asdf`, `git`, and `ffmpeg` installed on your system.

### System Dependencies (Linux Example)
```bash
sudo apt update && sudo apt install ffmpeg build-essential libssl-dev zlib1g-dev libsqlite3-dev
```

## 2. Version Management (asdf)
We use `asdf` to lock the versions and prevent "it works on my machine" issues.

```bash
# Install specific versions
asdf install python 3.11.9
asdf install nodejs 20.18.1

# Set local project versions
asdf local python 3.11.9
asdf local nodejs 20.18.1
```

## 3. Environment Setup
Create a fresh virtual environment to isolate the Studio dependencies.

```bash
# Delete old venv if exists
rm -rf venv

# Create and activate new venv
python -m venv venv
source venv/bin/activate

# Upgrade Pip
pip install --upgrade pip
```

## 4. Install Dependencies
Install the specific libraries required for audio analysis and AI orchestration.

```bash
pip install open-webui librosa numpy aiohttp requests ffmpeg-python Pillow python-dotenv
```

## 5. Initialize Coozila! Studio
Run the setup script to generate the directory structure and default JSON templates.

```bash
python setup_studio.py
```

## 6. Launch
Start the OpenWebUI server. The Studio button will appear in the chat interface automatically.

```bash
open-webui serve
```