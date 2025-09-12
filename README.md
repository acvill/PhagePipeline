A pipeline for assembling and annotating phage genomes. This pipeline is hard-coded to make use of the YCRC's [software modules](https://docs.ycrc.yale.edu/clusters-at-yale/applications/modules/) and [dSQ job submission system](https://docs.ycrc.yale.edu/clusters-at-yale/job-scheduling/dsq/).

```{bash}
# create an alias
echo "alias PhagePipeline='sh ~/project/shared_scripts/PhagePipeline/run_PhagePipeline.sh'" >> ~/.bashrc

# test the pipeline
PhagePipeline
```
```{bash}

  For short read assembly and annotation:
  sh run_PhagePipeline.sh -f <path> [OPTIONS]

  For annotation of an existing genome / assembly:
  sh run_PhagePipeline.sh -a <path> [OPTIONS]

  All options:

      -h    print this usage statement and exit
      -f    path to directory containing paired-end sequencing files
              Assumes filenames are structured as
              <name>_R1.fastq[.gz] and <name>_R2.fastq[.gz]
      -a    path to directory containing genomes or assemblies
              Assumes filenames are structured as
              <name>.fasta or <name>.fna or <name>.fa
      -s    optional bowtie2 index for host read removal
              Only applicable to short read assembly pipeline
              Either 'PAO1', 'PA14', or path to custom index.
              Exclude to skip host read removal.
      -o    output path
              Default: pwd
      -d    read subsampling depth for shovill assembly
              Default: 150
      -g    estimated genome size for shovill assembly
              As <integer[K,M,G]>, default: 100K
      -m    minimum contig length to keep
              Default: 1000
      -q    quoted parameter string for dSQ job array
              Must use long option names,
              default: '--partition day --mem 20g --cpus-per-task 8 --time 16:00:00'
      -k    keep all temporary / intermediate files
              Exclude to delete tmp folder

```

![](https://github.com/acvill/PhagePipeline/blob/master/pipelinev2.png)
