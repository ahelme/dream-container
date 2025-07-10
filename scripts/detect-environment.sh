#!/bin/bash
# 💭 DREAM CONTAINER - Environment Detection Script
# Detect if running in devcontainer, regular container, or host environment

detect_environment() {
    local env_type="unknown"
    local container_type=""
    local details=""
    
    # Check if we're in any Docker container
    if [ -f /.dockerenv ]; then
        env_type="container"
        
        # Check for devcontainer-specific indicators
        if [ -n "$REMOTE_CONTAINERS" ] || [ -n "$CODESPACES" ] || [ -n "$VSCODE_REMOTE_CONTAINERS_SESSION" ]; then
            container_type="devcontainer"
            details="VS Code devcontainer detected"
        elif [ -n "$TERM_PROGRAM" ] && [ "$TERM_PROGRAM" = "vscode" ]; then
            container_type="devcontainer"
            details="VS Code terminal detected"
        elif [ -f /home/vscode/.vscode-server/bin ]; then
            container_type="devcontainer"
            details="VS Code server files detected"
        elif [ -d /workspaces ] || [ -d /workspace ]; then
            container_type="devcontainer"
            details="Workspace directory detected"
        else
            container_type="regular"
            details="Regular Docker container"
        fi
        
        # Additional container info
        if [ -f /proc/1/cgroup ]; then
            local cgroup_info=$(head -1 /proc/1/cgroup)
            if [[ "$cgroup_info" == *"docker"* ]]; then
                details="$details (Docker cgroup confirmed)"
            fi
        fi
        
    # Check if we're in GitHub Codespaces
    elif [ -n "$CODESPACES" ]; then
        env_type="codespaces"
        container_type="codespaces"
        details="GitHub Codespaces environment"
        
    # Check if we're in WSL
    elif [ -n "$WSL_DISTRO_NAME" ] || grep -qi microsoft /proc/version 2>/dev/null; then
        env_type="wsl"
        details="Windows Subsystem for Linux"
        
    else
        env_type="host"
        details="Native host environment"
    fi
    
    # Export environment variables
    export DEV_ENV="$env_type"
    export DEV_CONTAINER_TYPE="$container_type"
    export DEV_ENV_DETAILS="$details"
    
    # Print results
    echo "🔍 Environment Detection Results:"
    echo "   Environment: $env_type"
    [ -n "$container_type" ] && echo "   Container Type: $container_type"
    echo "   Details: $details"
    echo ""
    echo "📋 Environment Variables Set:"
    echo "   DEV_ENV=$DEV_ENV"
    echo "   DEV_CONTAINER_TYPE=$DEV_CONTAINER_TYPE"
    echo "   DEV_ENV_DETAILS=\"$DEV_ENV_DETAILS\""
    
    return 0
}

# Additional helper functions
check_docker_availability() {
    if command -v docker >/dev/null 2>&1; then
        echo "✅ Docker is available"
        docker --version 2>/dev/null || echo "❌ Docker daemon not running"
    else
        echo "❌ Docker not installed"
    fi
}

check_development_tools() {
    echo ""
    echo "🛠️  Development Tools Check:"
    
    tools=("git" "node" "npm" "python3" "pip" "curl" "wget" "code" "claude")
    
    for tool in "${tools[@]}"; do
        if command -v "$tool" >/dev/null 2>&1; then
            local version=""
            case "$tool" in
                "git") version=$(git --version 2>/dev/null | cut -d' ' -f3) ;;
                "node") version=$(node --version 2>/dev/null) ;;
                "npm") version=$(npm --version 2>/dev/null) ;;
                "python3") version=$(python3 --version 2>/dev/null | cut -d' ' -f2) ;;
                "pip") version=$(pip --version 2>/dev/null | cut -d' ' -f2) ;;
                "code") version="installed" ;;
                "claude") version="installed" ;;
                *) version="available" ;;
            esac
            echo "   ✅ $tool: $version"
        else
            echo "   ❌ $tool: not available"
        fi
    done
}

# Run detection if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    detect_environment
    check_docker_availability
    check_development_tools
fi