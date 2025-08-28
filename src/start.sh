#!/usr/bin/env bash

# ==============================================================================
# CONFIGURAÇÃO DE LINKS SIMBÓLICOS PARA RUNPOD VOLUME
# ==============================================================================

echo "worker-comfyui: Setting up symbolic links from RunPod volume..."

# Função para criar links de forma segura
create_symlinks() {
    local source_dir="$1"
    local target_dir="$2"
    
    if [ -d "$source_dir" ]; then
        echo "  Linking: $source_dir -> $target_dir"
        mkdir -p "$target_dir"
        
        # Criar links para cada item no diretório
        for item in "$source_dir"/*; do
            if [ -e "$item" ]; then
                item_name=$(basename "$item")
                target_item="$target_dir/$item_name"
                
                # Remove link/arquivo existente se houver
                [ -L "$target_item" ] && rm "$target_item"
                [ -e "$target_item" ] || ln -sf "$item" "$target_item"
            fi
        done
        echo "  ✓ Linked $(ls -1 "$source_dir" 2>/dev/null | wc -l) items"
    else
        echo "  ✗ Source not found: $source_dir"
    fi
}

# Verificar se existe o volume do RunPod montado
if [ -d "/runpod-volume" ]; then
    echo "worker-comfyui: RunPod volume detected at /runpod-volume"
    
    # Links para ComfyUI completo (se existir)
    if [ -d "/runpod-volume/comfyui" ]; then
        echo "worker-comfyui: Found ComfyUI directory in volume, creating links..."
        
        # Links para modelos
        for model_type in checkpoints loras vae controlnet embeddings upscale_models clip clip_vision configs hypernetworks style_models ipadapter instantid insightface ultralytics animatediff_models animatediff_motion_lora; do
            create_symlinks "/runpod-volume/comfyui/models/$model_type" "/comfyui/models/$model_type"
        done
        
        # Links para custom nodes
        if [ -d "/runpod-volume/comfyui/custom_nodes" ]; then
            echo "worker-comfyui: Linking custom nodes..."
            for node_dir in /runpod-volume/comfyui/custom_nodes/*; do
                if [ -d "$node_dir" ]; then
                    node_name=$(basename "$node_dir")
                    target_node="/comfyui/custom_nodes/$node_name"
                    
                    # Só criar link se o node não existir
                    if [ ! -e "$target_node" ]; then
                        ln -sf "$node_dir" "$target_node"
                        echo "  ✓ Linked node: $node_name"
                    else
                        echo "  → Node already exists: $node_name (skipping)"
                    fi
                fi
            done
        fi
        
        # Links para inputs (opcional)
        create_symlinks "/runpod-volume/comfyui/input" "/comfyui/input"
        
    # Fallback: estrutura simplificada (models e custom_nodes direto no volume)
    elif [ -d "/runpod-volume/models" ] || [ -d "/runpod-volume/custom_nodes" ]; then
        echo "worker-comfyui: Found simplified structure in volume, creating links..."
        
        # Links diretos para modelos
        if [ -d "/runpod-volume/models" ]; then
            for model_type in /runpod-volume/models/*; do
                if [ -d "$model_type" ]; then
                    type_name=$(basename "$model_type")
                    create_symlinks "$model_type" "/comfyui/models/$type_name"
                fi
            done
        fi
        
        # Links diretos para custom nodes
        if [ -d "/runpod-volume/custom_nodes" ]; then
            for node_dir in /runpod-volume/custom_nodes/*; do
                if [ -d "$node_dir" ]; then
                    node_name=$(basename "$node_dir")
                    target_node="/comfyui/custom_nodes/$node_name"
                    
                    if [ ! -e "$target_node" ]; then
                        ln -sf "$node_dir" "$target_node"
                        echo "  ✓ Linked node: $node_name"
                    fi
                fi
            done
        fi
    else
        echo "worker-comfyui: No ComfyUI structure found in volume"
    fi
    
    # Instalar dependências dos custom nodes se configurado
    if [ "$INSTALL_CUSTOM_NODE_DEPS" = "true" ]; then
        echo "worker-comfyui: Installing custom node dependencies..."
        for req in /comfyui/custom_nodes/*/requirements.txt; do
            if [ -f "$req" ]; then
                node_name=$(basename $(dirname "$req"))
                echo "  Installing deps for: $node_name"
                pip install -q -r "$req" 2>/dev/null || echo "  ⚠ Failed to install some deps for $node_name"
            fi
        done
    fi
    
    echo "worker-comfyui: Symbolic links setup completed!"
else
    echo "worker-comfyui: No RunPod volume detected at /runpod-volume"
fi

# ==============================================================================
# CÓDIGO ORIGINAL DO START.SH
# ==============================================================================

# Use libtcmalloc for better memory management
TCMALLOC="$(ldconfig -p | grep -Po "libtcmalloc.so.\d" | head -n 1)"
export LD_PRELOAD="${TCMALLOC}"

# Ensure ComfyUI-Manager runs in offline network mode inside the container
comfy-manager-set-mode offline || echo "worker-comfyui - Could not set ComfyUI-Manager network_mode" >&2

echo "worker-comfyui: Starting ComfyUI"

# Allow operators to tweak verbosity; default is DEBUG.
: "${COMFY_LOG_LEVEL:=DEBUG}"

# Serve the API and don't shutdown the container
if [ "$SERVE_API_LOCALLY" == "true" ]; then
    python -u /comfyui/main.py --disable-auto-launch --disable-metadata --listen --verbose "${COMFY_LOG_LEVEL}" --log-stdout &

    echo "worker-comfyui: Starting RunPod Handler"
    python -u /handler.py --rp_serve_api --rp_api_host=0.0.0.0
else
    python -u /comfyui/main.py --disable-auto-launch --disable-metadata --verbose "${COMFY_LOG_LEVEL}" --log-stdout &

    echo "worker-comfyui: Starting RunPod Handler"
    python -u /handler.py
fi