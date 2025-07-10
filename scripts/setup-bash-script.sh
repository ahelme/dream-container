#!/bin/bash
# scripts/setup-bash.sh - Dream Container Setup for Bash Users
# 💭 Run this script to make your development dreams come true!
#
# Usage:
#   ./scripts/setup-bash.sh           # Smart caching (recommended)
#   ./scripts/setup-bash.sh --fresh   # Force clean build
#   ./scripts/setup-bash.sh --no-cache # Same as --fresh

set -e

# Colors for beautiful dream output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Dream emojis for magical output
DREAM="💭"
CHECK="✅"
WARNING="⚠️"
FIRE="🔥"
SPARKLES="✨"
ROCKET="🚀"
STAR="⭐"
BRIEFCASE="💼"
SHELL_ICON="🐚"

echo -e "${BLUE}${DREAM} DREAM CONTAINER Setup (Bash)${NC}"
echo -e "${BLUE}===============================${NC}"
echo -e "${PURPLE}Making your development dreams come true...${NC}"
echo -e "${CYAN}${SHELL_ICON} Optimized for Bash users${NC}"
echo ""

# Function to print colored dream output
print_step() {
    echo -e "${CYAN}${DREAM} ${1}${NC}"
}

print_success() {
    echo -e "${GREEN}${CHECK} ${1}${NC}"
}

print_warning() {
    echo -e "${YELLOW}${WARNING} ${1}${NC}"
}

print_error() {
    echo -e "${RED}❌ ${1}${NC}"
}

print_magic() {
    echo -e "${PURPLE}${SPARKLES} ${1}${NC}"
}

print_severance() {
    echo -e "${WHITE}${BRIEFCASE} ${1}${NC}"
}

# Check if Docker is running for our dreams
print_step "Checking Docker installation for your dreams..."
if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed. Dreams need Docker to come true!"
    echo "  📖 Install Docker: https://docs.docker.com/get-docker/"
    exit 1
fi

if ! docker info &> /dev/null; then
    print_error "Docker is not running. Please start Docker to begin your dreams."
    exit 1
fi

print_success "Docker is ready for your dreams!"

# Check if Docker Compose is available for multi-service dreams
if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    print_error "Docker Compose is not available. Multi-service dreams need Docker Compose!"
    exit 1
fi

print_success "Docker Compose is ready for orchestrating your dreams!"

# Create .env file for dream configuration
print_step "Setting up dream configuration..."
if [ ! -f ".env" ]; then
    if [ -f ".env.example" ]; then
        cp .env.example .env
        print_success "Created .env file from dream template"
        print_warning "Please edit .env file to customize your specific dreams"
    else
        print_warning ".env.example not found, creating basic dream configuration"
        cat > .env << 'EOF'
PROJECT_NAME=my-dream-project
DB_NAME=dream_db
DB_USER=dream_user
DB_PASSWORD=secure_dream_2025
DB_PORT=5432
REDIS_PORT=6379
API_PORT=8000
FRONTEND_PORT=3000
EOF
        print_success "Created basic .env file for your dreams"
    fi
else
    print_success ".env file already exists - dreams are configured!"
fi

# Create necessary directories for organized dreams
print_step "Creating dream project structure..."
mkdir -p backend frontend docs tests scripts examples
mkdir -p .github/workflows .github/ISSUE_TEMPLATE
print_success "Dream project directories created"

# Create basic requirements.txt for Python dreams
if [ ! -f "requirements.txt" ]; then
    print_step "Creating Python requirements for backend dreams..."
    cat > requirements.txt << 'EOF'
# 🐍 Python dependencies for your dreams (future-proof versions)
fastapi>=0.104.0,<1.0.0
uvicorn[standard]>=0.24.0,<1.0.0
pydantic>=2.5.0,<3.0.0
python-multipart>=0.0.6
requests>=2.31.0,<3.0.0

# 🗄️ Database for data dreams (stable versions)
psycopg2-binary>=2.9.7,<3.0.0
redis>=5.0.0,<6.0.0

# 🔧 Development tools for coding dreams (flexible versions)
python-dotenv>=1.0.0
pytest>=7.4.0
black>=23.0.0
isort>=5.12.0
EOF
    print_success "Created requirements.txt for Python dreams"
else
    print_success "requirements.txt already exists - Python dreams configured!"
fi

