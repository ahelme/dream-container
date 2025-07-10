## 🚀 **Quick Start** *(2 minutes to awesome)*

### **Shell Compatibility**  
We provide two setup scripts for maximum compatibility:

- **`setup-zsh.sh`**: For Zsh users (macOS default, oh-my-zsh)
- **`setup-bash.sh`**: For Bash users (Linux default, Windows WSL)

Both scripts provide identical functionality with shell-appropriate syntax and file paths.


### **Choose Your Setup Script:**

**For Zsh users (macOS default, oh-my-zsh users):**
```bash
# 1️⃣ Clone your dream environment
git clone https://github.com/ahelme/dream-container.git
cd dream-container

# 2️⃣ Customize (optional)
cp .env.example .env
# Edit .env with your project details

# 3️⃣ Launch your dreams 🚀
./scripts/setup-zsh-script.sh
```

**For Bash users (Linux default, Windows WSL):**
```bash
# 1️⃣ Clone your dream environment  
git clone https://github.com/ahelme/dream-container.git
cd dream-container

# 2️⃣ Customize (optional)
cp .env.example .env
# Edit .env with your project details

# 3️⃣ Launch your dreams 🚀
./scripts/setup-bash-script.sh
```

### **4️⃣ Open in VS Code**
```bash
code .
# Select "Reopen in Container" when prompted
```

🎉 **You're living the dream! Start coding immediately!**

---

## 🔐 **Authentication & Setup**

### **GitHub Authentication**
DreamOps setup scripts use **GitHub CLI web authentication** (`gh auth login --web`) for the best security and user experience:

- ✅ **Secure browser-based login**
- ✅ **Works with 2FA automatically**  
- ✅ **No tokens to manage**
- ✅ **Persistent across container rebuilds**

**Alternative Authentication:** If you prefer different GitHub authentication methods (personal access tokens, SSH keys, etc.), you can set these up manually after the container is running:

```bash
# Enter your Dream Container
docker-compose exec devcontainer zsh

# Set up your preferred authentication method
gh auth login --with-token  # For token-based auth
# or configure SSH keys, etc.
```

### **Claude Code Setup**
The setup script optionally configures Claude Code for AI-powered development:

- ✅ **Browser-based authentication**
- ✅ **MCP tools integration**
- ✅ **Persistent configuration**

**Manual Setup:** You can also set up Claude Code later:
```bash
docker-compose exec devcontainer zsh
claude login
```

---

## 🎯 **Manual Setup** *(If you prefer the long way)*

If you want to understand each step or customize the process:

```bash
# Check requirements
docker --version
docker-compose --version

# Build and start services  
docker-compose build
docker-compose up -d

# Enter the container
docker-compose exec devcontainer zsh

# Set up authentication (optional)
gh auth login --web
claude login

# Start developing!
```