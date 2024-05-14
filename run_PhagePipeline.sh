#!/bin/bash

# master script for calling assembly and annotation software

# defaults
outdir=$(pwd)
depth=150
gsize=100K
mincontig=1000
dsq_params="--partition scavenge --requeue --mem 20g --cpus-per-task 8 --time 6:00:00"

# script paths
ppl=/home/acv38/project/shared_scripts/PhagePipeline
hostile=${ppl}/hostile.sh
shovill=${ppl}/shovill.sh
phageterm=${ppl}/phageterm.sh
checkv=${ppl}/checkv.sh
pharokka=${ppl}/pharokka.sh
summarize=${ppl}/summarize.sh

# usage statement
usage() {
  printf "\n  Usage:
  sh run_PhagePipeline.sh -f <dir> -s <file> [-o,-d,-g,-m,-q,-k]
      -h    print this usage statement and exit
      -f    REQUIRED - path containing paired-end sequencing files
              Assumes filenames are structured as
              <name>_R1.fastq[.gz] and <name>_R2.fastq[.gz]
      -s    REQUIRED - bowtie2 index for host read removal
              (either 'PAO1', 'PA14', or path to custom index)
      -o    output path
              (default: pwd)
      -d    read subsampling depth for shovill assembly
              (default: 150)
      -g    estimated genome size for shovill assembly
              (as <integer[K,M,G]>, default: 100K)
      -m    minimum contig length to keep
              (default: 1000)
      -q    quoted parameter string for dSQ job array
              Must use long option names
              (default: '--partition scavenge --requeue --mem 20g --cpus-per-task 8 --time 6:00:00')
      -k    keep all temporary / intermediate files
              (exclude to delete tmp folder)
\n"
  1>&2
  exit 0
}

# parse options
while getopts "hf:s:o:d:g:m:q:k" opt; do
  case ${opt} in
    f) fastq=$(realpath ${OPTARG});;
    s) index=${OPTARG};;
    o) outdir=$(realpath ${OPTARG});;
    d) depth=${OPTARG};;
    g) gsize=${OPTARG};;
    m) mincontig=${OPTARG};;
    q) dsq_params=${OPTARG};;
    k) keeptemp=1;;
    h) usage
    exit 0;;
    *) usage
    exit 0;;
  esac
done

# check for required inputs
if [[ -z ${fastq} ]] || \
   [[ -z ${index} ]]; then
  usage
  exit 0
else
  if [ "${index}" = "PAO1" ]; then
    index=/home/acv38/project/databases/masked_genomes/PAO1/PAO1
  elif [ "${index}" = "PA14" ]; then
    index=/home/acv38/project/databases/masked_genomes/PA14/PA14
  else
    index=$(realpath ${index})
  fi
  printf "\n######################\n"
  printf "## input fastq path  -> ${fastq}\n"
  printf "## input index       -> ${index}\n"
  printf "## output path       -> ${outdir}\n"
  printf "## subsampling depth -> ${depth}\n"
  printf "## genome size       -> ${gsize}\n"
  printf "######################\n\n"
fi

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

# create sample list and check fastqs
samplist=${outdir}/log/ppl_$(date '+%d-%m-%Y')_samples.txt
if [ -f "${samplist}" ]; then
  printf "${samplist} exists ... overwriting\n" >> ${log}
  rm ${samplist}
else
  ls ${fastq} | \
    grep ".fastq" | \
    sed "s/_R[1-2].fastq.*$//g" | \
    sort | uniq \
    > ${samplist}
  printf "$(wc -l < ${samplist}) samples written to ${samplist}\n" >> ${log}
fi
cd ${fastq}
while read sample; do
  ls -d ${sample}* | \
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

# parse dsq parameters for available resources
memory=$(echo "${dsq_params}" | grep -Eo "\--mem [0-9]{1,4}" | awk '{print $2}')
cpus=$(echo "${dsq_params}" | grep -Eo "\--cpus-per-task [0-9]{1,4} " | awk '{print $2}')

# loop through sample list to build job file
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
  read1=$(find ${fastq} -type f -iname "${sample}_R1.fastq*")
  read2=$(find ${fastq} -type f -iname "${sample}_R2.fastq*")
  read1clean=${reads_out}/${sample}_R1.clean_1.fastq
  read2clean=${reads_out}/${sample}_R2.clean_2.fastq

  # generate subcommands
  run_hostile="printf '${sample} -- cleaning reads with hostile\\\n' >> ${log}; sh ${hostile} ${read1} ${read2} ${index} ${cpus}"
  run_shovill="printf '${sample} -- assembling reads with shovill\\\n' >> ${log}; sh ${shovill} ${read1clean}.gz ${read2clean}.gz ${mincontig} ${depth} ${gsize} ${memory} ${cpus}"
  run_phageterm="printf '${sample} -- predicting phage genome ends with PhageTerm\\\n' >> ${log}; gunzip ${read1clean}.gz ${read2clean}.gz; sh ${phageterm} ${read1clean} ${read2clean} ${assem_out}/contigs.fa ${sample} ${cpus} ${mincontig}; gzip ${read1clean} ${read2clean}"
  run_checkv="if [[ -f ${assem_out}/${sample}_sequence.fasta ]]; then printf '${sample} -- running checkv on PhageTerm-reoriented genome\\\n' >> ${log}; sh ${checkv} ${assem_out}/${sample}_sequence.fasta ${cpus}; else printf '${sample} -- running checkv on shovill assembly\\\n' >> ${log}; sh ${checkv} ${assem_out}/contigs.fa ${cpus}; fi"
  run_pharokka="if [[ -f ${assem_out}/${sample}_sequence.fasta ]]; then printf '${sample} -- annotating PhageTerm-reoriented genome with pharokka\\\n' >> ${log}; sh ${pharokka} ${assem_out}/${sample}_sequence.fasta ${annot_out} ${cpus} ${sample}; else printf '${sample} -- annotating shovill assembly with pharokka\\\n' >> ${log}; sh ${pharokka} ${assem_out}/contigs.fa ${annot_out} ${cpus} ${sample}; fi"
  run_summarize="printf '${sample} -- consolidating files and generating summary statistics\\\n' >> ${log}; sh ${summarize} ${out} ${sample} ${read1} ${mincontig}"
  if [[ ${keeptemp} -ne 1 ]]; then
    # remove intermediate files
    run_cleanup="rm -r ${out}/tmp; printf '${sample} -- Pipeline Done!\\\n' >> ${log}"
  else
    # keep intermediate files
    run_cleanup="printf '${sample} -- Pipeline Done!\\\n' >> ${log}"
  fi

  # write job
  if [[ -f ${read1} && -f ${read2} ]]; then
    printf "cd ${reads_out}; ${run_hostile}; cd ${assem_out}; ${run_shovill}; ${run_phageterm}; ${run_checkv}; ${run_pharokka}; ${run_summarize}; ${run_cleanup}\n" >> ${jobfile}
    printf "${sample} -- job written to ${jobfile}\n" >> ${log}
  else
    printf "${sample} -- one or both fastq files cannot be found\n" >> ${log}
  fi

done < ${samplist}

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
