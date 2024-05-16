A pipeline for assembling and annotating phage genomes. This pipeline is hard-coded to make use of the YCRC's [software modules](https://docs.ycrc.yale.edu/clusters-at-yale/applications/modules/) and [dSQ job submission system](https://docs.ycrc.yale.edu/clusters-at-yale/job-scheduling/dsq/).

```{bash}
  Usage:
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
```

![](https://github.com/acvill/PhagePipeline/assets/22378512/733872e3-7f00-428a-b444-9c78de050d01)
