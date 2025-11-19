This is a pipeline for assembling and annotating phage genomes. This pipeline is hard-coded to make use of the YCRC's [software modules](https://docs.ycrc.yale.edu/clusters-at-yale/applications/modules/) and [dSQ job submission system](https://docs.ycrc.yale.edu/clusters-at-yale/job-scheduling/dsq/). 

### Calling the script
You can call the script directly by giving the full path: 
```{bash}
# on McCleary
sh /gpfs/gibbs/project/turner/acv38/shared_scripts/PhagePipeline/run_PhagePipeline.sh

# on Bouchet
sh /nfs/roberts/project/pi_pet3/shared/PhagePipeline/run_PhagePipeline.sh
```
Or you can create an alias in your shell configuration file:
```{bash}
# on McCleary
echo "alias PhagePipeline='sh /gpfs/gibbs/project/turner/acv38/shared_scripts/PhagePipeline/run_PhagePipeline.sh'" >> ~/.bashrc
source ~/.bashrc
PhagePipeline

# on Bouchet
echo "alias PhagePipeline='sh /nfs/roberts/project/pi_pet3/shared/PhagePipeline/run_PhagePipeline.sh'" >> ~/.bashrc
source ~/.bashrc
PhagePipeline
```
### Options
```{bash}

  For short read assembly and annotation:
  PhagePipeline -f <path> [OPTIONS]

  For annotation of an existing genome / assembly:
  PhagePipeline -a <path> [OPTIONS]

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
              Default: 100
      -m    minimum contig length to keep
              Default: 1000
      -q    quoted parameter string for dSQ job array
              Must use long option names,
              default: '--partition day --mem 20g --cpus-per-task 8 --time 16:00:00'
      -k    keep all temporary / intermediate files
              Exclude to delete tmp folder

```

![](https://github.com/acvill/PhagePipeline/blob/master/pipelinev2.png)
