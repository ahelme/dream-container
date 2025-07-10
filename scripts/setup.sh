#!/bin/bash
# scripts/setup.sh - One-command setup for DREAM CONTAINER
# 💭 Run this script to make your development dreams come true!
#
# Usage:
#   ./scripts/setup.sh           # Smart caching (recommended)
#   ./scripts/setup.sh --fresh   # Force clean build
#   ./scripts/setup.sh --no-cache # Same as --fresh

set -e

# Colors for beautiful dream output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Dream emojis for magical output
DREAM="💭"
CHECK="✅"
WARNING="⚠️"
FIRE="🔥"
SPARKLES="✨"
ROCKET="🚀"
STAR="⭐"

echo -e "${BLUE}${DREAM} DREAM CONTAINER Setup${NC}"
echo -e "${BLUE}========================${NC}"
echo -e "${PURPLE}Making your development dreams come true...${NC}"
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
    "dev": "echo '🚀 Add your development command here'",
    "build": "echo '🏗️ Add your build command here'",
    "test": "echo '🧪 Add your test command here'",
    "quality": "echo '✨ Add quality checks here'",
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
    echo -e "${YELLOW}💡 Tip: Try running with --fresh flag for a clean build: ./scripts/setup.sh --fresh${NC}"
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

# Final dream success message
echo ""
echo -e "${GREEN}${FIRE}${FIRE}${FIRE} DREAMS ACHIEVED! ${FIRE}${FIRE}${FIRE}${NC}"
echo -e "${GREEN}Your Dream Container development environment is ready!${NC}"
echo ""

echo -e "${CYAN}💭 Your Next Dream Steps:${NC}"
echo -e "  1. ${YELLOW}Open VS Code:${NC} code ."
echo -e "  2. ${YELLOW}Reopen in Container${NC} when prompted (let the dreams begin!)"
echo -e "  3. ${YELLOW}Authenticate with GitHub:${NC} run 'gh auth login' in terminal"
echo -e "  4. ${YELLOW}Set up Git authentication:${NC} your git push will work like a dream!"
echo -e "  5. ${YELLOW}Start Claude Code:${NC} run 'claude login' for AI-powered dream development"
echo ""

echo -e "${CYAN}🌐 Your Dream Service URLs:${NC}"
echo -e "  • ${BLUE}Database:${NC} localhost:5432 (for data dreams)"
echo -e "  • ${BLUE}Redis:${NC} localhost:6379 (for caching dreams)"  
echo -e "  • ${BLUE}API:${NC} localhost:8000 (when you build your API dreams)"
echo -e "  • ${BLUE}Frontend:${NC} localhost:3000 (when you build your UI dreams)"
echo ""

echo -e "${CYAN}🔧 Useful Dream Commands:${NC}"
echo -e "  • ${YELLOW}Enter container:${NC} docker-compose exec devcontainer zsh"
echo -e "  • ${YELLOW}View logs:${NC} docker-compose logs -f"
echo -e "  • ${YELLOW}Stop everything:${NC} docker-compose down"
echo -e "  • ${YELLOW}Rebuild (cached):${NC} ./scripts/setup.sh"
echo -e "  • ${YELLOW}Rebuild (fresh):${NC} ./scripts/setup.sh --fresh"
echo -e "  • ${YELLOW}Health check:${NC} (run 'health' inside container)"
echo ""

echo -e "${PURPLE}${SPARKLES} Your development dreams are now reality! ${SPARKLES}${NC}"
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
echo -e "${GREEN}${STAR} Thank you for choosing Dream Container! ${STAR}${NC}"
echo -e "${GREEN}Star us on GitHub if your development dreams came true! ${STAR}${NC}"
echo ""