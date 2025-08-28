DOCKER_USERNAME="shedyhs"
IMAGE_NAME="worker-comfyui-custom"
VERSION="1.0.0"

# Cores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}📤 Fazendo push para Docker Hub...${NC}"

# Login no Docker Hub
echo -e "${YELLOW}Fazendo login no Docker Hub...${NC}"
docker login

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Falha no login!${NC}"
    exit 1
fi

# Push da versão específica
echo -e "${YELLOW}Push: ${DOCKER_USERNAME}/${IMAGE_NAME}:${VERSION}${NC}"
docker push ${DOCKER_USERNAME}/${IMAGE_NAME}:${VERSION}

# Push da tag latest
echo -e "${YELLOW}Push: ${DOCKER_USERNAME}/${IMAGE_NAME}:latest${NC}"
docker push ${DOCKER_USERNAME}/${IMAGE_NAME}:latest

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Push concluído com sucesso!${NC}"
    echo ""
    echo -e "${GREEN}Imagem disponível em:${NC}"
    echo "  https://hub.docker.com/r/${DOCKER_USERNAME}/${IMAGE_NAME}"
    echo ""
    echo -e "${YELLOW}Use no RunPod:${NC}"
    echo "  ${DOCKER_USERNAME}/${IMAGE_NAME}:${VERSION}"
else
    echo -e "${RED}❌ Push falhou!${NC}"
    exit 1
fi