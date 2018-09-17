# Welcome to QUARS ~ **QUA**lity control for **R**na_**S**eq
QUARS creates a [MultiQC](http://multiqc.info) report out of the [FastQC](https://www.bioinformatics.babraham.ac.uk/projects/fastqc/) and [Fastp](https://github.com/OpenGene/fastp) results of both single and paired end RNAseq raw reads (.fq and simmilars). Powered by [Nextflow](https://www.nextflow.io).

## Motivation
If like me, you have waited several hours or days for some RNAseq pipelines to finish, just to realise that the initial quality control step required further trimming! or simply that my raw reads were so bad they need to be excluded from further analysis. Then, like me, you will enjoy QUARS.

QUARS is an attemp to:
1. Make **only** quality control for RNAseq raw reads, before the big steps of annotation quantification and differential expression.
2. Run in a parallel/threating environment a quality control test for RNAseq.

## Getting Started
So you have decided to use QUARS, here is what you'll need

### Prerequisites
QUARS builds upon
- Nextflow (< version 0.30.2 build 4867).

And supported for now,
- fastp (< 0.18.0)
- fastQC (< v0.11.7)
- multiQC (< v1.6.dev0)

In future releases, Docker will simplify your use of QUARS, as there will no longer be necessary downloading individual packages (*e.g.* FastQC). Only [Nextflow](https://www.nextflow.io) and [Docker](https://www.docker.com) will be required.

### Installation
Integration with [Docker](https://www.docker.com) is in progress.

Thanks to nextflow, installation is not a must, you just have to call it from command line as (QUARS attemps to fetch `.fastq`data in `./Data`):

    nextflow run TainVelasco-Luquez/QUARS --fastq_files 'mydir/*.fastq.gz' --cpus 16
or

    nextflow run https://github.com/TainVelasco-Luquez/QUARS  --fastq_files 'mydir/*.fastq.gz' --cpus 16

Alternatively you can clone the repo and run it locally by

    git clone https://github.com/TainVelasco-Luquez/QUARS
    nextflow run QUARS/quars.nf  --fastq_files 'mydir/*.fastq.gz' --cpus 16

If you are running on a cluster with [HTCondor](https://research.cs.wisc.edu/htcondor/):

    nextflow run TainVelasco-Luquez/QUARS --fastq_files 'mydir/*.fastq.gz' --cpus 16 -profile condor

To modify memory, cpus and more options when running in clusters, go to [nextflow.config](https://github.com/TainVelasco-Luquez/QUARS/nextflow.config).

### Typical usage
* For single end fastq files:

      nextflow run QUARS --fastq_files 'mydir/*.fastq.gz' --cpus 16

  Which produces this [multiqc_report_single.html](https://cdn.rawgit.com/TainVelasco-Luquez/QUARS/0d06a9b1/Docs/multiqc_report_single.html)

* For paired end fastq files:

      nextflow run QUARS --fastq_files 'mydir/*_{1,2}.fastq.gz' --singleEnd false --cpus 16

  Which produces this [multiqc_report_paired.html](https://cdn.rawgit.com/TainVelasco-Luquez/QUARS/cb82bb28/Docs/multiqc_report_paired.html)

#### Arguments
  - `--fastq_files`                 Absolute path to input .fastq data (must be enclosed with single quotes). If no path specified, the default behaviour is search in the current dir for the folder "Data" (_i.e._ "./Data/")
  - `--singleEnd`                   Logical indicating whether the files are single ("true". This is the default beahaviour) or paired end ("false").

#### Options
  - `--outdir `                     Absolute path to the output data (must be enclosed in quotes). If no path specified, the default behaviour is to create in the current dir the folder "Results" (_i.e._ "./Results/").
  - `--cpus`                        Integer specifying the number of cores to use. Be aware of the limits of your machine.
  - `-profile condor`               Used when in a cluster with the HTCondor executor. For configuration of the HTCondor parameters go to `nextflow.config` and change the required settings.

#### Getting Help

    nextflow run QUARS --help
or

    nextflow quars.nf --help

## Credits
@TainVelasco-Luquez
QUARS is heavily influenced by the [NGI-RNAseq](https://github.com/SciLifeLab/NGI-RNAseq) pipeline, whose author, @ewels solved questions and provide ideas through his code.
This work was developed for the [Grupo de Investigación en Terapia Celular y Molecular](http://ciencias.javeriana.edu.co/departamentos-instituto/nutricion-bioquimica/investigacion) from the Pontificia Universidad Javeriana.

## Licence
This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details
