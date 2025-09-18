#!/bin/bash

# assemble isolate genomes using spades wrapper
# performs read trimming and subsampling

# positional parameters
## $1 = read1
## $2 = read2
## $3 = min contig length
## $4 = depth to subsample to
## $5 = Gb memory
## $6 = cpus

ml miniconda/24.11.3
conda activate /home/acv38/project/conda_envs/shovill
shovill \
  --outdir . \
  --force \
  --R1 ${1} \
  --R2 ${2} \
  --minlen ${3} \
  --mincov 10 \
  --depth ${4} \
  --ram ${5} \
  --cpus ${6} \
  --assembler spades \
  --trim
conda deactivate
