#!/bin/bash
# build.sh - Script para build da imagem Docker

# Configurações
DOCKER_USERNAME="shedyhs"  # Altere para seu username do Docker Hub
IMAGE_NAME="worker-comfyui-runpod"
VERSION="1.0.0"
PLATFORM="linux/amd64"  # Para RunPod, sempre use AMD64

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}🔨 Iniciando build da imagem Docker...${NC}"

# Build da imagem
echo -e "${YELLOW}Building: ${DOCKER_USERNAME}/${IMAGE_NAME}:${VERSION}${NC}"
docker build \
  --platform ${PLATFORM} \
  -t ${DOCKER_USERNAME}/${IMAGE_NAME}:${VERSION} \
  -t ${DOCKER_USERNAME}/${IMAGE_NAME}:latest \
  --target base \
  .

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Build concluído com sucesso!${NC}"
    
    # Mostrar tamanho da imagem
    echo -e "${YELLOW}📦 Tamanho da imagem:${NC}"
    docker images ${DOCKER_USERNAME}/${IMAGE_NAME}:${VERSION}
    
    echo -e "\n${YELLOW}Próximos passos:${NC}"
    echo "1. Teste localmente: ./test-local.sh"
    echo "2. Push para Docker Hub: ./push.sh"
else
    echo -e "${RED}❌ Build falhou!${NC}"
    exit 1
fi
