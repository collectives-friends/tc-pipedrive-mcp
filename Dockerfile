# Multi-stage build for optimized image size
FROM node:20-alpine AS builder

# Set working directory
WORKDIR /app

# Copy package files
COPY package*.json ./
COPY tsconfig.json ./

# Install dependencies
RUN npm ci

# Copy source code
COPY src ./src

# Build the application
RUN npm run build

# Production stage
FROM node:20-alpine AS production

# Install wget for healthcheck + Infisical CLI (secrets injected at runtime)
RUN apk add --no-cache wget ca-certificates && \
    ARCH=$(uname -m); case "$ARCH" in x86_64) A=amd64;; aarch64) A=arm64;; *) A=amd64;; esac; \
    wget -qO /tmp/inf.tar.gz "https://github.com/Infisical/cli/releases/download/v0.43.96/cli_0.43.96_linux_${A}.tar.gz" && \
    tar -xzf /tmp/inf.tar.gz -C /usr/local/bin infisical && \
    rm /tmp/inf.tar.gz && chmod +x /usr/local/bin/infisical

# Set working directory
WORKDIR /app

# Copy package files and built application from builder stage
COPY --from=builder /app/package.json /app/package-lock.json ./
COPY --from=builder /app/build ./build
COPY infisical-entrypoint.sh /app/infisical-entrypoint.sh
RUN chmod +x /app/infisical-entrypoint.sh

# Install production dependencies only
RUN npm ci --omit=dev

# Set NODE_ENV to production
ENV NODE_ENV=production

# Expose the default MCP port (can be overridden via environment variable)
EXPOSE 3000

# Run as non-root user for security
USER node

# Start the application via Infisical (secrets injected from the vault)
CMD ["/app/infisical-entrypoint.sh"]
