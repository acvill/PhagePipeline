#!/bin/bash

# call phage ends

# positional parameters
## $1 = read1 (not gzipped)
## $2 = read2 (not gzipped)
## $3 = contigs.fa from shovill
## $4 = sample name
## $5 = cores
## $6 = minimum contig length

module load miniconda/24.3.0
conda activate /home/acv38/project/conda_envs/phageterm_py3
/home/acv38/project/conda_envs/ptv-py3_release_1_light/PhageTerm.py \
  -f ${1} \
  -p ${2} \
  -r ${3} \
  --report_title ${4} \
  -c ${5} \
  -l ${6} \
  --nrt

bases=$(sed '/^[[:space:]]*$/d' ${4}_sequence.fasta | grep -v ">" | wc -c)
if [ "$bases" -eq "0" ]; then
  rm ${4}_sequence.fasta
  rm nrt.txt
fi

conda deactivate
