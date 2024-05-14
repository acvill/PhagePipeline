#!/bin/bash

# remove host reads using hostile
# uses masked genomes

# positional parameters
## $1 = read1
## $2 = read2
## $3 = bowtie2 index
## $4 = threads

module load miniconda/24.3.0
conda activate /home/acv38/project/conda_envs/hostile
hostile clean \
  --fastq1 ${1} \
  --fastq2 ${2} \
  --aligner bowtie2 \
  --index ${3} \
  --out-dir . \
  --threads ${4}
conda deactivate
