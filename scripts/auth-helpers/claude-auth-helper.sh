#!/bin/bash
# scripts/auth-claude.sh  
# 🤖 Claude Code Authentication Helper for Dream Container

set -e

# Colors for beautiful output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
PURPLE='\033[0;35m'
NC='\033[0m'

echo -e "${PURPLE}🤖 Dream Container - Claude Code Authentication${NC}"
echo -e "${PURPLE}===============================================${NC}"
echo ""

# Check if we're inside the container or outside
if [ -f "/.dockerenv" ]; then
    echo -e "${GREEN}✅ Running inside Dream Container${NC}"
    echo ""
    
    # We're inside the container
    echo -e "${YELLOW}🚀 Starting Claude Code authentication...${NC}"
    echo ""
    echo "This will open your browser for secure authentication."
    echo "Make sure you have an active Claude subscription."
    echo "Your credentials will be stored persistently in the container."
    echo ""
    
    # Check if claude command exists
    if ! command -v claude &> /dev/null; then
        echo -e "${RED}❌ Claude Code not found in container!${NC}"
        echo "Please check that the container was built correctly."
        exit 1
    fi
    
    # Run authentication
    echo -e "${BLUE}Please follow the authentication flow in your browser...${NC}"
    claude login
    
    echo ""
    echo -e "${GREEN}✅ Testing Claude Code...${NC}"
    claude --version
    
    echo ""
    echo -e "${BLUE}🎯 Quick functionality test:${NC}"
    claude "Hello! I am now running in the Dream Container. Please respond with a brief confirmation that you can see this message and that we are ready for AI-powered development!"
    
    echo ""
    echo -e "${GREEN}🎉 Claude Code authentication complete!${NC}"
    echo "AI assistance is now available in your development environment."
    
else
    echo -e "${YELLOW}📋 Running from host - entering Dream Container...${NC}"
    echo ""
    
    # We're on the host, need to enter container
    if ! docker-compose ps devcontainer | grep -q "Up"; then
        echo -e "${RED}❌ Dream Container is not running!${NC}"
        echo "Please start it first with: docker-compose up -d devcontainer"
        exit 1
    fi
    
    echo -e "${BLUE}🔗 Executing Claude Code setup inside Dream Container...${NC}"
    docker-compose exec devcontainer zsh -c "
        echo '🤖 Claude Code Authentication Process'
        echo '===================================='
        echo ''
        
        # Check if claude command exists
        if ! command -v claude &> /dev/null; then
            echo '❌ Claude Code not found in container!'
            echo 'Please check that the container was built correctly.'
            exit 1
        fi
        
        echo 'Opening browser for authentication...'
        echo 'Make sure you have an active Claude subscription.'
        echo ''
        
        claude login
        
        echo ''
        echo '✅ Testing Claude Code...'
        claude --version
        
        echo ''
        echo '🎯 Quick functionality test:'
        claude 'Hello! I am now running in the Dream Container. Please respond with a brief confirmation that you can see this message and that we are ready for AI-powered development!'
        
        echo ''
        echo '🎉 Claude Code authentication complete!'
        echo 'AI assistance is now available in your development environment.'
    "
fi

echo ""
echo -e "${GREEN}🎯 You can now use Claude Code for AI assistance:${NC}"
echo "  • claude 'your question or request'"
echo "  • AI-powered code generation and debugging"
echo "  • MCP tools for web automation and testing"
echo "  • Authentication persists across container rebuilds"
echo ""
echo -e "${BLUE}💡 Pro tip: Your Claude authentication is stored in the dream_claude_config volume${NC}"
echo "   It will survive container rebuilds and restarts!"
echo ""
echo -e "${PURPLE}🔧 Available MCP Tools:${NC}"
echo "  • Puppeteer: Web automation and screenshots"
echo "  • Browser Tools: Console monitoring and debugging"
echo "  • Playwright: Advanced browser testing"