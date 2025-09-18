#!/bin/bash

# get summary statistics from pipeline output

# positional parameters
## $1 = sample output directory
## $2 = sample name
## $3 = genome / assembly input

annot_out=${1}/tmp/annotation

count_contigs=$(grep ">" ${3} | wc -l)
count_bases_assembly=$(grep -v ">" ${3} | wc -c)
mv ${1}/tmp/quality_summary.tsv ${1}/${2}_checkv_summary.tsv

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
  printf "Contigs >${4} bp:\t\t${count_contigs}\n" >> ${summary}
  printf "Assembly length:\t\t${count_bases_assembly} bp\n" >> ${summary}
  printf "CheckV completeness:\t\t${cv_complete}\045\n" >> ${summary}
  printf "CheckV contamination:\t\t${cv_contam}\045\n" >> ${summary}
else
  cv_complete=$(sed -n 2p ${1}/${2}_checkv_summary.tsv | awk -F$'\t' '{print $10}')
  cv_contam=$(sed -n 2p ${1}/${2}_checkv_summary.tsv  | awk -F$'\t' '{print $12}')
  printf "Contigs >${4} bp:\t\t${count_contigs}\n" >> ${summary}
  printf "Longest contig length:\t\t${count_bases_assembly} bp\n" >> ${summary}
  printf "CheckV completeness longest contig:\t\t${cv_complete}\045\n" >> ${summary}
  printf "CheckV contamination longest contig:\t\t${cv_contam}\045\n" >> ${summary}
fi
