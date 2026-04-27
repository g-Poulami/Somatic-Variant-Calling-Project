FROM broadinstitute/gatk:4.5.0.0
LABEL org.opencontainers.image.title="GATK Somatic"
RUN apt-get update && apt-get install -y --no-install-recommends     samtools     && rm -rf /var/lib/apt/lists/*
RUN groupadd -r bioinfo && useradd -r -g bioinfo -G root bioinfo
RUN mkdir -p /data/input /data/ref /data/output && chown -R bioinfo:bioinfo /data
USER bioinfo
WORKDIR /data
CMD ["gatk"]