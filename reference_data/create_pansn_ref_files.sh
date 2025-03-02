###############################################################################
##							      HG002                                      ##
###############################################################################

cd /private/groups/hprc/ref_files/hg002/

## download references (including version of HG002 with MT but no EBV)
aws s3 cp s3://human-pangenomics/T2T/HG002/assemblies/hg002v1.1.pat.fasta.gz .
aws s3 cp s3://human-pangenomics/T2T/HG002/assemblies/hg002v1.1.mat_MT.fasta.gz .


zcat hg002v1.1.pat.fasta.gz \
	| sed 's/>chr\([0-9Y]*\)_PATERNAL/>HG002#1#chr\1/' \
	> hg002v1.1.pat.PanSN.fa


## Note: chrM is written chrM not chrM_MATERNAL
zcat hg002v1.1.mat_MT.fasta.gz \
  | sed 's/>chr\([0-9X]*\)_MATERNAL/>HG002#2#chr\1/' \
  | sed 's/>chrM/>HG002#2#chrM/' \
  > hg002v1.1.mat_MT.PanSN.fa


bgzip -i hg002v1.1.pat.PanSN.fa
bgzip -i hg002v1.1.mat_MT.PanSN.fa

samtools faidx hg002v1.1.mat_MT.PanSN.fa.gz
samtools faidx hg002v1.1.pat.PanSN.fa.gz

md5sum hg002v1.1.mat_MT.PanSN.fa.gz > hg002v1.1.mat_MT.PanSN.fa.gz.md5
md5sum hg002v1.1.pat.PanSN.fa.gz > hg002v1.1.pat.PanSN.fa.gz.md5


cat<<EOF > README.txt
## 14 Feb 2025
## created version of HG002 v1.1 with PanSN naming convention for HPRC use.

## 02 Mar 2025: UPDATE
## fixed PanSN convention for chrM in maternal haplotype
## replaced sed 's/>chrM/>HG002#2chrM/' with sed 's/>chrM/>HG002#2#chrM/'


## download references (including version of HG002 with MT but no EBV)
aws s3 cp s3://human-pangenomics/T2T/HG002/assemblies/hg002v1.1.pat.fasta.gz .
aws s3 cp s3://human-pangenomics/T2T/HG002/assemblies/hg002v1.1.mat_MT.fasta.gz .


zcat hg002v1.1.pat.fasta.gz \
	| sed 's/>chr\([0-9Y]*\)_PATERNAL/>HG002#1#chr\1/' \
	> hg002v1.1.pat.PanSN.fa


## Note: chrM is written chrM not chrM_MATERNAL
zcat hg002v1.1.mat_MT.fasta.gz \
  | sed 's/>chr\([0-9X]*\)_MATERNAL/>HG002#2#chr\1/' \
  | sed 's/>chrM/>HG002#2#chrM/' \
  > hg002v1.1.mat_MT.PanSN.fa


bgzip -i hg002v1.1.pat.PanSN.fa
bgzip -i hg002v1.1.mat_MT.PanSN.fa

samtools faidx hg002v1.1.mat_MT.PanSN.fa.gz
samtools faidx hg002v1.1.pat.PanSN.fa.gz

md5sum hg002v1.1.mat_MT.PanSN.fa.gz > hg002v1.1.mat_MT.PanSN.fa.gz.md5
md5sum hg002v1.1.pat.PanSN.fa.gz > hg002v1.1.pat.PanSN.fa.gz.md5
EOF

aws s3 cp hg002v1.1.mat_MT.PanSN.fa.gz     s3://human-pangenomics/working/HPRC_PLUS/HG002/assemblies/Q100/pansn/hg002v1.1.mat_MT.PanSN.fa.gz
aws s3 cp hg002v1.1.mat_MT.PanSN.fa.gz.fai s3://human-pangenomics/working/HPRC_PLUS/HG002/assemblies/Q100/pansn/hg002v1.1.mat_MT.PanSN.fa.gz.fai
aws s3 cp hg002v1.1.mat_MT.PanSN.fa.gz.gzi s3://human-pangenomics/working/HPRC_PLUS/HG002/assemblies/Q100/pansn/hg002v1.1.mat_MT.PanSN.fa.gz.gzi
aws s3 cp hg002v1.1.mat_MT.PanSN.fa.gz.md5 s3://human-pangenomics/working/HPRC_PLUS/HG002/assemblies/Q100/pansn/hg002v1.1.mat_MT.PanSN.fa.gz.md5

