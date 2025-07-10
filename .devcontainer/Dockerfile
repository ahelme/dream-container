# .devcontainer/Dockerfile
# 💭 DREAM CONTAINER - The Development Environment of Your Dreams
# Multi-Platform Support: ARM64 (Apple Silicon) + AMD64 (Intel/AMD) + Claude Code + MCP Tools
# 
# 🎯 Versioning Strategy for Future-Proof Dreams:
# - Base images: Major version tags (get security updates automatically)
# - System packages: Latest stable from repos (most reliable)
# - Global npm packages: @latest (AI tools evolve quickly)
# - Python packages: Smart version ranges in requirements.txt
#
# Using future-proof base image with auto minor updates
FROM mcr.microsoft.com/devcontainers/python:1-3.12-bookworm

# 📦 Install system dependencies and browser support for your dreams
RUN echo "💭 Transcending bureaucracy and installing dream dependencies..." && \
    apt-get update && export DEBIAN_FRONTEND=noninteractive \
    && apt-get -y install --no-install-recommends \
    # Core utilities for dream development
    wget \
    gnupg \
    ca-certificates \
    curl \
    zsh \
    git \
    # Database clients for data dreams
    postgresql-client \
    redis-tools \
    # Development tools for coding dreams
    httpie \
    jq \
    # Node.js ecosystem for web dreams
    nodejs \
    npm \
    # Browser automation dependencies for testing dreams
    fonts-liberation \
    libasound2 \
    libatk-bridge2.0-0 \
    libatk1.0-0 \
    libatspi2.0-0 \
    libcups2 \
    libdbus-1-3 \
    libdrm2 \
    libgbm1 \
    libgtk-3-0 \
    libnspr4 \
    libnss3 \
    libwayland-client0 \
    libxcomposite1 \
    libxdamage1 \
    libxfixes3 \
    libxkbcommon0 \
    libxrandr2 \
    xdg-utils \
    libu2f-udev \
    libvulkan1 \
    --no-install-recommends \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/*

# 🐙 Install GitHub CLI for persistent authentication dreams
RUN echo "🐙 Manifesting persistent GitHub authentication magic..." && \
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
    && chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
    && apt-get update \
    && apt-get install gh -y \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/*

# 🌐 Install Google Chrome/Chromium (multi-platform dream support)
RUN echo "🌐 Summoning browsers from the multi-platform realm..." && \
    ARCH=$(dpkg --print-architecture) && \
    if [ "$ARCH" = "amd64" ]; then \
        mkdir -p /etc/apt/keyrings && \
        curl -fsSL https://dl.google.com/linux/linux_signing_key.pub | \
        gpg --dearmor -o /etc/apt/keyrings/google-chrome.gpg && \
        echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/google-chrome.gpg] http://dl.google.com/linux/chrome/deb/ stable main" > \
        /etc/apt/sources.list.d/google-chrome.list && \
        apt-get update && \
        apt-get install -y google-chrome-stable --no-install-recommends; \
    else \
        echo "Chrome not available for $ARCH, installing Chromium for dream compatibility" && \
        apt-get update && \
        apt-get install -y chromium --no-install-recommends; \
    fi && \
    apt-get clean -y && \
    rm -rf /var/lib/apt/lists/*

# 🎭 Configure browser automation tools for testing dreams
ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true \
    PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1

RUN ARCH=$(dpkg --print-architecture) && \
    if [ "$ARCH" = "amd64" ]; then \
        echo 'export PUPPETEER_EXECUTABLE_PATH=/usr/bin/google-chrome-stable' >> /etc/environment; \
    else \
        echo 'export PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium' >> /etc/environment; \
    fi

# 🤖 Install Claude Code and MCP tools for AI-powered dreams (using latest stable)
RUN echo "🤖 Awakening AI consciousness and installing dream enhancement tools..." && \
    npm install -g \
    @modelcontextprotocol/server-puppeteer@latest \
    @agentdeskai/browser-tools-server@latest \
    playwright@latest

# Install Claude Code with error handling for dream reliability (always latest)
RUN echo "✨ Channeling the power of Claude for AI-assisted dreams..." && \
    npm install -g @anthropic-ai/claude-code@latest || \
    (echo "🔄 Dream recovery sequence initiated..." && \
     npm cache clean --force && \
     npm install -g @anthropic-ai/claude-code@latest)

# 🔧 Create essential directories and set permissions for dream organization
RUN echo "🏗️ Architecting the sacred geometry of dream directories..." && \
    mkdir -p /home/vscode/.cache/puppeteer \
    && mkdir -p /home/vscode/.cache/ms-playwright \
    && mkdir -p /home/vscode/.claude \
    && mkdir -p /home/vscode/.config/gh \
    && chown -R vscode:vscode /home/vscode/.cache \
    && chown -R vscode:vscode /home/vscode/.claude \
    && chown -R vscode:vscode /home/vscode/.config

# 👤 Switch to vscode user for dream development
USER vscode

# 🐚 Configure shell environment for dream workflows
SHELL ["/bin/zsh", "-c"]
RUN echo "🐚 Crafting the perfect shell environment for dream experiences..." && \
    echo 'export PATH="/home/vscode/.local/bin:$PATH"' >> ~/.zshrc \
    && echo 'export PATH="/home/vscode/.npm-global/bin:$PATH"' >> ~/.zshrc \
    && echo '# Welcome to DREAM CONTAINER! 💭' >> ~/.zshrc \
    && echo 'echo "💭 Welcome to Dream Container! Transcending bureaucracy and making dreams come true..."' >> ~/.zshrc \
    && echo 'echo "✨ Ready to build something extraordinary? Your development dreams await!"' >> ~/.zshrc

# 📦 Install Python dependencies (layer caching optimization for faster dreams)
COPY --chown=vscode:vscode requirements*.txt /tmp/
RUN echo "🐍 Weaving Python magic into your development dreams..." && \
    pip install --user --no-cache-dir -r /tmp/requirements.txt && \
    (test -f /tmp/requirements-dev.txt && pip install --user --no-cache-dir -r /tmp/requirements-dev.txt || true)

# 📦 Install Node.js dependencies (layer caching optimization for speedy dreams)  
COPY --chown=vscode:vscode package.json /tmp/
WORKDIR /tmp
RUN echo "📦 Assembling Node.js packages for web development dreams..." && \
    npm install --omit=dev --ignore-scripts

# 🏠 Set final working directory for your dreams
WORKDIR /workspace
RUN echo "🎉 Dream Container construction complete! Welcome to your development paradise! 💭✨"