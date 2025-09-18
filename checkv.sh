#!/bin/bash

# evaluate phage assemblies

# positional parameters
## $1 = contigs
## $2 = threads

ml miniconda/24.11.3
conda activate /home/acv38/project/conda_envs/checkv
checkv end_to_end \
  ${1} \
  . \
  -d /home/acv38/turner_data/db/checkv/checkv-db-v1.5 \
  --remove_tmp \
  -t ${2} \
  --restart
conda deactivate