aws s3 cp hg002v1.1.pat.PanSN.fa.gz     s3://human-pangenomics/working/HPRC_PLUS/HG002/assemblies/Q100/pansn/hg002v1.1.pat.PanSN.fa.gz
aws s3 cp hg002v1.1.pat.PanSN.fa.gz.fai s3://human-pangenomics/working/HPRC_PLUS/HG002/assemblies/Q100/pansn/hg002v1.1.pat.PanSN.fa.gz.fai
aws s3 cp hg002v1.1.pat.PanSN.fa.gz.gzi s3://human-pangenomics/working/HPRC_PLUS/HG002/assemblies/Q100/pansn/hg002v1.1.pat.PanSN.fa.gz.gzi
aws s3 cp hg002v1.1.pat.PanSN.fa.gz.md5 s3://human-pangenomics/working/HPRC_PLUS/HG002/assemblies/Q100/pansn/hg002v1.1.pat.PanSN.fa.gz.md5

aws s3 cp README.txt s3://human-pangenomics/working/HPRC_PLUS/HG002/assemblies/Q100/pansn/README.txt


###############################################################################
##							      GRCh38                                     ##
###############################################################################

cd /private/groups/hprc/ref_files/grch38

aws s3 cp s3://human-pangenomics/working/HPRC_PLUS/GRCh38/assemblies/GCA_000001405.15_GRCh38_no_alt_analysis_set.fna.gz .

zcat GCA_000001405.15_GRCh38_no_alt_analysis_set.fna.gz \
  | sed 's/^>\(chr[^[:space:]]*\)/>GRCh38#0#\1/' \
  > GCA_000001405.15_GRCh38_no_alt_analysis_set.PanSN.fa

bgzip -i GCA_000001405.15_GRCh38_no_alt_analysis_set.PanSN.fa

samtools faidx GCA_000001405.15_GRCh38_no_alt_analysis_set.PanSN.fa.gz

md5sum GCA_000001405.15_GRCh38_no_alt_analysis_set.PanSN.fa.gz > GCA_000001405.15_GRCh38_no_alt_analysis_set.PanSN.fa.gz.md5

cat<<EOF > README.txt
## 14 Feb 2025
## created version of GCA_000001405.15_GRCh38_no_alt_analysis_set.fna.gz with PanSN naming convention for HPRC use.

aws s3 cp s3://human-pangenomics/working/HPRC_PLUS/GRCh38/assemblies/GCA_000001405.15_GRCh38_no_alt_analysis_set.fna.gz .

zcat GCA_000001405.15_GRCh38_no_alt_analysis_set.fna.gz \
  | sed 's/^>\(chr[^[:space:]]*\)/>GRCh38#0#\1/' \
  > GCA_000001405.15_GRCh38_no_alt_analysis_set.PanSN.fa

bgzip -i GCA_000001405.15_GRCh38_no_alt_analysis_set.PanSN.fa

samtools faidx GCA_000001405.15_GRCh38_no_alt_analysis_set.PanSN.fa.gz

md5sum GCA_000001405.15_GRCh38_no_alt_analysis_set.PanSN.fa.gz > GCA_000001405.15_GRCh38_no_alt_analysis_set.PanSN.fa.gz.md5
EOF

