#!/bin/bash

# master script for calling assembly and annotation software

# last edited 11 Sep 2025, Albert Vill

# TO DO v2
## update all packages
## add phables assembly for short reads
## add phold v1.0, phynteny annotations

# defaults
outdir=$(pwd)
depth=100
mincontig=500
dsq_params="--partition day --mem 20g --cpus-per-task 8 --time 16:00:00"

# script paths
ppl=/home/acv38/project/shared_scripts/PhagePipeline
hostile=${ppl}/hostile.sh
shovill=${ppl}/shovill.sh
phageterm=${ppl}/phageterm.sh
checkv=${ppl}/checkv.sh
pharokka=${ppl}/pharokka.sh
phold=${ppl}/phold.sh
phynteny=${ppl}/phynteny.sh
full_summarize=${ppl}/full_summarize.sh
annotate_summarize=${ppl}/annotate_summarize.sh

# usage statement function
usage() {
  
  printf "\n
  For short read assembly and annotation:
  sh run_PhagePipeline.sh -f <path> [OPTIONS]
  
  For annotation of an existing genome / assembly:
  sh run_PhagePipeline.sh -a <path> [OPTIONS]
  
  All options:
  
      -h    print this usage statement and exit
      -f    path to directory containing paired-end sequencing files
              Assumes filenames are structured as
              <name>_R1.fastq[.gz] and <name>_R2.fastq[.gz]
      -a    path to directory containing genomes or assemblies
              Assumes filenames are structured as
              <name>.fasta or <name>.fna or <name>.fa
      -s    optional bowtie2 index for host read removal
              Only applicable to short read assembly pipeline
              Either 'PAO1', 'PA14', or path to custom index.
              Exclude to skip host read removal.
      -o    output path
              Default: pwd
      -d    read subsampling depth for shovill assembly
              Default: 100
      -m    minimum contig length to keep
              Default: 1000
      -q    quoted parameter string for dSQ job array
              Must use long option names,
              default: '--partition day --mem 20g --cpus-per-task 8 --time 16:00:00'
      -k    keep all temporary / intermediate files
              Exclude to delete tmp folder
\n"
  1>&2
  exit 0

}

# function to make log, job, and sample files
initiate() {
  
  # initiate log
  log=${outdir}/log/ppl_$(date '+%d-%m-%Y')_log.txt
  
  if [ -d "${outdir}/log" ]; then
    rm -r ${outdir}/log
    mkdir -p ${outdir}/log
    printf "${outdir}/log exists ... overwriting\n" >> ${log}
  fi
  
  mkdir -p ${outdir}/log
  
  # initiate dsq job list
  jobfile=${outdir}/log/ppl_$(date '+%d-%m-%Y')_jobs.txt
  
  if [ -f "${jobfile}" ]; then
    printf "${jobfile} exists ... overwriting\n" >> ${log}
    rm ${jobfile}
  fi
  
  # initiate and create sample list
  samplist=${outdir}/log/ppl_$(date '+%d-%m-%Y')_samples.txt
  
  if [ -f "${samplist}" ]; then
    printf "${samplist} exists ... overwriting\n" >> ${log}
    rm ${samplist}
  fi

}

# function to parse dsq parameters for available resources
parse_dsq() {
  
  memory=$(echo "${dsq_params}" | grep -Eo "\--mem [0-9]{1,4}" | awk '{print $2}')
  cpus=$(echo "${dsq_params}" | grep -Eo "\--cpus-per-task [0-9]{1,4} " | awk '{print $2}')

}

# parse options
while getopts "hf:a:s:o:d:g:m:q:k" opt; do
  case ${opt} in
    f) fastq=${OPTARG};;
    a) fasta=${OPTARG};;
    s) index=${OPTARG};;
    o) outdir=$(realpath ${OPTARG});;
    d) depth=${OPTARG};;
    m) mincontig=${OPTARG};;
    q) dsq_params=${OPTARG};;
    k) keeptemp=1;;
    h) usage
    exit 0;;
    *) usage
    exit 0;;
  esac
done

# check that either fastq xor fasta supplied
if [[ -n ${fastq} ]] && \
   [[ -n ${fasta} ]]; then
  printf "\nError: please supply either reads or assemblies, not both\n"
  exit 1
elif [[ -z ${fastq} ]] && \
     [[ -z ${fasta} ]]; then
  usage
  exit 0

