FROM node:22-slim

# Install system dependencies
RUN apt-get update && apt-get install -y \
    python3 \
    build-essential \
    git \
    && rm -rf /var/lib/apt/lists/*

# Install clawdbot globally
RUN npm install -g clawdbot

# Create working directory
WORKDIR /app

# Expose Gateway port
EXPOSE 18789

# Set entrypoint
CMD ["clawdbot", "gateway"]

