# Somatic-Variant-Calling-Nextflow

[![Nextflow](https://img.shields.io/badge/Nextflow-%E2%89%A523.04-brightgreen?style=flat-square)](https://nextflow.io)
[![License](https://img.shields.io/badge/License-MIT-blue?style=flat-square)](LICENSE)
[![CI](https://github.com/g-Poulami/Somatic-Variant-Calling-Nextflow/actions/workflows/ci.yml/badge.svg)](https://github.com/g-Poulami/Somatic-Variant-Calling-Nextflow/actions/workflows/ci.yml)

A scalable **Nextflow DSL2** pipeline for somatic mutation identification in paired tumour-normal cancer genomics datasets, implementing the GATK best-practice Mutect2 workflow.

---

## Overview

Somatic variant calling identifies mutations present in tumour tissue that are absent from matched normal (germline) DNA. Unlike germline calling, somatic analysis must distinguish true low-allele-fraction tumour mutations from sequencing artefacts and germline variants — requiring a dedicated statistical framework.

This pipeline implements the GATK Mutect2 tumour-normal workflow with panel of normals (PoN) filtering, contamination estimation, and orientation bias artefact filtering to produce a high-confidence somatic VCF suitable for downstream annotation and clinical research.

---

## Pipeline Steps

```
Tumour FASTQ + Normal FASTQ
          |
          v
   FastQC (raw)               -- per-sample read QC
          |
          v
   Trimmomatic                -- adapter removal, quality trimming
          |
          v
   FastQC (trimmed)           -- confirm trimming
          |
          v
   BWA-MEM2 alignment         -- map tumour and normal to reference
          |
          v
   SAMtools sort & index       -- coordinate-sorted BAMs
          |
          v
   Picard MarkDuplicates       -- mark/remove PCR duplicates
          |
          v
   GATK BQSR                  -- base quality score recalibration
          |
          v
   GATK Mutect2                -- tumour-normal somatic variant calling
   (+ Panel of Normals)
          |
          v
   GATK GetPileupSummaries     -- estimate tumour contamination
   GATK CalculateContamination
          |
          v
   GATK LearnReadOrientationModel  -- orientation bias artefact detection
          |
          v
   GATK FilterMutectCalls      -- apply all filters to somatic VCF
          |
          v
   Filtered Somatic VCF
          |
          v
   MultiQC                    -- aggregated QC report
```

---

## Key Features

- **Tumour-normal paired design**: matched normal sample removes germline background and technical artefacts
- **Panel of Normals (PoN) support**: further reduces recurrent sequencing artefacts not captured by a single normal
- **Contamination estimation**: `GetPileupSummaries` + `CalculateContamination` quantifies cross-sample contamination and feeds directly into `FilterMutectCalls`
- **Orientation bias filtering**: `LearnReadOrientationModel` guards against oxidative damage (OxoG) artefacts common in FFPE samples
- **Nextflow DSL2 modularity**: each tool is an isolated, reusable module; profiles for local, Docker, Singularity, conda, and SLURM
- **Resumable**: Nextflow caching means interrupted runs restart from the last successful task

---

## Quick Start

### Install Nextflow

```bash
curl -s https://get.nextflow.io | bash
sudo mv nextflow /usr/local/bin/
```

### Stub run (no tools required)

```bash
git clone https://github.com/g-Poulami/Somatic-Variant-Calling-Nextflow.git
cd Somatic-Variant-Calling-Nextflow
python3 test/generate_test_data.py
nextflow run main.nf -profile test -stub-run
```

### Run with Docker on your data

```bash
nextflow run main.nf \
  -profile docker \
  --tumour_reads  'data/tumour_*_R{1,2}.fastq.gz' \
  --normal_reads  'data/normal_*_R{1,2}.fastq.gz' \
  --genome        'ref/hg38.fa' \
  --known_sites   'ref/dbsnp_146.hg38.vcf.gz' \
  --pon           'ref/somatic-hg38_1000g_pon.hg38.vcf.gz' \
  --germline_resource 'ref/af-only-gnomad.hg38.vcf.gz' \
  --outdir        results
```

### Resume after failure

```bash
nextflow run main.nf -resume [other params]
```

---

## Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `--tumour_reads` | required | Glob pattern for tumour paired FASTQs |
| `--normal_reads` | required | Glob pattern for matched normal FASTQs |
| `--genome` | required | Reference genome FASTA |
| `--known_sites` | null | dbSNP VCF for BQSR |
| `--pon` | null | Panel of Normals VCF |
| `--germline_resource` | null | gnomAD allele frequency VCF for Mutect2 |
| `--run_bqsr` | `true` | Run BQSR on both tumour and normal |
| `--outdir` | `results` | Output directory |
| `--run_multiqc` | `true` | Aggregate QC reports |

---

## Outputs

| Directory | Contents |
|-----------|----------|
| `results/fastqc/` | FastQC HTML reports (raw and trimmed) |
| `results/bwa/` | Aligned SAM files |
| `results/samtools/` | Sorted BAMs, BAI indices, flagstat |
| `results/picard/` | Deduplicated BAMs and duplication metrics |
| `results/bqsr/` | Recalibrated BAMs |
| `results/mutect2/` | Raw somatic VCF and stats |
| `results/contamination/` | Contamination tables |
| `results/filtered/` | Final filtered somatic VCF |
| `results/multiqc/` | `multiqc_report.html` |

---

## Profiles

| Profile | Description |
|---------|-------------|
| `local` | Run locally, tools must be in PATH |
| `docker` | Pull from quay.io/biocontainers and broadinstitute/gatk |
| `singularity` | Singularity images (recommended for HPC) |
| `conda` | Per-process conda environments |
| `slurm` | Submit to SLURM cluster |
| `test` | Synthetic paired data for CI |

---

## Project Structure

```
Somatic-Variant-Calling-Nextflow/
├── main.nf
├── nextflow.config
├── assets/
│   └── adapters.fa
├── modules/
│   ├── fastqc.nf
│   ├── trimmomatic.nf
│   ├── bwamem2.nf
│   ├── samtools.nf
│   ├── picard.nf
│   ├── gatk_bqsr.nf
│   ├── mutect2.nf
│   ├── contamination.nf
│   ├── filter_mutect.nf
│   └── multiqc.nf
├── test/
│   └── generate_test_data.py
└── .github/
    └── workflows/
        └── ci.yml
```

---

## License

MIT

---

## Author

Poulami Ghosh — [LinkedIn](https://linkedin.com/in/poulami-ghosh-879439304) | [Google Scholar](https://scholar.google.com)