# ASSEMBLY FIRST PIPELINE  
elif [[ -n ${fastq} ]]; then
  
  if [ -z  ${index} ]; then
    index=none
  elif [ -a  ${index} ]; then
    if [ "${index}" = "PAO1" ]; then
      index=/home/acv38/project/databases/masked_genomes/PAO1/PAO1
    elif [ "${index}" = "PA14" ]; then
      index=/home/acv38/project/databases/masked_genomes/PA14/PA14
    else
      index=$(realpath ${index})
    fi
  fi
  
  fq_path=$(realpath ${fastq})
  
  printf "\n######################\n"
  printf "\nStarting assembly pipeline\n"
  printf "\n######################\n"
  printf "## input fastq path  -> ${fq_path}\n"
  printf "## input index       -> ${index}\n"
  printf "## output path       -> ${outdir}\n"
  printf "## subsampling depth -> ${depth}\n"
  printf "######################\n\n"
  
  initiate
  parse_dsq
  
  # get sample list of fastq files
  ls ${fq_path} | \
    grep ".fastq" | \
    sed "s/_R[1-2].fastq.*$//g" | \
    sort | uniq \
    > ${samplist}
  printf "$(wc -l < ${samplist}) samples written to ${samplist}\n" >> ${log}
  cd ${fq_path}
  while read sample; do
    ls -d ${sample}_R[1-2].fastq.gz | \
      wc -l | sed "s/^/${sample}\t/g" | \
      grep -Pv "\t2$" | awk -F$"\t" '{print $1}' \
      >> ${outdir}/log/error_samples.txt
  done < ${samplist}
  if [ -s ${outdir}/log/error_samples.txt ]; then
    printf "ERROR: there was a problem parsing some sample names.\n"
    printf "See log/error_samples.txt for problematic samples.\n"
    exit 1
  fi
  rm ${outdir}/log/error_samples.txt
  
  while read sample; do
    # create output directory
    out=${outdir}/${sample}
    if [ -d "${out}" ]; then
      printf "${out} exists ... overwriting\n" >> ${log}
      rm -r ${out}
    fi
    
    reads_out=${out}/tmp/clean_reads
    assem_out=${out}/tmp/assembly
    annot_out=${out}/tmp/annotation
    mkdir -p ${reads_out}
    mkdir -p ${assem_out}
    mkdir -p ${annot_out}
    read1=$(find ${fq_path} -type f -iname "${sample}_R1.fastq*")
    read2=$(find ${fq_path} -type f -iname "${sample}_R2.fastq*")
    read1clean=${reads_out}/${sample}_R1.clean_1.fastq
    read2clean=${reads_out}/${sample}_R2.clean_2.fastq
    
    if [ "${index}" = "none" ]; then
      # skip hostile read cleaning
      if [[ ${read1} =~ \.gz$ ]] || [[ ${read2} =~ \.gz$ ]]; then
        run_hostile="cp ${read1} ${read1clean}.gz; cp ${read2} ${read2clean}.gz"
      else
        run_hostile="gzip -c ${read1} > ${read1clean}.gz; gzip -c ${read2} > ${read2clean}.gz"
      fi
    else
      # carry out hostile read cleaning
      run_hostile="printf '${sample} -- cleaning reads with hostile\\\n' >> ${log}; sh ${hostile} ${read1} ${read2} ${index} ${cpus}"
    fi

    run_shovill="printf '${sample} -- assembling reads with shovill\\\n' >> ${log}; sh ${shovill} ${read1clean}.gz ${read2clean}.gz ${mincontig} ${depth} ${memory} ${cpus}"
    run_phageterm="printf '${sample} -- predicting phage genome ends with PhageTerm\\\n' >> ${log}; gunzip ${read1clean}.gz ${read2clean}.gz; sh ${phageterm} ${read1clean} ${read2clean} ${assem_out}/contigs.fa ${sample} ${cpus} ${mincontig}; gzip ${read1clean} ${read2clean}"
    run_checkv="if [[ -f ${assem_out}/${sample}_sequence.fasta ]]; then printf '${sample} -- running checkv on PhageTerm-reoriented genome\\\n' >> ${log}; sh ${checkv} ${assem_out}/${sample}_sequence.fasta ${cpus}; else printf '${sample} -- running checkv on shovill assembly\\\n' >> ${log}; sh ${checkv} ${assem_out}/contigs.fa ${cpus}; fi"
    run_pharokka="if [[ -f ${assem_out}/${sample}_sequence.fasta ]]; then printf '${sample} -- annotating PhageTerm-reoriented genome with pharokka\\\n' >> ${log}; sh ${pharokka} ${assem_out}/${sample}_sequence.fasta ${annot_out} ${cpus} ${sample}; else printf '${sample} -- annotating shovill assembly with pharokka\\\n' >> ${log}; sh ${pharokka} ${assem_out}/contigs.fa ${annot_out} ${cpus} ${sample}; fi"
    run_phold="printf '${sample} -- annotating genome with phold\\\n' >> ${log}; sh ${phold} ${annot_out}/${sample}.gbk ${annot_out}/phold ${cpus} ${sample}"
    run_phynteny="printf '${sample} -- annotating genome with phynteny\\\n' >> ${log}; sh ${phynteny} ${annot_out}/phold/${sample}.gbk ${annot_out}/phynteny ${sample}"
    run_summarize="printf '${sample} -- consolidating files and generating summary statistics\\\n' >> ${log}; sh ${full_summarize} ${out} ${sample} ${read1} ${mincontig}"

    if [[ ${keeptemp} -ne 1 ]]; then
      # remove intermediate files
      run_cleanup="rm -r ${out}/tmp; printf '${sample} -- Pipeline Done!\\\n' >> ${log}"
    else
      # keep intermediate files
      run_cleanup="printf '${sample} -- Pipeline Done!\\\n' >> ${log}"
    fi

    # write job
    if [[ -f ${read1} && -f ${read2} ]]; then
      printf "cd ${reads_out}; ${run_hostile}; cd ${assem_out}; ${run_shovill}; ${run_phageterm}; ${run_checkv}; ${run_pharokka}; ${run_phold}; ${run_phynteny}; ${run_summarize}; ${run_cleanup}\n" >> ${jobfile}
      printf "${sample} -- job written to ${jobfile}\n" >> ${log}
    else
      printf "${sample} -- one or both fastq files cannot be found\n" >> ${log}
    fi

  done < ${samplist}

