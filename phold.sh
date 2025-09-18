#!/bin/bash

# annotate phage genomes with phold

# positional parameters
## $1 = genbank file from pharokka
## $2 = outdir to be written
## $3 = threads
## $4 = sample

ml miniconda/24.11.3
conda activate /home/acv38/project/conda_envs/phold
phold run \
  -i ${1} \
  -d /home/acv38/turner_data/db/phold \
  -o ${2} \
  -t ${3} \
  -f \
  -p ${4} \
  --cpu \
  --ultra_sensitive
conda deactivate
