<div align="center">
<img src="frontend/static/assets/img/dream_ops_claude_cloud.png" alt="DreamContainer... transcending bureaucracy." width="400">
</div>

# 💭DreamContainer™️💭 & 💭DreamKit™️💭
**AI-Ready Development That Dreams Are Made Of**

[![GitHub Stars](https://img.shields.io/github/stars/ahelme/dream-container?style=for-the-badge&logo=github)](https://github.com/ahelme/dream-container)
[![Docker Pulls](https://img.shields.io/docker/pulls/ahelme/dream-container?style=for-the-badge&logo=docker)](https://hub.docker.com/r/ahelme/dream-container)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)](https://opensource.org/licenses/MIT)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg?style=for-the-badge)](http://makeapullrequest.com)

This project is a two-in-one:

1. DreamContainer: the AI-ready fully-optimised multi-architecture .devcontainer of your dreams.

2. DreamKit - FastAPI & htmx Template: the modern opinionated architecture to make your Javascript framework nightmares fade away.

## **Not just another devcontainer...**

DreamContainer is the **AI-first development environment you've been dreaming of**.

### **Fully Isolated AI-Powered Development with Persistent Auth**
- **Claude Code & Github CLI** integration out of the box
- **MCP tools** ecosystem (Puppeteer, Playwright, Browser automation)
- **Browser automation** ready (screenshots, testing, scraping)
- **Security best practices** (read-only mounts, isolated packages)
- **Production-like** development environment
- **gh auth** survives rebuilds (no more re-login after every rebuild)

### **Multi-Platform & Enterprise-Ready**
- **Native ARM64** (Apple Silicon Macs) / **Native AMD64** builds (Intel/AMD servers)
- **Zero QEMU emulation** slowdown (50-80% faster)
- **Multi-service orchestration** (API, Database, Cache, Frontend)
- **Proper volume management** (zero host pollution)

### **Zero-Friction Developer Experience**
- **One command setup**
- **Automatic dependency management** 
- **Health checks included**
- **Works on any machine** immediately
- **Smart versioning** security updates without breaking changes

---

## **Quick Start** *(2 minutes to awesome)*

```bash
# ① Clone your dream environment
git clone https://github.com/ahelme/dream-container.git
cd dream-container

**Customize** (optional)
cp .env.example .env
# Edit .env with your project details

# ② Launch your dreams... 🚀
./scripts/setup.sh

# ③ (Optional) Open in VS Code 
code .
# Select "Reopen in Container" when prompted

# ④ Claude Code is installed & ready to vibe...
claude
> Help me build the app of my dreams!

# 💭 Living the dream... start coding immediately!
```

### **Dream vs Nightmare**

| 😭 **Development Hell** | 💭 **DreamContainer** |
|---|---|
| ❌ Breaks after rebuilds | ✅ Persistent authentication |
| ❌ Slow multi-platform builds | ✅ Native ARM64 + AMD64 |
| ❌ Host dependency pollution | ✅ Perfect isolation |
| ❌ Complex authentication setup | ✅ One-command login |
| ❌ Hours of configuration | ✅ 2-minute setup |

---

# ** DreamKit - FastAPI & htmx Template**

_Anti-Bureaucracy Architecture_

```
├── 🤖 Dream AI Dev Container (Claude Code + MCP Tools)
├── 🐘 PostgreSQL Database
├── 📦 Cache Layer (Redis/Valkey/KeyDB)
├── 🚀 API Server (FastAPI/Express/Django)
├── ⚡ HTMX Frontend (Zero build complexity!)
└── 🔧 Quality Tools (Black, Prettier, Tests)

Notice what's missing? Webpack, Babel, build scripts, node_modules chaos!
```

### 🤖 AI Dev Layer

• Claude Code for AI pair programming
• MCP tools for automation
• Browser testing capabilities
• Persistent authentication

### ⚡️ Frontend Layer

• HTMX for dynamic interactions
• Tailwind for beautiful styling
• No build process needed
• Edit and refresh workflow

### 🚀 Backend Layer

• FastAPI for modern Python APIs
• Automatic OpenAPI documentation
• Type validation included
• Async support out of the box

### 🗄️ Data Layer

• PostgreSQL for reliability
• Redis for lightning-fast caching
• Persistent volumes for data safety
• Connection pooling configured

---

## **Dream Up Your Perfect App**

### 🌟 Anti-Bureaucratic Web Apps

Zero build complexity

• HTMX + Tailwind + FastAPI/Express backends
• Database-driven applications &  API-first development 
• Real-time updates without JavaScript frameworks complexity
• HTML & Nginx for the bare essentials!

### 🤖 AI & ML Projects

Claude Code ready

• Claude Code integration out of the box
• Jupyter notebooks with HTMX frontends
• Data visualization without unnecessary complexity

### 🏢 Enterprise Development

Production ready

• Microservices architecture
• Multi-team collaboration without build conflicts
• Security-focused development

### 🚀 Startup MVPs

Ship fast, iterate faster

• Rapid prototyping without build tools
• Full-stack in minutes, not hours
• Production-grade from day one: scale as you go

"The best framework is the one you don't need." - DreamOps Philosophy

---

## 📚 **Dream Documentation**

| 📖 **Guide** | 🎯 **Perfect For** |
|---|---|
| [🚀 Quick Start](docs/QUICK_START.md) | Living the dream in 2 minutes |
| [🏗️ Architecture](docs/ARCHITECTURE.md) | Understanding your dreams |
| [⚙️ Customization](docs/CUSTOMIZATION.md) | Personalizing your dreams |
| [🔐 Authentication](docs/AUTHENTICATION.md) | Setting up dream authentication |
| [🐛 Troubleshooting](docs/TROUBLESHOOTING.md) | When dreams need fixing |
| [🤖 Claude Code](docs/CLAUDE_CODE.md) | AI-powered dream development |

---

## 🔧 **Ready-Made Dream Setups (in progress..)**

Choose your dream stack and start immediately:

### ⚡ **Anti-Bureaucracy Web Dreams** (Recommended!)
- **[FastAPI + HTMX](examples/fastapi-htmx/)** - Modern Python web without frontend complexity
- **[Django + HTMX](examples/django-htmx/)** - Traditional Python with dynamic UI magic  
- **[Express + HTMX](examples/express-htmx/)** - Node.js backend with zero-build frontend
- **[Pure HTML + API](examples/html-api/)** - Static HTML + Tailwind + API calls

### 🤖 **AI & Data Dreams**
- **[Data Science](examples/data-science/)** - Jupyter + ML library dreams
- **[AI Chatbot](examples/ai-chatbot/)** - Claude Code + LangChain dreams
- **[Computer Vision](examples/computer-vision/)** - OpenCV + PyTorch dreams
- **[Claude Code Playground](examples/claude-playground/)** - MCP tools sandbox

### 🏢 **Enterprise Dreams**
- **[Microservices](examples/microservices/)** - Docker Compose + Kong dreams
- **[GraphQL API](examples/graphql/)** - Apollo Server setup dreams
- **[Auth + RBAC](examples/auth-rbac/)** - Security-first development

### 🎯 **Framework Dreams** (For the build-tool lovers)
- **[FastAPI + React](examples/fastapi-react/)** - If you enjoy bundler complexity
- **[Vue + Express](examples/vue-express/)** - Component-based development
- **[Next.js Full-Stack](examples/nextjs/)** - SSR with all the bells and whistles
- **[Svelte + FastAPI](examples/svelte-fastapi/)** - Compile-time optimized

> 💡 **Dream Tip:** Start with HTMX examples for maximum anti-bureaucracy bliss! You can always add React later if your project truly needs it (spoiler: it probably doesn't!).

---

## 🚀 **Start Living Your Dreams Now**

### Option 1: **Use as Template** *(Recommended)*
```bash
# Create new dream from this template
gh repo create my-dream-project --template yourname/dream-container
cd my-dream-project
code .
```

### Option 2: **Clone and Customize**
```bash
git clone https://github.com/yourname/dream-container.git
cd dream-container
# Customize your dreams
```

### Option 3: **Add Dreams to Existing Project**
```bash
# Copy just the dream setup
curl -sL https://github.com/yourname/dream-container/archive/main.tar.gz | tar -xz --strip=1 "*/\.devcontainer"
```

---

## **Contributing**

- 🐛 **Found a nightmare?** [Report it](https://github.com/yourname/dream-container/issues)
- 💡 **Have a dream idea?** [Share it](https://github.com/yourname/dream-container/discussions)  
- 🔧 **Want to contribute?** [Join the dream team](CONTRIBUTING.md)
- ⭐ **Think its dreamy?** Star it and tell your friends!

---

## 📄 **License**

MIT License - feel free to use this for all your dreams! See [LICENSE](LICENSE) for details.

---

## 🙏 **Dream Team Acknowledgments**

Built with 💭 by developers who were tired of development nightmares.

Credits:
- [Aeon Helme](https://github.com/ahelme/)
- [Claude Sonnet](https://www.anthropic.com/claude/sonnet)

Special thanks to:
- The VS Code team for making devcontainer dreams possible
- Anthropic for Claude Code that makes AI dreams real
- The Docker team for multi-platform dream builds
- Everyone who contributed examples and made dreams come true

---

<div align="center">

### 💭 **Ready to live your development dreams?**

**[⭐ Star this dream](https://github.com/ahelme/dream-container)** • **[📖 Read the dream docs](docs/)** • **[💬 Join dream discussions](https://github.com/ahelme/dream-container/discussions)**

</div>

---

<div align="center">
<sub>Made with 💭 and ☕ by dreamers, for dreamers</sub>
</div>