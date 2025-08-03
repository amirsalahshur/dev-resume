# Multi-stage Dockerfile for Production Portfolio Application
# Stage 1: Build stage
FROM node:20-alpine AS builder

# Set working directory
WORKDIR /app

# Copy package files
COPY package*.json ./

# Install all dependencies (including devDependencies for build)
RUN npm ci --include=dev

# Copy source code
COPY . .

# Build the application
RUN npm run build

# Stage 2: Production stage
FROM node:20-alpine AS production

# Install PM2 globally
RUN npm install -g pm2@latest

# Create app user for security
RUN addgroup -g 1001 -S appgroup && \
    adduser -S appuser -u 1001 -G appgroup

# Set working directory
WORKDIR /app

# Copy package files
COPY package*.json ./

# Install only production dependencies
RUN npm ci --only=production && \
    npm cache clean --force

# Copy built application from builder stage
COPY --from=builder /app/dist ./dist

# Copy PM2 ecosystem and health check script
COPY ecosystem.config.js ./
COPY scripts/health-check.js ./scripts/

# Create logs directory
RUN mkdir -p /app/logs && \
    chown -R appuser:appgroup /app

# Create non-root user directories
RUN mkdir -p /home/appuser/.pm2 && \
    chown -R appuser:appgroup /home/appuser

# Switch to non-root user
USER appuser

# Expose ports
EXPOSE 3000 3001

# Health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD node /app/scripts/health-check.js || exit 1

# Use PM2 to run the application
CMD ["pm2-runtime", "start", "ecosystem.config.js", "--env", "production"]

# Metadata
LABEL maintainer="Amir Salahshur <amir@example.com>"
LABEL description="Production-ready portfolio application with PM2 and health checks"
LABEL version="2.0.0"