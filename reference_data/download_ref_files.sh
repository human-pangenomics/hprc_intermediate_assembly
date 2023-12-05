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


###############################################################################
##                                                                           ## 
###############################################################################