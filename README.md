# Welcome to QUARS ~ **QUA**lity control for **R**NA_**S**eq
QUARS creates a [MultiQC](http://multiqc.info) report out of the [FastQC](https://www.bioinformatics.babraham.ac.uk/projects/fastqc/) and [Fastp](https://github.com/OpenGene/fastp) results of both single and paired end RNAseq raw reads (.fq and simmilars). Powered by [Nextflow](https://www.nextflow.io)

## Typical usage
* For paired end fastq files:

`nextflow run RNAseq_QC.nf --fastq_files 'mydir/*.fastq.gz'`

  Which produces this [paired_end_MultiQC_report.html](Docs/multiqc_report_paired.html)

* For single end fastq files:

`nextflow run RNAseq_QC.nf --fastq_files 'mydir/*_{1,2}.fastq.gz' --singleEnd false`

## Arguments
  `--fastq_files`                 Absolute path to input .fastq data (must be enclosed with single quotes). If no path specified, the default behaviour is search in the current dir for the folder "Data" (_i.e._ "./Data/")
  `--singleEnd`                   Logical indicating whether the files are single ("true". This is the default beahaviour) or paired end ("false").

## Options
  `--outdir `                     Absolute path to the output data (must be enclosed in quotes). If no path specified, the default behaviour is search in the current dir for the folder "Results" (_i.e._ "./Results/"). Be sure to add the final "/" to the path.
  `--cpus`                        Integer specifying the number of cores to use. Be aware of the limits of your machine.
