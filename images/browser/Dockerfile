# 💭 DreamContainer browser variant — base + Chromium/Playwright
#
# Opt-in per project (`dream new --browser`). Never the default: the browser
# stack costs 1–2 GB of RAM headroom and a much larger image. See
# docs/ARCHITECTURE.md §4.
#
# Build context is the repo root (needs images/base first):
#   docker buildx bake browser

ARG BASE_IMAGE=ghcr.io/ahelme/dream-container:latest
FROM ${BASE_IMAGE}

USER root
ARG DEBIAN_FRONTEND=noninteractive

# Chromium from Debian (multi-arch — works on arm64 where Chrome doesn't)
# plus the runtime libs Playwright needs.
RUN apt-get update && apt-get install -y --no-install-recommends \
      chromium \
      fonts-liberation \
      libasound2 \
      libatk-bridge2.0-0 \
      libatk1.0-0 \
      libcups2 \
      libdbus-1-3 \
      libdrm2 \
      libgbm1 \
      libgtk-3-0 \
      libnss3 \
      libxcomposite1 \
      libxdamage1 \
      libxfixes3 \
      libxkbcommon0 \
      libxrandr2 \
      xdg-utils \
    && rm -rf /var/lib/apt/lists/*

# Point Puppeteer/Playwright at the system Chromium; skip their downloads.
ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true \
    PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium \
    PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1 \
    PLAYWRIGHT_CHROMIUM_EXECUTABLE_PATH=/usr/bin/chromium

USER agent
WORKDIR /workspace

# NOTE for compose: browser projects need shm headroom —
#   shm_size: "1gb"
# (set automatically by `dream new --browser` in the project .env)