# Create basic package.json for web dreams
if [ ! -f "package.json" ]; then
    print_step "Creating Node.js package.json for web dreams..."
    cat > package.json << 'EOF'
{
  "name": "dream-container-project",
  "version": "1.0.0",
  "description": "A project built with Dream Container - where development dreams come true",
  "scripts": {
    "dev": "echo '🚀 Start your development environment with: docker-compose up'",
    "build": "echo '🏗️ Build services with: docker-compose build'",
    "test": "echo '🧪 Add your test command here'",
    "quality": "echo '✨ Add quality checks here (e.g., linting and formatting)'",
    "dream": "echo '💭 Living the development dream!'"
  },
  "keywords": ["dream-container", "devcontainer", "development"],
  "devDependencies": {
    "prettier": "^3.0.0",
    "eslint": "^8.50.0"
  }
}
EOF
    print_success "Created package.json for web dreams"
else
    print_success "package.json already exists - web dreams configured!"
fi

# Build the dream container (smart caching for speed)
print_step "Building your Dream Container (leveraging cache for lightning speed)..."
echo -e "${YELLOW}${SPARKLES} Downloading images and building your development dreams...${NC}"

# Check if this is a fresh build or rebuild
if [ "$1" = "--fresh" ] || [ "$1" = "--no-cache" ]; then
    echo -e "${PURPLE}🔄 Fresh build requested - ignoring cache for pristine dreams...${NC}"
    BUILD_CMD="docker-compose build --no-cache devcontainer"
else
    echo -e "${PURPLE}⚡ Using intelligent caching for speedy dream construction...${NC}"
    BUILD_CMD="docker-compose build devcontainer"
fi

if $BUILD_CMD; then
    print_magic "Dream Container built successfully! Your dreams are taking shape!"
else
    print_error "Failed to build Dream Container. Check the output above for troubleshooting."
    echo -e "${YELLOW}💡 Tip: Try running with --fresh flag for a clean build: ./scripts/setup-bash.sh --fresh${NC}"
    exit 1
fi

# Start dream services
print_step "Starting your dream services..."
if docker-compose up -d db redis; then
    print_success "Database and Redis started - your data dreams are alive!"
else
    print_error "Failed to start dream services"
    exit 1
fi

# Wait for database to be ready for data dreams
print_step "Waiting for database to be ready for your data dreams..."
timeout=30
counter=0
while ! docker-compose exec -T db pg_isready -U dream_user -d dream_db &> /dev/null; do
    sleep 1
    counter=$((counter + 1))
    if [ $counter -ge $timeout ]; then
        print_error "Database did not start within $timeout seconds - dreams delayed"
        exit 1
    fi
done
print_success "Database is ready for your data dreams!"

# Start the dream container
print_step "Starting your Dream Container..."
if docker-compose up -d devcontainer; then
    print_magic "Dream Container is running! Your development dreams are live!"
else
    print_error "Failed to start Dream Container"
    exit 1
fi

# Wait a moment for container to fully initialize
sleep 3

# ==========================================
# 🎯 BASH-SPECIFIC CONVENIENCE OPTIONS
# ==========================================

echo ""
echo -e "${WHITE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${WHITE}${BRIEFCASE} CONVENIENCE AUTHENTICATION PROTOCOL${NC}"
echo -e "${WHITE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
print_severance "For your convenience, we can configure authentication services now."
print_severance "This will streamline your Bash development workflow and eliminate future"
print_severance "authentication interruptions."
echo ""

# Initialize convenience tracking variables
github_authenticated=false
claude_authenticated=false

# GitHub Authentication Option
echo -e "${CYAN}🔐 GITHUB AUTHENTICATION SETUP${NC}"
echo -e "${CYAN}──────────────────────────────────${NC}"
echo ""
read -p "$(echo -e ${YELLOW}Would you like to authenticate with GitHub now? [y/N]: ${NC})" setup_github

