# ====================================
# MULTI-STAGE DOCKER BUILD
# ====================================

# Stage 1: Build dependencies
FROM node:18-alpine AS builder

# Set working directory
WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies with clean install
RUN npm ci --only=production --no-audit --no-fund

# Stage 2: Production runtime
FROM node:18-alpine AS runtime

# Install security updates
RUN apk upgrade --no-cache && \
    apk add --no-cache dumb-init curl

# Create non-root user
RUN addgroup -g 1000 app && \
    adduser -u 1000 -G app -s /bin/sh -D app

# Set working directory
WORKDIR /app

# Copy dependencies from builder stage
COPY --from=builder /app/node_modules ./node_modules

# Copy application source
COPY --chown=app:app . .

# Create necessary directories with proper permissions
RUN mkdir -p /app/logs /app/tmp && \
    chown -R app:app /app

# Switch to non-root user
USER app

# Expose port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:3000/health || exit 1

# Use dumb-init to handle signals properly
ENTRYPOINT ["dumb-init", "--"]

# Start application
CMD ["npm", "start"]

# ====================================
# BUILD METADATA
# ====================================

# Build-time metadata
ARG BUILD_DATE
ARG VERSION
ARG VCS_REF

# Image metadata
LABEL maintainer="your-team@yourcompany.com" \
      org.opencontainers.image.title="Enterprise Application" \
      org.opencontainers.image.description="Enterprise-grade application with security best practices" \
      org.opencontainers.image.version=$VERSION \
      org.opencontainers.image.created=$BUILD_DATE \
      org.opencontainers.image.revision=$VCS_REF \
      org.opencontainers.image.source="https://github.com/yourorg/yourrepo" \
      org.opencontainers.image.vendor="Your Organization"