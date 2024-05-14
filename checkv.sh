#!/bin/bash

# evaluate phage assemblies

# positional parameters
## $1 = contigs
## $2 = threads

module load miniconda/24.3.0
conda activate /home/acv38/project/conda_envs/checkv
checkv end_to_end \
  ${1} \
  . \
  -d /home/acv38/project/databases/checkv/checkv-db-v1.5 \
  --remove_tmp \
  -t ${2} \
  --restart
conda deactivate