if [[ $setup_github =~ ^[Yy]$ ]]; then
    echo ""
    print_magic "Initiating GitHub authentication protocol..."
    echo ""
    echo -e "${PURPLE}📋 This will:${NC}"
    echo -e "   • Open your browser for secure authentication"
    echo -e "   • Store persistent credentials in the container"
    echo -e "   • Enable seamless git operations"
    echo ""
    
    # Run gh auth login inside the container
    print_step "Executing authentication in Dream Container..."
    
    if docker-compose exec devcontainer zsh -c "
        echo '🤖 GitHub CLI Authentication Process'
        echo '=================================='
        echo ''
        echo 'Please follow the authentication flow in your browser.'
        echo 'Your credentials will be stored securely for future use.'
        echo ''
        
        # Clear any existing GITHUB_TOKEN that might interfere
        unset GITHUB_TOKEN
        
        # Run the authentication
        gh auth login --web
        
        echo ''
        echo '✅ GitHub authentication complete!'
        echo 'Testing authentication...'
        gh auth status
    "; then
        echo ""
        print_success "GitHub authentication successful!"
        echo -e "   ${GREEN}Your git operations will now work seamlessly.${NC}"
        github_authenticated=true
    else
        echo ""
        print_warning "GitHub authentication encountered an issue."
        echo -e "   ${YELLOW}You can authenticate later with: docker-compose exec devcontainer gh auth login${NC}"
        github_authenticated=false
    fi
else
    echo ""
    print_step "Skipping GitHub authentication."
    echo -e "   ${CYAN}You can authenticate later with: docker-compose exec devcontainer gh auth login${NC}"
    github_authenticated=false
fi

echo ""
echo -e "${WHITE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# Claude Code Authentication Option
echo -e "${CYAN}🤖 CLAUDE CODE SETUP${NC}"
echo -e "${CYAN}─────────────────────${NC}"
echo ""
read -p "$(echo -e ${YELLOW}Would you like to set up Claude Code AI assistance now? [y/N]: ${NC})" setup_claude

if [[ $setup_claude =~ ^[Yy]$ ]]; then
    echo ""
    print_magic "Initiating Claude Code setup protocol..."
    echo ""
    echo -e "${PURPLE}📋 This will:${NC}"
    echo -e "   • Authenticate with your Anthropic account"
    echo -e "   • Verify your Claude subscription"
    echo -e "   • Enable AI-powered development assistance"
    echo -e "   • Configure MCP tools for automation"
    echo ""
    
    # Run claude login inside the container
    print_step "Executing Claude Code setup in Dream Container..."
    
    if docker-compose exec devcontainer zsh -c "
        echo '🤖 Claude Code Authentication Process'
        echo '==================================='
        echo ''
        echo 'Please follow the authentication flow in your browser.'
        echo 'Make sure you have an active Claude subscription.'
        echo ''
        
        # Check if claude command exists
        if command -v claude &> /dev/null; then
            claude login
            
            echo ''
            echo '✅ Claude Code authentication complete!'
            echo 'Testing Claude Code...'
            claude --version
            
            echo ''
            echo '🎯 Quick Claude Code test:'
            claude 'Hello! I am now running in the Dream Container. Please respond with a brief confirmation that you can see this message and that we are ready for AI-powered development!'
        else
            echo '❌ Claude Code not found. Please check the container setup.'
            exit 1
        fi
    "; then
        echo ""
        print_success "Claude Code setup successful!"
        echo -e "   ${GREEN}AI assistance is now available in your development environment.${NC}"
        claude_authenticated=true
    else
        echo ""
        print_warning "Claude Code setup encountered an issue."
        echo -e "   ${YELLOW}You can set up Claude Code later with: docker-compose exec devcontainer claude login${NC}"
        claude_authenticated=false
    fi
else
    echo ""
    print_step "Skipping Claude Code setup."
    echo -e "   ${CYAN}You can set up Claude Code later with: docker-compose exec devcontainer claude login${NC}"
    claude_authenticated=false
fi

echo ""
echo -e "${WHITE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# ==========================================
# 🎉 BASH-SPECIFIC COMPLETION & NEXT STEPS
# ==========================================

echo ""
echo -e "${GREEN}${FIRE}${FIRE}${FIRE} DREAMS ACHIEVED! ${FIRE}${FIRE}${FIRE}${NC}"
echo -e "${GREEN}Your Dream Container environment is ready for Bash!${NC}"
echo ""

# Enhanced Authentication Status Summary
echo -e "${CYAN}📊 Authentication Status:${NC}"
if [ "$github_authenticated" = true ]; then
    echo -e "   ${CHECK} ${GREEN}GitHub: Authenticated and ready${NC}"
else
    echo -e "   ⏸️  ${YELLOW}GitHub: Not configured (can be set up later)${NC}"