aws s3 cp GCA_000001405.15_GRCh38_no_alt_analysis_set.PanSN.fa.gz s3://human-pangenomics/working/HPRC_PLUS/GRCh38/assemblies/pansn/GCA_000001405.15_GRCh38_no_alt_analysis_set.PanSN.fa.gz
aws s3 cp GCA_000001405.15_GRCh38_no_alt_analysis_set.PanSN.fa.gz.fai s3://human-pangenomics/working/HPRC_PLUS/GRCh38/assemblies/pansn/GCA_000001405.15_GRCh38_no_alt_analysis_set.PanSN.fa.gz.fai
aws s3 cp GCA_000001405.15_GRCh38_no_alt_analysis_set.PanSN.fa.gz.gzi s3://human-pangenomics/working/HPRC_PLUS/GRCh38/assemblies/pansn/GCA_000001405.15_GRCh38_no_alt_analysis_set.PanSN.fa.gz.gzi
aws s3 cp GCA_000001405.15_GRCh38_no_alt_analysis_set.PanSN.fa.gz.md5 s3://human-pangenomics/working/HPRC_PLUS/GRCh38/assemblies/pansn/GCA_000001405.15_GRCh38_no_alt_analysis_set.PanSN.fa.gz.md5
aws s3 cp README.txt s3://human-pangenomics/working/HPRC_PLUS/GRCh38/assemblies/pansn/README.txt


###############################################################################
##							    CHM13 v2.0                                   ##
###############################################################################

cd /private/groups/hprc/ref_files/

aws s3 cp s3://human-pangenomics/T2T/CHM13/assemblies/analysis_set/chm13v2.0_maskedY_rCRS.fa.gz .

zcat chm13v2.0_maskedY_rCRS.fa.gz \
  | sed 's/^>\(chr[^[:space:]]*\)/>CHM13#0#\1/' \
  > chm13v2.0_maskedY_rCRS.fa.PanSN.fa

bgzip -i chm13v2.0_maskedY_rCRS.fa.PanSN.fa

samtools faidx chm13v2.0_maskedY_rCRS.fa.PanSN.fa.gz

md5sum chm13v2.0_maskedY_rCRS.fa.PanSN.fa.gz > chm13v2.0_maskedY_rCRS.fa.PanSN.fa.gz.md5


cat<<EOF > README.txt
## 14 Feb 2025
## created version of chm13v2.0_maskedY_rCRS with PanSN naming convention for HPRC use.

aws s3 cp s3://human-pangenomics/T2T/CHM13/assemblies/analysis_set/chm13v2.0_maskedY_rCRS.fa.gz .

zcat chm13v2.0_maskedY_rCRS.fa.gz \
  | sed 's/^>\(chr[^[:space:]]*\)/>CHM13#0#\1/' \
  > chm13v2.0_maskedY_rCRS.fa.PanSN.fa

bgzip -i chm13v2.0_maskedY_rCRS.fa.PanSN.fa

samtools faidx chm13v2.0_maskedY_rCRS.fa.PanSN.fa.gz

md5sum chm13v2.0_maskedY_rCRS.fa.PanSN.fa.gz > chm13v2.0_maskedY_rCRS.fa.PanSN.fa.gz.md5
EOF

aws s3 cp chm13v2.0_maskedY_rCRS.fa.PanSN.fa.gz s3://human-pangenomics/working/HPRC_PLUS/CHM13/assemblies/analysis_set/pansn/chm13v2.0_maskedY_rCRS.fa.PanSN.fa.gz
aws s3 cp chm13v2.0_maskedY_rCRS.fa.PanSN.fa.gz.fai s3://human-pangenomics/working/HPRC_PLUS/CHM13/assemblies/analysis_set/pansn/chm13v2.0_maskedY_rCRS.fa.PanSN.fa.gz.fai
aws s3 cp chm13v2.0_maskedY_rCRS.fa.PanSN.fa.gz.gzi s3://human-pangenomics/working/HPRC_PLUS/CHM13/assemblies/analysis_set/pansn/chm13v2.0_maskedY_rCRS.fa.PanSN.fa.gz.gzi
aws s3 cp chm13v2.0_maskedY_rCRS.fa.PanSN.fa.gz.md5 s3://human-pangenomics/working/HPRC_PLUS/CHM13/assemblies/analysis_set/pansn/chm13v2.0_maskedY_rCRS.fa.PanSN.fa.gz.md5
aws s3 cp README.txt s3://human-pangenomics/working/HPRC_PLUS/CHM13/assemblies/analysis_set/pansn/README.txt

###############################################################################
##							       DONE                                      ##
###############################################################################