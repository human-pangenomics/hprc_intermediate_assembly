###############################################################################
##                                    CHM13 v2.0                             ##
###############################################################################

mkdir -p /private/groups/hprc/ref_files/chm13


## reference
aws s3 cp \
    s3://human-pangenomics/T2T/CHM13/assemblies/chm13v2.0.fa \
    /private/groups/hprc/ref_files/chm13/

pigz -p 8 /private/groups/hprc/ref_files/chm13/chm13v2.0.fa


## annotationBed
aws s3 cp \
    s3://human-pangenomics/T2T/CHM13/assemblies/annotation/chm13v2.0_GenomeFeature_v1.0.bed \
    /private/groups/hprc/ref_files/chm13/

## annotationCENSAT
aws s3 cp \
    s3://human-pangenomics/T2T/CHM13/assemblies/annotation/chm13v2.0_censat_v2.0.bed \
    /private/groups/hprc/ref_files/chm13/

## annotationSD
gsutil cp \
    gs://fc-5e531b40-db4b-4522-b4a6-99295c647c25/ref_files/chm13v2.0_SD.flattened.bed \
    /private/groups/hprc/ref_files/chm13/


###############################################################################
##                                   GRCh38                                  ##
###############################################################################

mkdir -p /private/groups/hprc/ref_files/grch38


## genesFasta
gsutil cp \
    gs://hifiasm/Homo_sapiens.GRCh38.cdna.all.fa \
    /private/groups/hprc/ref_files/grch38/

## hs38Paf
gsutil cp \
    gs://hifiasm/hs38.paf \
    /private/groups/hprc/ref_files/grch38/

gsutil cp \
    gs://hifiasm/hs38DH.fa \
    /private/groups/hprc/ref_files/grch38/

## GIAB version with chr names
cd /private/groups/hprc/ref_files/grch38
wget https://ftp-trace.ncbi.nlm.nih.gov/ReferenceSamples/giab/release/references/GRCh38/GCA_000001405.15_GRCh38_no_alt_analysis_set.fasta.gz
gunzip /private/groups/hprc/ref_files/grch38/GCA_000001405.15_GRCh38_no_alt_analysis_set.fasta.gz
samtools faidx /private/groups/hprc/ref_files/grch38/GCA_000001405.15_GRCh38_no_alt_analysis_set.fasta

###############################################################################
##                              GIAB bed files                              ##
###############################################################################

mkdir -p /private/groups/hprc/ref_files/giab

cd /private/groups/hprc/ref_files/giab

wget https://ftp-trace.ncbi.nlm.nih.gov/ReferenceSamples/giab/release/AshkenazimTrio/HG002_NA24385_son/NISTv4.2.1/GRCh38/HG002_GRCh38_1_22_v4.2.1_benchmark_noinconsistent.bed

wget https://ftp-trace.ncbi.nlm.nih.gov/ReferenceSamples/giab/release/ChineseTrio/HG005_NA24631_son/NISTv4.2.1/GRCh38/HG005_GRCh38_1_22_v4.2.1_benchmark.bed

bedtools intersect \
-a /private/groups/hprc/ref_files/giab/HG002_GRCh38_1_22_v4.2.1_benchmark_noinconsistent.bed \
-b /private/groups/hprc/ref_files/giab/HG005_GRCh38_1_22_v4.2.1_benchmark.bed \
> /private/groups/hprc/ref_files/giab/HG002_intersect_HG005_GIAB_v4.2.1.bed

bedtools sort -faidx /private/groups/hprc/ref_files/grch38/GCA_000001405.15_GRCh38_no_alt_analysis_set.fasta.fai \
-i /private/groups/hprc/ref_files/giab/HG002_intersect_HG005_GIAB_v4.2.1.bed \
> tmp ; mv tmp /private/groups/hprc/ref_files/giab/HG002_intersect_HG005_GIAB_v4.2.1.bed

cut -f1-2 /private/groups/hprc/ref_files/grch38/GCA_000001405.15_GRCh38_no_alt_analysis_set.fasta.fai \
> /private/groups/hprc/ref_files/grch38/GCA_000001405.15_GRCh38_no_alt_analysis_set.fasta.fai.genome

bedtools complement \
-i /private/groups/hprc/ref_files/giab/HG002_intersect_HG005_GIAB_v4.2.1.bed \
-g /private/groups/hprc/ref_files/grch38/GCA_000001405.15_GRCh38_no_alt_analysis_set.fasta.fai.genome \
> /private/groups/hprc/ref_files/giab/outside_HG002_intersect_HG005_GIAB_v4.2.1.bed


###############################################################################
##                           Yak Files For Sex Chromosomes                   ##
###############################################################################

mkdir -p /private/groups/hprc/ref_files/yak

wget -O- 'https://zenodo.org/record/7882299/files/human-chrXY-yak.tar?download=1' \
    | tar xf - -C /private/groups/hprc/ref_files/yak

    