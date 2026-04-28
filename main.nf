nextflow.enable.dsl=2

params.genome = "${launchDir}/data/ref/genome.fa"
params.tumor_fastq = "${launchDir}/data/fastq/tumor.fastq.gz"
params.outdir = "${launchDir}/results"

process BWA_INDEX {
    container 'somatic-bwa:latest'
    input: path ref
    output: path "${ref}.*"
    script: "bwa index $ref"
}

process SAMTOOLS_FAIDX {
    container 'somatic-samtools:latest'
    input: path ref
    output: path "${ref}.fai"
    script: "samtools faidx $ref"
}

process GATK_DICT {
    container 'somatic-gatk:latest'
    input: path ref
    output: path "${ref.baseName}.dict"
    script: "gatk CreateSequenceDictionary -R $ref"
}

process BWA_MEM {
    container 'somatic-bwa:latest'
    input:
        path tumor
        path ref
        path index_files
    output: path "aligned.sam"
    script: "bwa mem -R '@RG\\tID:lane1\\tLB:lib1\\tPL:illumina\\tSM:TumorSample' $ref $tumor > aligned.sam"
}

process SAMTOOLS_SORT {
    container 'somatic-samtools:latest'
    publishDir "${params.outdir}/bam", mode: 'copy'
    input: path sam
    output: path "sorted.bam", emit: bam
    script: "samtools view -Sb $sam | samtools sort -o sorted.bam && samtools index sorted.bam"
}

process MUTECT2 {
    container 'somatic-gatk:latest'
    input:
        path bam
        path ref
        path fai
        path dict
    output: path "raw_somatic.vcf.gz*", emit: vcf_bundle
    script: "gatk Mutect2 -R $ref -I $bam -O raw_somatic.vcf.gz"
}

process FILTER_VARIANTS {
    container 'somatic-gatk:latest'
    publishDir "${params.outdir}", mode: 'copy'
    input:
        path vcf_bundle
        path ref
        path fai
        path dict
    output:
        path "filtered_somatic.vcf.gz", emit: vcf
        path "filtered_somatic.vcf.gz.tbi"
    script: "gatk FilterMutectCalls -R $ref -V raw_somatic.vcf.gz -O filtered_somatic.vcf.gz"
}

process VISUALIZE_VCF {
    container 'python:3.9-slim'
    publishDir "${params.outdir}/plots", mode: 'copy'
    input: path vcf
    output: path "*.png"
    script:
    """
    pip install --target=. matplotlib
    export PYTHONPATH=".:\$PYTHONPATH"
    python3 ${baseDir}/plot_vaf.py $vcf
    """
}

workflow {
    BWA_INDEX(params.genome)
    SAMTOOLS_FAIDX(params.genome)
    GATK_DICT(params.genome)
    BWA_MEM(params.tumor_fastq, params.genome, BWA_INDEX.out)
    SAMTOOLS_SORT(BWA_MEM.out)
    MUTECT2(SAMTOOLS_SORT.out.bam, params.genome, SAMTOOLS_FAIDX.out, GATK_DICT.out)
    FILTER_VARIANTS(MUTECT2.out.vcf_bundle, params.genome, SAMTOOLS_FAIDX.out, GATK_DICT.out)
    VISUALIZE_VCF(FILTER_VARIANTS.out.vcf)
}
