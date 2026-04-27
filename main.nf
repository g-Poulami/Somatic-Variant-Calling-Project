nextflow.enable.dsl=2

// Parameters
params.genome = "${launchDir}/data/ref/genome.fa"
params.tumor_fastq = "${launchDir}/data/fastq/tumor.fastq.gz"
params.outdir = "${launchDir}/results"

// Import processes if they are in separate files, 
// or define them here if you are using a single-file script.

/* ... [Your existing processes: BWA_INDEX, SAMTOOLS_FAIDX, GATK_DICT, 
        BWA_MEM, SAMTOOLS_SORT, MUTECT2, FILTER_VARIANTS] ...
*/

process VISUALIZE_VCF {
    container 'python:3.9-slim'
    publishDir "${params.outdir}/plots", mode: 'copy'

    input: 
    path vcf  // <--- Make sure this is 'vcf'

    output: 
    path "*.png"

    script:
    """
    # Use single quotes for the export to prevent Nextflow from evaluating the variable
    export PYTHONPATH='./.local/lib/python3.9/site-packages'
    pip install --target=./.local/lib/python3.9/site-packages matplotlib
    
    python3 ${baseDir}/plot_vaf.py $vcf
    """
}

workflow {
    // 1. Prepare Reference
    BWA_INDEX(params.genome)
    SAMTOOLS_FAIDX(params.genome)
    GATK_DICT(params.genome)

    // 2. Alignment & Processing
    BWA_MEM(params.genome, params.tumor_fastq, BWA_INDEX.out)
    SAMTOOLS_SORT(BWA_MEM.out)

    // 3. Variant Calling
    MUTECT2(params.genome, SAMTOOLS_SORT.out, SAMTOOLS_FAIDX.out, GATK_DICT.out)
    
    // 4. Filtering
    FILTER_VARIANTS(params.genome, MUTECT2.out, SAMTOOLS_FAIDX.out, GATK_DICT.out)

    // 5. Visualization (The new step!)
    VISUALIZE_VCF(FILTER_VARIANTS.out)
}
