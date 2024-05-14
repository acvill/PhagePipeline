#!/bin/bash

# assemble isolate genomes using spades wrapper
# performs read trimming and subsampling

# positional parameters
## $1 = read1
## $2 = read2
## $3 = depth to subsample to
## $4 = estimated genome size
## $5 = Gb memory
## $6 = cpus

module load miniconda/24.3.0
conda activate /home/acv38/project/conda_envs/shovill
shovill \
  --outdir . \
  --force \
  --R1 ${1} \
  --R2 ${2} \
  --minlen ${3} \
  --mincov 10 \
  --depth ${4} \
  --gsize ${5} \
  --ram ${6} \
  --cpus ${7} \
  --assembler spades \
  --trim
conda deactivate
