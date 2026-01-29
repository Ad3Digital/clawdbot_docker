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

# Install clawdbot globally
RUN npm install -g clawdbot npm-check-updates pnpm

# Create working directory
WORKDIR /app

# Expose Gateway port
EXPOSE 18789

# Set entrypoint
CMD ["clawdbot", "gateway"]

