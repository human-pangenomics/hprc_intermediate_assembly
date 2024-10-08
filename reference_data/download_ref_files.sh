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

## PARs
aws s3 cp \
    s3://human-pangenomics/T2T/CHM13/assemblies/analysis_set/chm13v2.0_PAR.bed \
    /private/groups/hprc/ref_files/chm13/


awk 'BEGIN{OFS="\t"} {print $1, $2, $3, "censat"}' /private/groups/hprc/ref_files/chm13/chm13v2.0_censat_v2.0.bed \
    | cat - <(awk 'BEGIN{OFS="\t"} {print $1, $2, $3, "par"}' /private/groups/hprc/ref_files/chm13/chm13v2.0_PAR.bed ) \
    | sort -k1,1 -k2,2n \
    | bedtools merge \
        -i - \
        -d 10000 \
        | awk 'BEGIN{OFS="\t"} {if ($3 - $2 >= 1000000) {print $1, $2, $3, "censat_or_par";}}' \
    > /private/groups/hprc/ref_files/chm13/chm13v2.0_censat_par_10k_merge_gt1mbp.bed

## misjoin check centromere + PAR bed file
## note 1: adding PARs to avoid false positives in those regions (only PAR1 will be kept)
## note 2: only keep large (1Mbp) sequences because we want to detect large events
cat \
    /private/groups/hprc/ref_files/chm13/chm13v2.0_censat_v2.0.bed \
    /private/groups/hprc/ref_files/chm13/chm13v2.0_PAR.bed \
    | grep -vP '\t.*\(q_arm|\t.*\(p_arm' \
    | awk 'BEGIN{OFS="\t"} {if ($3 - $2 >= 1000) print $1, $2, $3, "censat_or_par";}' \
    | sort -k1,1 -k2,2n \
    | bedtools merge \
    -i - \
    -d 10000 \
    | awk 'BEGIN{OFS="\t"} {if ($3 - $2 >= 1000000) print $1, $2, $3, "censat_or_par";}' \
    > /private/groups/hprc/ref_files/chm13/chm13v2.0_censat_par_10k_merge_gt1mbp.bed
    

cat \
    /private/groups/hprc/ref_files/chm13/chm13v2.0_censat_v2.0.bed \
    /private/groups/hprc/ref_files/chm13/chm13v2.0_PAR.bed \
    | awk 'BEGIN{OFS="\t"} $4 !~ /^ct_/ {print $1, $2, $3, "censat_or_par";}' \
    | sort -k1,1 -k2,2n \
    | bedtools merge \
    -i - \
    -d 10000 \
    | awk 'BEGIN{OFS="\t"} {if ($3 - $2 >= 500000) print $1, $2, $3, "censat_or_par";}' \
    > /private/groups/hprc/ref_files/chm13/chm13v2.0_censat_par_10k_merge_gt1mbp.bed

cat \
    /private/groups/hprc/ref_files/chm13/chm13v2.0_censat_v2.0.bed \
    /private/groups/hprc/ref_files/chm13/chm13v2.0_PAR.bed \
    | awk 'BEGIN{OFS="\t"} $4 !~ /^ct_/ {print $0;}' 


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


###############################################################################
##                          CHM13 Annotation Files For Flagger               ##
###############################################################################

cd /private/groups/hprc/ref_files/chm13/

mkdir flagger_beds
cd flagger_beds

git clone https://github.com/mobinasri/flagger.git
cd flagger
git reset --hard e0dd6cdeda13ef1ea3811d93b253611203f2f6b2
cd ..

cp -r flagger/misc/stratifications/ ./
rm -rf flagger

###############################################################################
##                                  FCS DBs                                  ##
###############################################################################

cd /private/groups/hprc/ref_files/
mkdir -p /private/groups/hprc/ref_files/fcs 

s5cmd  --no-sign-request cp  \
    --part-size 50  \
    --concurrency 50 \
    s3://ncbi-fcs-gx/gxdb/latest/all.* \
    /private/groups/hprc/ref_files/fcs 


###############################################################################
##                               Mito Reference                              ##
###############################################################################

cd /private/groups/hprc/ref_files/
mkdir -p mito 
cd mito

## Download reference (rCRS) mito genome
## NC_012920.1.fasta + NC_012920.1.gb
## based on src/findMitoReference.py in mitohifi...

python3 << 'EOF'
#!/usr/bin/env python

from Bio import Entrez
from Bio import SeqIO
from io import StringIO
import os

def download_sequence_by_id(ncbi_id, email, outfolder):
    Entrez.email = email

    # Create output folder if it doesn't exist
    if not os.path.isdir(outfolder):
        os.mkdir(outfolder)

    # Fetch and save GenBank file
    handle = Entrez.efetch(db="nucleotide", id=ncbi_id, rettype="gb", retmode="text")
    record = handle.read()
    handle.close()
    with open(os.path.join(outfolder, ncbi_id + '.gb'), "w") as out:
        out.write(record)
    
    # Fetch and save FASTA file
    handle = Entrez.efetch(db="nucleotide", id=ncbi_id, rettype="fasta", retmode="text")
    record = handle.read()
    handle.close()
    with open(os.path.join(outfolder, ncbi_id + '.fasta'), "w") as out:
        out.write(record)
    
    print(f"Downloaded {ncbi_id} sequence in GenBank and FASTA formats.")

if __name__ == '__main__':
    # Parameters
    ncbi_id = 'NC_012920.1'
    outfolder = 'rcrs_reference'
    email = 'juklucas@ucsc.edu'

    # Download the sequence
    download_sequence_by_id(ncbi_id, email, outfolder)

EOF


###############################################################################
##                               NCBI's Blast DB For Mito                    ##
###############################################################################

## Currently FCS doesn't find all mito sequences. Use this DB to emulate
## Genbanks mito screening process.
wget -O /private/groups/hprc/ref_files/mito/ncbi_mito_blast_db_v1.1.tar.gz \
    https://ftp.ncbi.nlm.nih.gov/blast/db/mito.tar.gz

