#!/bin/bash

# get summary statistics from pipeline output

# positional parameters
## $1 = sample output directory
## $2 = sample name
## $3 = raw read1
## $4 = minimum contig length

reads_out=${1}/tmp/clean_reads
assem_out=${1}/tmp/assembly
annot_out=${1}/tmp/annotation

# reads - consolidate and count
mv ${reads_out}/${2}_R1.clean_1.fastq.gz ${1}/${2}_clean_R1.fastq.gz
mv ${reads_out}/${2}_R2.clean_2.fastq.gz ${1}/${2}_clean_R2.fastq.gz
count_reads_raw=$(echo $(zcat ${3} | wc -l)/4 | bc)
count_reads_clean=$(echo $(zcat ${1}/${2}_clean_R1.fastq.gz | wc -l)/4 | bc)

# assemblies - consolidate and summarize
if [ -s ${assem_out}/${2}_sequence.fasta ]; then
  # if phageterm gave output
  mv ${assem_out}/${2}_sequence.fasta ${1}/${2}.fasta
  mv ${assem_out}/${2}_PhageTerm_report.pdf ${1}/
  endtype=$(cat ${assem_out}/nrt.txt)
  if [ "${endtype}" = "-" ] || [ -z "${endtype}" ]; then
    endtype="not determined"
  fi
else
  # if phageterm did not give output
  mv ${assem_out}/contigs.fa ${1}/${2}.fasta
  endtype="not determined"
fi

count_contigs=$(grep ">" ${1}/${2}.fasta | wc -l)
count_bases_assembly=$(grep -v ">" ${1}/${2}.fasta | wc -c)
mv ${assem_out}/quality_summary.tsv ${1}/${2}_checkv_summary.tsv

mv ${annot_out}/${2}.gbk ${1}/${2}_pharokka.gbk
mv ${annot_out}/phold/${2}.gbk ${1}/${2}_phold.gbk
mv ${annot_out}/phynteny/phynteny.gbk ${1}/${2}_phynteny.gbk

mv ${annot_out}/${2}.gff ${1}/${2}_pharokka.gff
mv ${annot_out}/${2}.tbl ${1}/${2}_pharokka.tbl
mv ${annot_out}/${2}_cds_functions.tsv ${1}/${2}_pharokka_cds_functions.tsv
mv ${annot_out}/phold/${2}_all_cds_functions.tsv ${1}/${2}_phold_cds_functions.tsv
mv ${annot_out}/phynteny/phynteny.tsv ${1}/${2}_phynteny.tsv

summary=${1}/${2}_pipeline_summary.txt
# if assembly is a single contig
if [ "${count_contigs}" = 1 ]; then
  cv_complete=$(sed -n 2p ${1}/${2}_checkv_summary.tsv | awk -F$'\t' '{print $10}')
  cv_contam=$(sed -n 2p ${1}/${2}_checkv_summary.tsv  | awk -F$'\t' '{print $12}')
  printf "Raw read pairs in:\t\t${count_reads_raw}\n" >> ${summary}
  printf "Clean read pairs out:\t\t${count_reads_clean}\n" >> ${summary}
  printf "Contigs >${4} bp:\t\t${count_contigs}\n" >> ${summary}
  printf "Assembly length:\t\t${count_bases_assembly} bp\n" >> ${summary}
  printf "Genome ends:\t\t\t${endtype}\n" >> ${summary}
  printf "CheckV completeness:\t\t${cv_complete}\045\n" >> ${summary}
  printf "CheckV contamination:\t\t${cv_contam}\045\n" >> ${summary}
else
  cv_complete=$(sed -n 2p ${1}/${2}_checkv_summary.tsv | awk -F$'\t' '{print $10}')
  cv_contam=$(sed -n 2p ${1}/${2}_checkv_summary.tsv  | awk -F$'\t' '{print $12}')
  printf "Raw read pairs in:\t\t${count_reads_raw}\n" >> ${summary}
  printf "Clean read pairs out:\t\t${count_reads_clean}\n" >> ${summary}
  printf "Contigs >${4} bp:\t\t${count_contigs}\n" >> ${summary}
  printf "Longest contig length:\t\t${count_bases_assembly} bp\n" >> ${summary}
  printf "Genome ends:\t\t\t${endtype}\n" >> ${summary}
  printf "CheckV completeness longest contig:\t\t${cv_complete}\045\n" >> ${summary}
  printf "CheckV contamination longest contig:\t\t${cv_contam}\045\n" >> ${summary}
fi
