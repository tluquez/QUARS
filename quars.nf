#!/usr/bin/env nextflow

/*
vim: syntax=groovy
-*- mode: groovy;-*-

MIT License

Copyright (c) [2018] [Grupo de Investigación en Terapia Celular y Molecular from the Pontificia Universidad Javeriana and Tain Velasco-Luquez]

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

/*
Author:
Tain Velasco-Luquez <tvelasco@javeriana.edu.co> @TainVelasco-Luquez: Design and implementation.
Caution note: This code is heavily influenced by NGI-RNAseq by Phil Ewels.
*/

/*
Params.arg can be supplied when running the command, and automatically replace the default ones, by ussing the format: --arg value (e.g. nextflow run file.nf --fastq_files '/home/tain/')
*/

params.fastq_files = './Data/*_{1,2}.fastq'
params.outdir = './Results/'
params.singleEnd = true
params.cpus = 6

def usage() {
    log.info"""

    ============================================================================
              QUARS ~ QUAlity control for RNA_Seq, a nextflow pipeline
    ============================================================================

    Description:
    QUARS creates a MultiQC report out of the FastQC and Fastp results of both single and paired end RNAseq reads. It also saves the Fastp cleaned files to a new dir as .fq.gz.

    Typical usage:
    nextflow run quars.nf --fastq_files 'mydir/*_{1,2}.fastq.gz' --singleEnd false

    nextflow run quars.nf --fastq_files 'mydir/*.fastq.gz'

    Mandatory arguments:
      --fastq_files                 Absolute path to input .fastq data (must be enclosed with single quotes). If no path specified, the default behaviour is search in the current dir for the folder "Data" (i.e. "./Data/")
      --singleEnd                   Logical indicating whether the files are single ("true". This is the default beahaviour) or paired end ("false").

    Options:
      --outdir                      Absolute path to the output data (must be enclosed in quotes). If no path specified, the default behaviour is search in the current dir for the folder "Results" (i.e. "./Results/"). Be sure to add the final "/" to the path.
      --cpus                        Integer specifying the number of cores to use. Be aware of the limits of your machine.
      -profile condor               Used when in a cluster with the HTCondor executor. For configuration of the HTCondor parameters go to nextflow.config and change the required settings.
    """.stripIndent()
}

// Show help message
params.help = false
if (params.help){
    usage()
    exit 0
}

/*
* Step 1: Fastp
*/

// The channel takes all files matching the glob *_{1,2}.fastq and assigns them the attribute size equal to 1 or 2 dependeng on whether they are the forward (1) or the reverse (2). The channel then emmits each set of 1 and 2 files through files_QC_ch
Channel
.fromFilePairs( params.fastq_files, size: params.singleEnd ? 1 : 2 )
.ifEmpty { error "Cannot find any reads matching: ${params.fastq_files}" }
.set { files_QC_ch }

println ("\n Fastp is about to run... \n")

process fastp {

  tag { fastp_tag }

  // The files ending in *.html are saved to the specified output dir inside a new folder called fastp.
  publishDir pattern: "*.html",  path: { params.outdir + "fastp/" }, mode: 'copy'

  publishDir pattern: "*_fastp.fastq.gz",  path: { params.outdir + "cleaned_files/" }, mode: 'copy'

  input:
  set val(samplename), file(fastq_file) from files_QC_ch

  output:
  //Inasmuch as multiQC (the last step of this pipeline) only supports the .json files from fastp, only these files are kept for following analyses while the .html are publised to the specified dir
  file('*.json') into fastp_results_ch
  set file('*.html'), file('*_fastp.fastq.gz')

  shell:
  // Tag the process with the samplename
  fastp_tag = samplename

  if (params.singleEnd == true) {
    """
    fastp -p -w ${params.cpus} --dont_overwrite -i ${fastq_file[0]} -o ${samplename}_fastp.fastq.gz -h ${samplename}_fastp.html -j ${samplename}_fastp.json
    """
    } else {
      """
      fastp -p -w ${params.cpus} --dont_overwrite -i ${fastq_file[0]} -I ${fastq_file[1]} -o ${samplename}_1_fastp.fastq.gz -O ${samplename}_2_fastp.fastq.gz -h ${samplename}_fastp.html -j ${samplename}_fastp.json
      """
    }
  }

  /*
  * Step 2: fastQC
  */

  // A new channel must be created for fastQC, exactly as for fastp
  Channel
  .fromFilePairs( params.fastq_files, size: params.singleEnd ? 1 : 2 )
  .ifEmpty { error "Cannot find any reads matching: ${params.fastq_files}" }
  .set { files_QC_2_ch }

println ("\n fastQC is about to run... \n")

process fastQC {
    tag { fastqc_tag }

    //Publish only the .html output while the .zip is stored for use with multiqc
    publishDir pattern: "*.html", path: { params.outdir + "fastQC/" }, mode: 'copy'

    input:
    set val(samplename), file(fastq_file) from files_QC_2_ch

    output:
    file('*.zip') into fastqc_results_ch
    file('*.html')

    script:
    fastqc_tag = samplename

    if (params.singleEnd == true) {
      """
      fastqc -t ${params.cpus} --noextract -q ${fastq_file}
      """
      } else {
        """
        fastqc -t ${params.cpus} --noextract -q ${fastq_file[0]} ${fastq_file[1]}
        """
      }
    }

    /*
    * Step 3: MultiQC
    */
    /*
    * This step has the code structure from https://github.com/SciLifeLab/NGI-RNAseq/blob/master/main.nf all credit is for its authors.
    */

    println ("\n mutiQC is about to run... \n")

    process multiQC {

      publishDir pattern: "*multiqc_report.html", path: { params.outdir + "multiQC/" }, mode: 'copy'

      input:
      file ('fastQC/*') from fastqc_results_ch.collect()
      file ('fastp/*') from fastp_results_ch.collect()

      output:
      file('*multiqc_report.html')

      script:
      """
      multiqc . -f -m fastqc -m fastp
      """
    }

    workflow.onComplete {
      println "\n Pipeline completed at: $workflow.complete"
      println "\n Execution status: ${ workflow.success ? 'OK' : 'failed' }"
    }
