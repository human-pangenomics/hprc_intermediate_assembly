# Exclude:
# Sequence name, length, apparent source
# HG03139#1#h2tg000046l	167414	mitochondrion-not_cleaned

# Exclude:
# Sequence name, length, apparent source
# NA20805#2#h2tg000081l	199481	mitochondrion-not_cleaned

###############################################################################
## 					     	Pull Sequences Identified                        ##   
###############################################################################

cd /private/groups/hprc/genbank_upload/batch4/

mkdir check_contam
cd check_contam

## HG03139.hap1
## check that the contig is actually all mito: it sure is
## my filtering missed it because this mito is so big.
cat /private/groups/hprc/genbank_upload/batch4/HG03139/analysis/assembly_cleanup_outputs/786bcbc5-62b1-44eb-a14f-8b266f4e6c8b/HG03139.hap1.mito_blast_out.txt |
	grep "h2tg000046l" | sort -k7,7n
# h2tg000046l     NC_012920.1     99.637  5789    19      2       1       5788    5788    1       0.0     10573   167414  16569
# h2tg000046l     NC_012920.1     99.644  16571   55      4       5789    22357   16569   1       0.0     30271   167414  16569
# h2tg000046l     NC_012920.1     99.656  16570   55      2       22358   38926   16569   1       0.0     30282   167414  16569
# h2tg000046l     NC_012920.1     99.656  16570   55      2       38927   55495   16569   1       0.0     30282   167414  16569
# h2tg000046l     NC_012920.1     99.662  16570   54      2       55496   72064   16569   1       0.0     30288   167414  16569
# h2tg000046l     NC_012920.1     99.656  16570   55      2       72065   88633   16569   1       0.0     30282   167414  16569
# h2tg000046l     NC_012920.1     99.656  16570   55      2       88634   105202  16569   1       0.0     30282   167414  16569
# h2tg000046l     NC_012920.1     99.656  16570   55      2       105203  121771  16569   1       0.0     30282   167414  16569
# h2tg000046l     NC_012920.1     99.656  16570   55      2       121772  138340  16569   1       0.0     30282   167414  16569
# h2tg000046l     NC_012920.1     99.650  16570   56      2       138341  154909  16569   1       0.0     30276   167414  16569
# h2tg000046l     NC_012920.1     99.688  12505   39      0       154910  167414  16569   4065    0.0     22877   167414  16569


## NA20805.hap2
## check that the contig is actually all mito: it sure is
## my filtering missed it because this mito is so big.
cat /private/groups/hprc/genbank_upload/batch4/NA20805/analysis/assembly_cleanup_outputs/9a7fe6f9-00b4-4470-9ba3-85ad6b97e2d7/NA20805.hap2.mito_blast_out.txt \
	| grep "h2tg000081l" | sort -k7,7n
# h2tg000081l     NC_012920.1     99.798  8396    17      0       1       8396    8174    16569   0.0     15411   199481  16569
# h2tg000081l     NC_012920.1     99.807  16571   29      3       8397    24966   1       16569   0.0     30420   199481  16569
# h2tg000081l     NC_012920.1     99.807  16571   29      3       24967   41536   1       16569   0.0     30420   199481  16569
# h2tg000081l     NC_012920.1     99.813  16571   28      3       41537   58106   1       16569   0.0     30426   199481  16569
# h2tg000081l     NC_012920.1     99.807  16571   29      3       58107   74676   1       16569   0.0     30420   199481  16569
# h2tg000081l     NC_012920.1     99.813  16571   28      3       74677   91246   1       16569   0.0     30426   199481  16569
# h2tg000081l     NC_012920.1     99.813  16571   28      3       91247   107816  1       16569   0.0     30426   199481  16569
# h2tg000081l     NC_012920.1     99.801  16571   30      3       107817  124386  1       16569   0.0     30415   199481  16569
# h2tg000081l     NC_012920.1     99.853  8824    10      3       124387  133209  1       8822    0.0     16220   199481  16569
# h2tg000081l     NC_012920.1     99.786  6535    14      0       133310  139844  10035   16569   0.0     11991   199481  16569
# h2tg000081l     NC_012920.1     99.819  16571   27      3       139845  156414  1       16569   0.0     30432   199481  16569
# h2tg000081l     NC_012920.1     99.807  16571   29      3       156415  172984  1       16569   0.0     30420   199481  16569
# h2tg000081l     NC_012920.1     99.813  16571   28      3       172985  189554  1       16569   0.0     30426   199481  16569
# h2tg000081l     NC_012920.1     99.839  9928    13      3       189555  199481  1       9926    0.0     18242   199481  16569


###############################################################################
## 					  	HG03139.hap1: Remove Extra MT Contig                 ##
###############################################################################

## get file uploaded to genbank...
cp \
	/private/groups/hprc/genbank_upload/batch4/HG03139/analysis/assembly_cleanup_outputs/50c798e3-2898-4ec7-86b4-0b6b62988d5c/HG03139.hap1_for_genbank.fa.gz \
	.

