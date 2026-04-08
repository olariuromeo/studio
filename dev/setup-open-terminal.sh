#!/bin/bash
# ----------------------------------------------------------------------------------#
#                                                                                   #
#   Copyright (C) 2009 - 2026 Coozila! Licensed under the MIT License.              #
#   Coozila! Team    lab@coozila.com                                               #
#                                                                                   #
# ----------------------------------------------------------------------------------#
# Document: dev/setup-open-terminal.sh
# Description: Clone Open Terminal into apps/open-terminal and start with dev Terminal stack
# ----------------------------------------------------------------------------------#
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OPEN_TERMINAL_DIR="$ROOT_DIR/apps/open-terminal"
COMPOSE_FILE="$ROOT_DIR/dev/terminal.yaml"

# Load repo URL from environment or repo config (no hard-coded URL here)
# Priority: OPEN_TERMINAL_REPO env var > OPEN_TERMINAL_REPO from .env.open_terminal > default
REPO_URL_DEFAULT="https://github.com/kabballa/open-terminal.git"

ENV_FILE="$ROOT_DIR/.env.open_terminal"
if [ -f "$ENV_FILE" ]; then
  # Source file to expose OPEN_TERMINAL_REPO if defined
  source "$ENV_FILE"
fi

REPO_URL="${OPEN_TERMINAL_REPO:-$REPO_URL_DEFAULT}"

# 1) Clone/Open Terminal repo if missing
if [ ! -d "$OPEN_TERMINAL_DIR/.git" ]; then
  echo "🔁 Cloning Open Terminal into $OPEN_TERMINAL_DIR..."
  git clone "$REPO_URL" "$OPEN_TERMINAL_DIR"
else
  echo "🔄 Updating Open Terminal at $OPEN_TERMINAL_DIR..."
  git -C "$OPEN_TERMINAL_DIR" fetch --all --recurse-submodules
  git -C "$OPEN_TERMINAL_DIR" pull --rebase
fi

# 2) Verify docker-compose file exists
if [ ! -f "$COMPOSE_FILE" ]; then
  echo "❌ Docker compose file $COMPOSE_FILE is missing. Please ensure the file exists."
  exit 1
fi

# 3) Launch stack using the single Compose file
echo "🚀 Launching stack using $COMPOSE_FILE..."
docker compose -f "$COMPOSE_FILE" up -d --build

echo -e "\n✅ Open Terminal stack is live. Check with: docker ps"