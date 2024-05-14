#!/bin/bash

# annotate phage genomes

# positional parameters
## $1 = contigs.fa
## $2 = outdir to be written
## $3 = threads
## $4 = sample

module load miniconda/24.3.0
conda activate /home/acv38/project/conda_envs/pharokka
pharokka.py \
  -i ${1} \
  -d /home/acv38/project/databases/pharokka/pharokka_v1.4.0_databases \
  -o ${2} \
  -t ${3} \
  -f \
  -p ${4} \
  -g phanotate
conda deactivate
