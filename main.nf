nextflow.enable.dsl=2

params.tumor_fastq = "${baseDir}/data/fastq/tumor.fastq.gz"
params.genome = "${baseDir}/data/ref/genome.fa"
params.outdir = "results"

workflow {
    tumor_ch = Channel.fromPath(params.tumor_fastq, checkIfExists: true)
    ref_ch = Channel.fromPath(params.genome, checkIfExists: true)

    BWA_INDEX(ref_ch)
    SAMTOOLS_FAIDX(ref_ch)
    GATK_DICT(ref_ch)

    all_ref_files = ref_ch
        .combine(BWA_INDEX.out)
        .combine(SAMTOOLS_FAIDX.out)
        .combine(GATK_DICT.out)

    BWA_MEM(tumor_ch, all_ref_files)
    SAMTOOLS_SORT(BWA_MEM.out.bam)
    MUTECT2(SAMTOOLS_SORT.out.bam, all_ref_files)
    FILTER_VARIANTS(MUTECT2.out.vcf_bundle, all_ref_files)
}

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
    path all_ref
    output: path "aligned.bam", emit: bam
    script:
    """
    bwa mem -R '@RG\\tID:lane1\\tLB:lib1\\tPL:illumina\\tSM:TumorSample' ${all_ref[0]} $tumor > aligned.bam
    """
}

process SAMTOOLS_SORT {
    container 'somatic-samtools:latest'
    input: path bam
    output: path "sorted.bam", emit: bam
    script:
    """
    samtools sort -o sorted.bam $bam
    samtools index sorted.bam
    """
}

process MUTECT2 {
    container 'somatic-gatk:latest'
    input: 
    path bam
    path all_ref
    output: 
    path "raw_somatic.vcf.gz*", emit: vcf_bundle
    path "raw_somatic.vcf.gz.stats", emit: stats
    script:
    """
    gatk Mutect2 -R ${all_ref[0]} -I $bam -O raw_somatic.vcf.gz
    """
}

process FILTER_VARIANTS {
    container 'somatic-gatk:latest'
    publishDir "${params.outdir}", mode: 'copy'
    input: 
    path vcf_bundle
    path all_ref
    output: 
    path "filtered_somatic.vcf.gz*"
    script:
    """
    gatk FilterMutectCalls -R ${all_ref[0]} -V raw_somatic.vcf.gz -O filtered_somatic.vcf.gz
    """
}
