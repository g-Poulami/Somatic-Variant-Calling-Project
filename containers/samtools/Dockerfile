FROM debian:bookworm-slim

# Install pre-compiled samtools and clean up
RUN apt-get update && apt-get install -y --no-install-recommends \
    samtools \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /data

# No Entrypoint for Nextflow compatibility
CMD ["samtools"]