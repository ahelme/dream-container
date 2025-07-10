#!/bin/bash
# .devcontainer/post-create.sh
# 💭 Post-creation setup inside your Dream Container

set -e

# Dream colors and emojis
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
PURPLE='\033[0;35m'
NC='\033[0m'
DREAM="💭"
CHECK="✅"
SPARKLES="✨"
ROBOT="🤖"

echo -e "${BLUE}${DREAM} Setting up your Dream Container environment...${NC}"
echo -e "${PURPLE}Making development dreams come true from the inside...${NC}"
echo ""

# Helper functions for dream output
print_step() {
    echo -e "${BLUE}${DREAM} ${1}${NC}"
}

print_success() {
    echo -e "${GREEN}${CHECK} ${1}${NC}"
}

print_magic() {
    echo -e "${PURPLE}${SPARKLES} ${1}${NC}"
}

# Set up shell for dream development
print_step "Configuring shell environment for your dreams..."
if [ -f /etc/passwd ]; then
    sudo chsh -s $(which zsh) vscode 2>/dev/null || true
fi
print_success "Shell configured for dream development"

# Verify SSH and Git setup for version control dreams
print_step "Verifying SSH and Git configuration for your version control dreams..."
if [ -d "$HOME/.ssh" ]; then
    print_success "SSH keys mounted successfully (read-only for dream security)"
    if [ -r "$HOME/.ssh/id_rsa" ] || [ -r "$HOME/.ssh/id_ed25519" ] || ls $HOME/.ssh/*.pub &> /dev/null; then
        print_success "SSH keys detected - ready for secure dream pushes"
    else
        echo -e "${YELLOW}⚠️  No SSH keys found. You can still use HTTPS authentication for your dreams.${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  SSH directory not mounted. HTTPS authentication will be used for your dreams.${NC}"
fi

if [ -f "$HOME/.gitconfig" ]; then
    print_success "Git configuration mounted for version control dreams"
    echo -e "   Dream Developer: $(git config user.name) <$(git config user.email)>"
else
    echo -e "${YELLOW}⚠️  Git configuration not found. Please set up git config for your dreams.${NC}"
fi

# Install project dependencies for coding dreams
print_step "Installing project dependencies for your coding dreams..."
cd /workspace

# Python dependencies for backend dreams
if [ -f "requirements.txt" ]; then
    print_step "Installing Python packages for your backend dreams..."
    pip install --user -r requirements.txt
    print_success "Python packages installed - backend dreams ready!"
fi

if [ -f "requirements-dev.txt" ]; then
    print_step "Installing Python dev packages for enhanced dreams..."
    pip install --user -r requirements-dev.txt
    print_success "Python dev packages installed - development dreams enhanced!"
fi

# Node.js dependencies for web dreams
if [ -f "package.json" ]; then
    print_step "Installing Node.js packages for your web dreams..."
    # Remove any existing node_modules to ensure clean dream installation
    rm -rf node_modules
    npm install
    print_success "Node.js packages installed - web dreams ready!"
fi

# Set up authentication guides for dream workflows
print_step "Setting up authentication guides for dream workflows..."

# Check Claude Code for AI dreams
if command -v claude &> /dev/null; then
    if claude --version &>/dev/null 2>&1; then
        print_magic "Claude Code is authenticated and ready for AI-powered dreams!"
    else
        echo -e "${YELLOW}${ROBOT} Claude Code needs authentication for AI dreams. Run: ${NC}claude login"
    fi
else
    echo -e "${YELLOW}⚠️  Claude Code not found. Your AI dreams may need manual installation.${NC}"
fi

# Check GitHub CLI for git dreams
if command -v gh &> /dev/null; then
    if gh auth status &>/dev/null 2>&1; then
        print_success "GitHub CLI is authenticated - git dreams ready!"
    else
        echo -e "${YELLOW}${ROBOT} GitHub CLI needs authentication for git dreams. Run: ${NC}gh auth login"
    fi
else
    echo -e "${YELLOW}⚠️  GitHub CLI not found. Installing for your git dreams...${NC}"
    # GitHub CLI should be installed via Dockerfile, but just in case
    sudo apt-get update && sudo apt-get install -y gh
fi

# Wait for services to be ready for multi-service dreams
print_step "Checking service connectivity for your multi-service dreams..."

# Check database for data dreams
if command -v pg_isready &> /dev/null; then
    if pg_isready -h db -U ${DB_USER:-dream_user} -d ${DB_NAME:-dream_db} &> /dev/null; then
        print_success "Database connection ready for your data dreams"
    else
        echo -e "${YELLOW}⚠️  Database not ready yet for data dreams. Try: ${NC}pg_isready -h db -U dream_user"
    fi
fi

# Check Redis for caching dreams
if command -v redis-cli &> /dev/null; then
    if redis-cli -h redis ping &> /dev/null; then
        print_success "Redis connection ready for your caching dreams"
    else
        echo -e "${YELLOW}⚠️  Redis not ready yet for caching dreams. Try: ${NC}redis-cli -h redis ping"
    fi
fi

# Create helpful aliases and functions for dream development
print_step "Setting up development shortcuts for your dreams..."

# Add to both .bashrc and .zshrc for compatibility
for rc in .bashrc .zshrc; do
    if [ -f "$HOME/$rc" ]; then
        # Remove existing aliases to avoid duplicates
        sed -i '/# Dream Container Aliases/,/# End Dream Container Aliases/d' "$HOME/$rc"
        
        cat >> "$HOME/$rc" << 'EOF'

# Dream Container Aliases - Making development dreams come true
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

# Project shortcuts for your dreams
alias api='curl -s http://api:8000'
alias db='psql -h db -U ${DB_USER:-dream_user} -d ${DB_NAME:-dream_db}'
alias redis='redis-cli -h redis'

# Docker shortcuts for container dreams
alias logs='docker-compose logs -f'
alias restart='docker-compose restart'

# Development shortcuts for coding dreams
alias dev='echo "💭 Add your dev command to package.json scripts"'
alias test='echo "🧪 Add your test command to package.json scripts"' 
alias quality='echo "✨ Add your quality command to package.json scripts"'

# Git shortcuts for version control dreams (with enhanced authentication)
alias gst='git status'
alias gco='git checkout'
alias gcm='git commit -m'
alias gp='git push origin'
alias gl='git pull origin'

# Claude Code shortcuts for AI dreams
alias ai='claude'
alias dream='claude'
alias askgpt='claude'

# Dream-specific shortcuts
alias wake='echo "💭 Good morning, dreamer! Ready to build something amazing?"'
alias sleep='echo "💭 Sweet dreams! Your code will be here when you wake up."'

# Quick service health checks for dream maintenance
health() {
    echo "💭 Checking your Dream Container health..."
    echo -n "Database: "
    pg_isready -h db -U ${DB_USER:-dream_user} && echo "✅ Dreams flowing" || echo "❌ Dreams blocked"
    echo -n "Redis: "
    redis-cli -h redis ping > /dev/null && echo "✅ Dreams cached" || echo "❌ Dreams uncached"
    echo -n "GitHub CLI: "
    gh auth status > /dev/null 2>&1 && echo "✅ Dreams connected" || echo "❌ Dreams disconnected (run: gh auth login)"
    echo -n "Claude Code: "
    claude --version > /dev/null 2>&1 && echo "✅ Dreams enhanced" || echo "❌ Dreams basic (run: claude login)"
}

# Quick setup reminders for new dreamers
setup() {
    echo "💭 Dream Container Setup Reminders:"
    echo ""
    echo "🔐 Authentication Dreams:"
    echo "  • GitHub CLI: gh auth login"
    echo "  • Claude Code: claude login"
    echo "  • Git: Should work automatically with token magic"
    echo ""
    echo "🧪 Test Your Dreams:"
    echo "  • Run: health"
    echo "  • Test git: git push origin"
    echo "  • Test AI: claude 'Hello from my dreams!'"
    echo ""
    echo "📚 Learn About Your Dreams:"
    echo "  • Documentation: cat README.md"
    echo "  • Examples: ls examples/"
    echo "  • Dream more: echo 'The sky is the limit!'"
}

# Welcome message for new dreamers
welcome() {
    echo "💭 Welcome to Dream Container!"
    echo "   Where development dreams come true..."
    echo ""
    echo "🚀 Quick commands to get started:"
    echo "  • setup  - Show setup reminders"
    echo "  • health - Check all services"
    echo "  • dream  - Talk to Claude AI"
    echo "  • wake   - Morning motivation"
    echo ""
    echo "Happy dreaming! ✨"
}

# End Dream Container Aliases
EOF
        print_success "Dream aliases added to $rc"
    fi
done

# Source the updated shell config
source ~/.zshrc 2>/dev/null || source ~/.bashrc 2>/dev/null || true

# Final dream setup message
echo ""
echo -e "${GREEN}${SPARKLES}${SPARKLES}${SPARKLES} Dream Container Setup Complete! ${SPARKLES}${SPARKLES}${SPARKLES}${NC}"
echo ""
echo -e "${BLUE}💭 Your Next Dream Steps:${NC}"
echo -e "  1. ${YELLOW}Authenticate GitHub CLI:${NC} gh auth login"
echo -e "  2. ${YELLOW}Authenticate Claude Code:${NC} claude login"  
echo -e "  3. ${YELLOW}Test your dream setup:${NC} health"
echo -e "  4. ${YELLOW}Start coding your dreams:${NC} Your environment is ready!"
echo ""
echo -e "${BLUE}🌟 Dream Pro Tips:${NC}"
echo -e "  • Run ${YELLOW}setup${NC} anytime for quick reminders"
echo -e "  • Run ${YELLOW}health${NC} to check all your dream services"
echo -e "  • Run ${YELLOW}welcome${NC} to see the welcome message again"
echo -e "  • Your authentication persists across rebuilds like magic!"
echo ""
echo -e "${PURPLE}💭 Welcome to Dream Container - where coding dreams come true! 🌟${NC}"