# ANNOTATION-ONLY PIPELINE
elif [[ -n ${fasta} ]]; then

  fa_path=$(realpath ${fasta})

  printf "\n######################\n"
  printf "\nStarting annotation pipeline\n"
  printf "\n######################\n"
  printf "## input fasta path  -> ${fa_path}\n"
  printf "## output path       -> ${outdir}\n"
  printf "######################\n\n"

  initiate
  parse_dsq
  
  # get sample list of fasta files
  ls ${fa_path} | \
   grep -iE ".fasta|.fna|.fa" | \
   sed "s/\.[^.]*$//" | \
   sort | uniq \
   > ${samplist}
  printf "$(wc -l < ${samplist}) samples written to ${samplist}\n" >> ${log}
  cd ${fa_path}
  while read sample; do
    ls -d ${sample}.{fasta,fna,fa} | \
      wc -l | sed "s/^/${sample}\t/g" | \
      grep -Pv "\t1$" | awk -F$"\t" '{print $1}' \
      >> ${outdir}/log/error_samples.txt
  done < ${samplist}
  if [ -s ${outdir}/log/error_samples.txt ]; then
    printf "ERROR: there was a problem parsing some sample names.\n"
    printf "See log/error_samples.txt for problematic samples.\n"
    exit 1
  fi
  rm ${outdir}/log/error_samples.txt
  
  while read sample; do
    # create output directory
    out=${outdir}/${sample}
    if [ -d "${out}" ]; then
      printf "${out} exists ... overwriting\n" >> ${log}
      rm -r ${out}
    fi
    
    seqin=$(ls ${fa_path} | grep "${sample}" | grep -iE ".fasta|.fna|.fa")
    
    annot_out=${out}/tmp/annotation
    mkdir -p ${annot_out}
    run_checkv="printf '${sample} -- running checkv\\\n' >> ${log}; sh ${checkv} ${fa_path}/${seqin} ${cpus}"
    run_pharokka="printf '${sample} -- annotating genome with pharokka\\\n' >> ${log}; sh ${pharokka} ${fa_path}/${seqin} ${annot_out} ${cpus} ${sample}"
    run_phold="printf '${sample} -- annotating genome with phold\\\n' >> ${log}; sh ${phold} ${annot_out}/${sample}.gbk ${annot_out}/phold ${cpus} ${sample}"
    run_phynteny="printf '${sample} -- annotating genome with phynteny\\\n' >> ${log}; sh ${phynteny} ${annot_out}/phold/${sample}.gbk ${annot_out}/phynteny ${sample}"
    run_summarize="printf '${sample} -- consolidating files and generating summary statistics\\\n' >> ${log}; sh ${annotate_summarize} ${out} ${sample} ${fa_path}/${seqin}"

    if [[ ${keeptemp} -ne 1 ]]; then
      # remove intermediate files
      run_cleanup="rm -r ${out}/tmp; printf '${sample} -- Pipeline Done!\\\n' >> ${log}"
    else
      # keep intermediate files
      run_cleanup="printf '${sample} -- Pipeline Done!\\\n' >> ${log}"
    fi

    # write job
    if [[ -f ${seqin} ]]; then
      printf "cd ${out}/tmp; ${run_checkv}; ${run_pharokka}; ${run_phold}; ${run_phynteny}; ${run_summarize}; ${run_cleanup}\n" >> ${jobfile}
      printf "${sample} -- job written to ${jobfile}\n" >> ${log}
    else
      printf "${sample} -- fasta file cannot be found\n" >> ${log}
    fi

  done < ${samplist}
  
fi

# submit job file
if [ -s ${jobfile} ]; then
  module load dSQ
  cd ${outdir}/log
  dSQ --submit \
    --job-file ${jobfile} \
    --status-dir ${outdir}/log \
    ${dsq_params}
else
  printf "dSQ job file is empty\n" >> ${log}
  exit 1
fi

printf "\n######################\n"
printf "to monitor progress, see ${log}\n"
printf "######################\n\n"
