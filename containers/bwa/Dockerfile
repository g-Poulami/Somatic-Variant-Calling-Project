FROM debian:bookworm-slim AS builder
ARG BWA_VERSION=0.7.18
RUN apt-get update && apt-get install -y --no-install-recommends     wget make gcc zlib1g-dev ca-certificates     && rm -rf /var/lib/apt/lists/*
RUN wget -q "https://github.com/lh3/bwa/archive/refs/tags/v${BWA_VERSION}.tar.gz" -O bwa.tar.gz     && tar -xzf bwa.tar.gz && cd bwa-${BWA_VERSION} && make     && cp bwa /usr/local/bin/
FROM debian:bookworm-slim
RUN apt-get update && apt-get install -y --no-install-recommends zlib1g && rm -rf /var/lib/apt/lists/*
COPY --from=builder /usr/local/bin/bwa /usr/local/bin/bwa
CMD ["bwa"]
