# Multi-stage build for minimal container image
# Uses pre-built binaries from CI artifacts

# We use alpine as base for the final image (for shell access if needed)
# ARG is used to select the correct binary based on target platform
ARG TARGETPLATFORM

FROM alpine:latest

# Install minimal runtime dependencies (if any needed in future)
# Currently ansilust is statically linked, so none needed

WORKDIR /

# Copy the appropriate binary based on platform
# The binaries are copied from artifacts/ which is populated by the CI download step
# Platform mapping:
#   linux/amd64  -> linux-x64-musl/ansilust
#   linux/arm64  -> linux-arm64-musl/ansilust  
#   linux/arm/v7 -> linux-arm-musl/ansilust
COPY artifacts/ /artifacts/

# Use shell to copy the correct binary based on TARGETPLATFORM
RUN case "${TARGETPLATFORM}" in \
      "linux/amd64")  cp /artifacts/linux-x64-musl/ansilust /ansilust ;; \
      "linux/arm64")  cp /artifacts/linux-arm64-musl/ansilust /ansilust ;; \
      "linux/arm/v7") cp /artifacts/linux-arm-musl/ansilust /ansilust ;; \
      *) echo "Unsupported platform: ${TARGETPLATFORM}" && exit 1 ;; \
    esac && \
    chmod +x /ansilust && \
    rm -rf /artifacts

# Set entrypoint
ENTRYPOINT ["/ansilust"]

# Default command - show help
CMD ["--help"]
