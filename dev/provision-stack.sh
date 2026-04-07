#!/bin/bash
# ----------------------------------------------------------------------------------#
#                                                                                   #
#   Copyright (C) 2009 - 2026 Coozila! Licensed under the MIT License.              #
#   Coozila! Team    lab@coozila.com                                                #
#                                                                                   #
# ----------------------------------------------------------------------------------#
# Document: dev/provision-stack.sh
# Description: Container-native Provisioning for Coozila! Distributed Stack
# ----------------------------------------------------------------------------------#
set -e

STUDIO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# 1. Load Environment
if [ -f "$STUDIO_ROOT/.env.dev" ]; then
    export $(grep -v '^#' "$STUDIO_ROOT/.env.dev" | xargs)
else
    echo "❌ [ERROR] .env.dev missing. Required for Container Mapping."
    exit 1
fi

echo "🐳 [DOCKER] Provisioning Coozila! Studio v4.2 Stack..."

# 2. Sync MCP-Proxy Submodule
# Link: https://github.com/kabballa/mcp-proxy
PROXY_DIR="apps/mcp-proxy"
PROXY_REPO="https://github.com/kabballa/mcp-proxy.git"

if [ ! -d "$STUDIO_ROOT/$PROXY_DIR" ]; then
    echo "   -> [REGISTER] Adding MCP-Proxy Submodule..."
    git submodule add -f "$PROXY_REPO" "$PROXY_DIR"
fi

echo "   -> Updating all submodules (Proxy, Studio, Search)..."
git submodule update --init --recursive

# 3. Create Persistent Volumes (Local Mount Points)
echo "📁 [STORAGE] Preparing Data Plane Volumes..."
mkdir -p "$STUDIO_ROOT/data/minio"
mkdir -p "$STUDIO_ROOT/data/postgres"
mkdir -p "$STUDIO_ROOT/logs"

# 4. Docker Compose Generation Trigger
# Verificăm dacă fișierul mcp-proxy.yml există
if [ ! -f "$STUDIO_ROOT/mcp-proxy.yml" ]; then
    echo "❌ [ERROR] mcp-proxy.yml not found in root."
    exit 1
fi

# 5. Build and Launch
echo "🚀 [STACK] Launching Coozila! Distributed Environment..."
docker compose -f "$STUDIO_ROOT/mcp-proxy.yml" --env-file "$STUDIO_ROOT/.env.dev" up -d --build

echo -e "\n✅ [SUCCESS] Coozila! Stack is live."
echo "🔗 Proxy Gateway: $MCP_PROXY_URL"
echo "📂 Storage (MinIO): $S3_ENDPOINT"
echo "📺 Canvas UI: http://localhost:$STUDIO_PORT"