## rename for clarity (Genbank requires that "fixed" files have the same name)
mv HG03139.hap1_for_genbank.fa.gz HG03139.hap1_for_genbank.original.fa.gz

gunzip HG03139.hap1_for_genbank.original.fa.gz

## remove the mito contig...
python /private/groups/hprc/hprc_intermediate_assembly/hpc/misc/fasta_editor.py \
	HG03139.hap1_for_genbank.original.fa \
    remove "HG03139#1#h2tg000046l" \
    HG03139.hap1_for_genbank.fa

## check bases/contigs before edit
awk '/^>/ {contigs++} !/^>/ {bases += length($0)} END {print "Total Bases: " bases "\nTotal Contigs: " contigs}' HG03139.hap1_for_genbank.original.fa
# Total Bases: 2936720242
# Total Contigs: 65

## check bases/contigs after edit
awk '/^>/ {contigs++} !/^>/ {bases += length($0)} END {print "Total Bases: " bases "\nTotal Contigs: " contigs}' HG03139.hap1_for_genbank.fa
# Bases: 2936552828
# Total Contigs: 64

## gzip for upload...
gzip HG03139.hap1_for_genbank.fa 

###############################################################################
## 					  	NA20805.hap2: Remove Extra MT Contig                 ##
###############################################################################

## get file uploaded to genbank...
cp \
	/private/groups/hprc/genbank_upload/batch4/NA20805/analysis/assembly_cleanup_outputs/952171ac-4ea1-4531-9cd4-95de84e4c2b4/NA20805.hap2_for_genbank.fa.gz \
	.

## rename for clarity (Genbank requires that "fixed" files have the same name)
mv NA20805.hap2_for_genbank.fa.gz NA20805.hap2_for_genbank.original.fa.gz

gunzip NA20805.hap2_for_genbank.original.fa.gz

## remove the mito contig...
python /private/groups/hprc/hprc_intermediate_assembly/hpc/misc/fasta_editor.py \
	NA20805.hap2_for_genbank.original.fa \
    remove "NA20805#2#h2tg000081l" \
    NA20805.hap2_for_genbank.fa 

## check bases/contigs before edit
awk '/^>/ {contigs++} !/^>/ {bases += length($0)} END {print "Total Bases: " bases "\nTotal Contigs: " contigs}' NA20805.hap2_for_genbank.original.fa
# Total Bases: 3029826590
# Total Contigs: 90

## check bases/contigs after edit
awk '/^>/ {contigs++} !/^>/ {bases += length($0)} END {print "Total Bases: " bases "\nTotal Contigs: " contigs}' NA20805.hap2_for_genbank.fa
# Total Bases: 3029627109
# Total Contigs: 89

## gzip for upload...
gzip NA20805.hap2_for_genbank.fa

###############################################################################
##                      Upload Assemblies To Genbank                         ##
###############################################################################

cd /private/groups/hprc/genbank_upload/batch4/check_contam

mkdir batch4_fixes_genbank_upload

mv HG03139.hap1_for_genbank.fa.gz batch4_fixes_genbank_upload/
mv NA20805.hap2_for_genbank.fa.gz batch4_fixes_genbank_upload/

ascp \
    -i /private/home/juklucas/.ssh/aspera.openssh \
    -QT \
    -l100m \
    -k1 \
    -d batch4_fixes_genbank_upload \
    subasp@upload.ncbi.nlm.nih.gov:uploads/juklucas_ucsc.edu_tD3gRQfz/int_asm_batch4_fixes

###############################################################################
##                          Upload To HPRC Bucket                            ##
###############################################################################

cd /private/groups/hprc/genbank_upload/batch4/check_contam

mkdir -p batch4_fixes_s3_upload/HG03139/assemblies/freeze_2/assembly_pipeline/ncbi_upload/
mkdir -p batch4_fixes_s3_upload/NA20805/assemblies/freeze_2/assembly_pipeline/ncbi_upload/

cp \
	batch4_fixes_genbank_upload/HG03139.hap1_for_genbank.fa.gz \
	batch4_fixes_s3_upload/HG03139/assemblies/freeze_2/assembly_pipeline/ncbi_upload/HG03139.hap1_for_genbank_fixed.fa.gz

cp \
	batch4_fixes_genbank_upload/NA20805.hap2_for_genbank.fa.gz \
	batch4_fixes_s3_upload/NA20805/assemblies/freeze_2/assembly_pipeline/ncbi_upload/NA20805.hap2_for_genbank_fixed.fa.gz

ssds staging upload \
    --submission-id DC27718F-5F38-43B0-9A78-270F395F13E8 \
    batch4_fixes_genbank_upload \
    &>>batch4_s3_upload_fixes.upload.stderr
    

###############################################################################
##                                   DONE                                    ##
###############################################################################