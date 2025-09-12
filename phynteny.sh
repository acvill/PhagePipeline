#!/bin/bash

# annotate phage genomes with phynteny

# positional parameters
## $1 = genbank file from phold
## $2 = outdir to be written
## $3 = sample

ml miniconda/24.11.3
conda activate /home/acv38/project/conda_envs/phynteny_transformer
phynteny_transformer \
  -m /home/acv38/turner_data/db/phynteny_transformer/models \
  -o ${2} \
  -f \
  --prefix ${3} \
  ${1}
conda deactivate
