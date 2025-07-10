#!/bin/bash
# scripts/auth-github.sh
# 🔐 GitHub Authentication Helper for Dream Container

set -e

# Colors for beautiful output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}🔐 Dream Container - GitHub Authentication${NC}"
echo -e "${BLUE}==========================================${NC}"
echo ""

# Check if we're inside the container or outside
if [ -f "/.dockerenv" ]; then
    echo -e "${GREEN}✅ Running inside Dream Container${NC}"
    echo ""
    
    # We're inside the container
    echo -e "${YELLOW}🚀 Starting GitHub authentication...${NC}"
    echo ""
    echo "This will open your browser for secure authentication."
    echo "Your credentials will be stored persistently in the container."
    echo ""
    
    # Clear any existing GITHUB_TOKEN that might interfere
    unset GITHUB_TOKEN
    
    # Run authentication
    echo -e "${BLUE}Please follow the authentication flow in your browser...${NC}"
    gh auth login --web
    
    echo ""
    echo -e "${GREEN}✅ Testing GitHub authentication...${NC}"
    gh auth status
    
    echo ""
    echo -e "${GREEN}🎉 GitHub authentication complete!${NC}"
    echo "Your git operations will now work seamlessly."
    
else
    echo -e "${YELLOW}📋 Running from host - entering Dream Container...${NC}"
    echo ""
    
    # We're on the host, need to enter container
    if ! docker-compose ps devcontainer | grep -q "Up"; then
        echo -e "${RED}❌ Dream Container is not running!${NC}"
        echo "Please start it first with: docker-compose up -d devcontainer"
        exit 1
    fi
    
    echo -e "${BLUE}🔗 Executing authentication inside Dream Container...${NC}"
    docker-compose exec devcontainer zsh -c "
        echo '🔐 GitHub Authentication Process'
        echo '==============================='
        echo ''
        
        # Clear any existing GITHUB_TOKEN that might interfere
        unset GITHUB_TOKEN
        
        echo 'Opening browser for authentication...'
        gh auth login --web
        
        echo ''
        echo '✅ Testing authentication...'
        gh auth status
        
        echo ''
        echo '🎉 GitHub authentication complete!'
        echo 'Your git operations will now work seamlessly.'
    "
fi

echo ""
echo -e "${GREEN}🎯 You can now use git commands seamlessly:${NC}"
echo "  • git clone, git push, git pull"
echo "  • gh commands for GitHub operations"
echo "  • Authentication persists across container rebuilds"
echo ""
echo -e "${BLUE}💡 Pro tip: Your authentication is stored in the dream_gh_config volume${NC}"
echo "   It will survive container rebuilds and restarts!"