FROM node:22-slim

# Install system dependencies + package managers + dev tools
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    python3-venv \
    build-essential \
    git \
    ffmpeg \
    curl \
    wget \
    sudo \
    vim \
    nano \
    jq \
    unzip \
    zip \
    tar \
    gzip \
    htop \
    net-tools \
    iputils-ping \
    && rm -rf /var/lib/apt/lists/*

# Give root passwordless sudo (já é root, mas garante compatibilidade)
RUN echo "root ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

# Install additional Python tools
RUN pip3 install --no-cache-dir --break-system-packages \
    pipx \
    setuptools \
    wheel

# Install clawdbot globally and OAuth CLIs for authentication
RUN npm install -g clawdbot npm-check-updates pnpm

# Install CLIs for OAuth authentication (Claude Code, Gemini, etc.)
RUN npm install -g @anthropics/claude-code @google/generative-ai-cli || true

# Create working directory
WORKDIR /app

# Download and install CLIProxyAPI (Linux version)
RUN ARCH=$(dpkg --print-architecture) && \
    VERSION=$(curl -s https://api.github.com/repos/router-for-me/CLIProxyAPI/releases/latest | grep '"tag_name"' | cut -d'"' -f4) && \
    echo "Downloading CLIProxyAPI ${VERSION} for ${ARCH}..." && \
    curl -L "https://github.com/router-for-me/CLIProxyAPI/releases/download/${VERSION}/CLIProxyAPI_${VERSION#v}_linux_${ARCH}.tar.gz" -o /tmp/cliproxy.tar.gz && \
    tar -xzf /tmp/cliproxy.tar.gz -C /app && \
    rm /tmp/cliproxy.tar.gz && \
    chmod +x /app/cli-proxy-api

# Copy CLIProxyAPI config
COPY CLIProxyAPI/config.yaml /app/config.yaml

# Copy OAuth credentials if they exist (from host user directory)
# This will be mounted as volume in docker-compose instead
# RUN mkdir -p /root/.cli-proxy-api

# Copy entrypoint and watchdog scripts
COPY entrypoint.sh /app/entrypoint.sh
COPY watchdog.sh /app/watchdog.sh
RUN chmod +x /app/entrypoint.sh /app/watchdog.sh

# Expose Gateway port and CLIProxyAPI port
EXPOSE 18789 8317

# Set entrypoint
ENTRYPOINT ["/app/entrypoint.sh"]
CMD ["clawdbot", "gateway", "--bind", "lan"]

