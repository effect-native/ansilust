# Multi-stage build for minimal container image
# This Dockerfile builds a minimal container with just the ansilust binary

# Stage 1: Build (uses Zig to compile)
FROM alpine:latest AS builder

# Install Zig and dependencies
RUN apk add --no-cache \
    zig \
    build-base \
    git

WORKDIR /src

# Copy source code
COPY . .

# Build ansilust
RUN zig build -Doptimize=ReleaseSafe

# Stage 2: Runtime (minimal image with just the binary)
FROM scratch

# Copy only the binary from builder
COPY --from=builder /src/zig-out/bin/ansilust /ansilust

# Set entrypoint
ENTRYPOINT ["/ansilust"]

# Default command - show help
CMD ["--help"]
