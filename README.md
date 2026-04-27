# Somatic Variant Calling Pipeline

[![Nextflow CI](https://github.com/g-Poulami/Somatic-Variant-Calling-Project/actions/workflows/main.yml/badge.svg)](https://github.com/g-Poulami/Somatic-Variant-Calling-Project/actions)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://github.com/g-Poulami/Somatic-Variant-Calling-Project/blob/main/LICENSE)
[![Nextflow](https://img.shields.io/badge/nextflow%20DSL2-checked-brightgreen.svg)](https://www.nextflow.io/)

An automated, containerized end-to-end pipeline for identifying somatic mutations (SNVs and Indels) from raw sequencing data. This workflow implements GATK Best Practices for high-confidence variant discovery.

## Workflow Overview
This pipeline automates the transformation of raw FASTQ files into filtered VCF files. Each step is encapsulated in a dedicated Docker container to ensure environment consistency across local, HPC, and Cloud environments.

### Core Architecture
1. **Reference Indexing**: Generates BWA indices, Fasta indices (.fai), and Sequence Dictionaries (.dict).
2. **Alignment (BWA-MEM)**: Maps reads to the reference with automated Read Group (@RG) injection.
3. **Processing**: Sorts and indexes BAM files for efficient downstream access.
4. **Variant Calling (Mutect2)**: Uses a somatic-aware HaplotypeCaller engine to identify variants.
5. **Filtration**: Applies `FilterMutectCalls` to remove technical artifacts and strand bias.

## Technical Specifications

| Stage | Tool | Version | Docker Container | Output Files |
| :--- | :--- | :--- | :--- | :--- |
| **Indexing** | BWA / GATK | 0.7.17 / 4.5.0 | `somatic-bwa` / `somatic-gatk` | `.amb`, `.ann`, `.dict`, etc. |
| **Mapping** | BWA-MEM | 0.7.17 | `somatic-bwa` | `aligned.bam` |
| **Sorting** | Samtools | 1.17 | `somatic-samtools` | `sorted.bam`, `sorted.bam.bai` |
| **Calling** | Mutect2 | 4.5.0 | `somatic-gatk` | `raw_somatic.vcf.gz` |
| **Filtering** | GATK Filter | 4.5.0 | `somatic-gatk` | `filtered_somatic.vcf.gz` |

## Pipeline Visualization
The following diagram illustrates the flow of data through the Nextflow processes:



## Analysis Results
The output is a compressed VCF file. In a clinical or research setting, results are typically validated by inspecting the alignment in the Integrative Genomics Viewer (IGV).

### Example IGV Visualization
Below is an example of a high-confidence somatic SNV identified by the pipeline, showing high mapping quality and balanced strand support.



## Getting Started

### Prerequisites
- **Nextflow** (22.10.0+)
- **Docker** (Engine version 20.10+)

### Execution
To run the pipeline with the provided test data:
\`\`\`bash
nextflow run main.nf \
  --tumor_fastq "data/fastq/tumor.fastq.gz" \
  --genome "data/ref/genome.fa" \
  --outdir "results" \
  -resume
\`\`\`

## License
This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Contact
**g-Poulami**
GitHub: [https://github.com/g-Poulami](https://github.com/g-Poulami)
