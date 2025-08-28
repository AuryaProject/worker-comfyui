#!/usr/bin/env bash

set -e

# Ativar verbose se configurado
[ "${VERBOSE}" = "true" ] && set -x

SNAPSHOT_FILE=$(ls /**/*snapshot*.json 2>/dev/null | head -n 1)

if [ -z "$SNAPSHOT_FILE" ]; then
    echo "worker-comfyui: No snapshot file found. Exiting..."
    sleep 5
    exit 0
fi

echo "worker-comfyui: restoring snapshot: $SNAPSHOT_FILE"

# Adicionar flags verbose ao comfy
if [ "${VERBOSE}" = "true" ]; then
    comfy --verbose --workspace /comfyui node restore-snapshot "$SNAPSHOT_FILE" --pip-non-url --verbose
else
    comfy --workspace /comfyui node restore-snapshot "$SNAPSHOT_FILE" --pip-non-url
fi

echo "worker-comfyui: restored snapshot file: $SNAPSHOT_FILE"
sleep 5