fi

if [ "$claude_authenticated" = true ]; then
    echo -e "   ${CHECK} ${GREEN}Claude Code: Authenticated and ready${NC}"
else
    echo -e "   ⏸️  ${YELLOW}Claude Code: Not configured (can be set up later)${NC}"
fi

echo ""
echo -e "${CYAN}🌐 Your Dream Service URLs:${NC}"
echo -e "  • ${BLUE}Frontend:${NC} http://localhost:3000 (for your UI dreams)"
echo -e "  • ${BLUE}API:${NC} http://localhost:8000 (for your backend dreams)" 
echo -e "  • ${BLUE}Database:${NC} localhost:5433 (for data dreams)"
echo -e "  • ${BLUE}Cache:${NC} localhost:6380 (for caching dreams)"
echo ""

echo -e "${CYAN}🔧 Useful Dream Commands:${NC}"
echo -e "  • ${YELLOW}Enter container:${NC} docker-compose exec devcontainer zsh"
echo -e "  • ${YELLOW}View logs:${NC} docker-compose logs -f"
echo -e "  • ${YELLOW}Stop everything:${NC} docker-compose down"
echo -e "  • ${YELLOW}Rebuild (cached):${NC} ./scripts/setup-bash.sh"
echo -e "  • ${YELLOW}Rebuild (fresh):${NC} ./scripts/setup-bash.sh --fresh"
echo -e "  • ${YELLOW}Health check:${NC} docker-compose ps"
echo ""

# Conditional next steps based on what was configured
echo -e "${CYAN}💡 Getting Started with Bash:${NC}"
echo -e "   1. ${YELLOW}Enter your Dream Container:${NC} docker-compose exec devcontainer zsh"

if [ "$claude_authenticated" = true ]; then
    echo -e "   2. ${YELLOW}Ask Claude for help:${NC} claude 'Help me get started with this project'"
    echo -e "   3. ${YELLOW}Start building your dreams!${NC}"
elif [ "$github_authenticated" = true ]; then
    echo -e "   2. ${YELLOW}Create your first commit:${NC} git add . && git commit -m 'Initial dream commit'"
    echo -e "   3. ${YELLOW}Start building your dreams!${NC}"
else
    echo -e "   2. ${YELLOW}Explore your development environment${NC}"
    echo -e "   3. ${YELLOW}Start building your dreams!${NC}"
fi

echo ""

# Show setup commands for anything not configured
if [ "$github_authenticated" = false ]; then
    echo -e "${CYAN}🔐 To set up GitHub authentication later:${NC}"
    echo -e "   ${YELLOW}docker-compose exec devcontainer gh auth login${NC}"
    echo -e "   ${CYAN}💡 Bash tip: Add to ~/.bashrc for persistent tokens:${NC}"
    echo -e "   ${YELLOW}echo 'export GITHUB_TOKEN=\"your_token\"' >> ~/.bashrc${NC}"
    echo -e "   ${YELLOW}source ~/.bashrc${NC}"
    echo ""
fi

if [ "$claude_authenticated" = false ]; then
    echo -e "${CYAN}🤖 To set up Claude Code later:${NC}"
    echo -e "   ${YELLOW}docker-compose exec devcontainer claude login${NC}"
    echo ""
fi

echo -e "${PURPLE}${SPARKLES} Your Bash development dreams are now reality! ${SPARKLES}${NC}"
echo -e "${PURPLE}Welcome to Dream Container - where coding dreams come true! ${DREAM}${NC}"
echo ""

# Check if VS Code is available for the ultimate dream experience
if command -v code &> /dev/null; then
    echo -e "${CYAN}🎯 Dream tip: Run 'code .' to open this project in VS Code!${NC}"
    echo -e "${CYAN}   Then select 'Reopen in Container' to enter your Dream Container!${NC}"
else
    echo -e "${YELLOW}💡 Install VS Code for the ultimate dream experience: https://code.visualstudio.com/${NC}"
fi

echo ""

# Final Severance-style message
echo -e "${WHITE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
print_severance "Thank you for choosing Dream Container convenience services."
print_severance "Your Bash environment has been optimized for maximum productivity."
echo -e "${WHITE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

echo ""
echo -e "${GREEN}${STAR} Star us on GitHub if your development dreams came true! ${STAR}${NC}"
echo ""