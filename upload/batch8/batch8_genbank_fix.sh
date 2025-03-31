# HG02392#1#h2tg000037l	941888	mitochondrion-not_cleaned

# HG02392#2#h1tg000061l	167355	mitochondrion-not_cleaned
# HG02392#2#h1tg000088l	909097	mitochondrion-not_cleaned


###############################################################################
## 					     	Pull Sequences Identified                        ##   
###############################################################################

cd /private/groups/hprc/genbank_upload/batch8/

mkdir check_contam
cd check_contam

# /private/groups/hprc/genbank_upload/batch8/HG02392/analysis/assembly_cleanup_outputs/209d12ce-00cf-48a9-a6c4-830c4479de82/HG02392.hap2_for_genbank.fa.gz	
# /private/groups/hprc/genbank_upload/batch8/HG02392/analysis/assembly_cleanup_outputs/561b3686-7d51-448a-9a4b-de049cc1b662/HG02392.hap1_for_genbank.fa.gz
# /private/groups/hprc/genbank_upload/batch8/HG02392/analysis/assembly_cleanup_outputs/1f2dd4c4-9fa2-4204-bb6d-dfde041d6226/HG02392.hap1.mito_blast_out.txt
# /private/groups/hprc/genbank_upload/batch8/HG02392/analysis/assembly_cleanup_outputs/3b350c28-e4f8-4055-a930-dc756166bab5/HG02392.hap2.mito_blast_out.txt

## HG02392.hap1
## check that the contig is actually all mito: it sure is
## my filtering missed it because this mito is so big.
cat /private/groups/hprc/genbank_upload/batch8/HG02392/analysis/assembly_cleanup_outputs/1f2dd4c4-9fa2-4204-bb6d-dfde041d6226/HG02392.hap1.mito_blast_out.txt |
	grep "h2tg000037l" | sort -k7,7n
# h2tg000037l     NC_012920.1     99.587  1210    4       1       1       1210    1209    1       0.0     2206    941888  16569
# h2tg000037l     NC_012920.1     99.783  16572   32      4       1211    17781   16569   1       0.0     30400   941888  16569
# h2tg000037l     NC_012920.1     99.803  16259   31      1       17782   34039   16569   311     0.0     29846   941888  16569
# h2tg000037l     NC_012920.1     99.785  9758    18      3       908943  918699  9756    1       0.0     17900   941888  16569
# h2tg000037l     NC_012920.1     99.777  16571   34      3       918700  935269  16569   1       0.0     30393   941888  16569
# h2tg000037l     NC_012920.1     99.773  6620    14      1       935270  941888  16569   9950    0.0     12140   941888  16569

# make sure the rest of the sequence is N's (it is)
seqtk gap -l 2 \
    /private/groups/hprc/genbank_upload/batch8/HG02392/analysis/assembly_cleanup_outputs/561b3686-7d51-448a-9a4b-de049cc1b662/HG02392.hap1_for_genbank.fa.gz \
    | grep "h2tg000037l"
# HG02392#1#h2tg000037l   32946   907847


# HG02392#2#h1tg000061l	167355	mitochondrion-not_cleaned
# HG02392#2#h1tg000088l	909097	mitochondrion-not_cleaned


cat /private/groups/hprc/genbank_upload/batch8/HG02392/analysis/assembly_cleanup_outputs/3b350c28-e4f8-4055-a930-dc756166bab5/HG02392.hap2.mito_blast_out.txt |
	grep "h1tg000061l" | sort -k7,7n
# h1tg000061l     NC_012920.1     99.815  14571   26      1       1       14570   1999    16569   0.0     26757   167355  16569
# h1tg000061l     NC_012920.1     99.783  16571   33      3       14571   31140   1       16569   0.0     30398   167355  16569
# h1tg000061l     NC_012920.1     99.332  1198    4       4       31141   32336   1       1196    0.0     2165    167355  16569
# h1tg000061l     NC_012920.1     99.706  15303   29      6       32420   47719   1280    16569   0.0     27996   167355  16569
# h1tg000061l     NC_012920.1     99.779  8127    14      4       47720   55844   1       8125    0.0     14905   167355  16569
# h1tg000061l     NC_012920.1     99.602  2511    8       2       55945   58454   14060   16569   0.0     4580    167355  16569
# h1tg000061l     NC_012920.1     99.765  16572   34      5       58455   75024   1       16569   0.0     30382   167355  16569
# h1tg000061l     NC_012920.1     99.572  16587   34      27      75025   91592   1       16569   0.0     30203   167355  16569
# h1tg000061l     NC_012920.1     99.716  16571   34      6       91593   108152  1       16569   0.0     30328   167355  16569
# h1tg000061l     NC_012920.1     99.747  16578   32      5       108153  124729  1       16569   0.0     30372   167355  16569
# h1tg000061l     NC_012920.1     99.626  16581   33      27      124730  141293  1       16569   0.0     30249   167355  16569
# h1tg000061l     NC_012920.1     99.512  16587   33      14      141294  157850  1       16569   0.0     30138   167355  16569
# h1tg000061l     NC_012920.1     99.779  9507    17      4       157851  167355  1       9505    0.0     17437   167355  16569


cat /private/groups/hprc/genbank_upload/batch8/HG02392/analysis/assembly_cleanup_outputs/3b350c28-e4f8-4055-a930-dc756166bab5/HG02392.hap2.mito_blast_out.txt |
	grep "h1tg000088l" | sort -k7,7n
# h1tg000088l     NC_012920.1     99.781  8672    15      4       1       8670    8670    1       0.0     15906   909097  16569
# h1tg000088l     NC_012920.1     99.729  16576   34      10      8671    25242   16569   1       0.0     30350   909097  16569
# h1tg000088l     NC_012920.1     99.777  16571   32      4       25243   41810   16569   1       0.0     30391   909097  16569
# h1tg000088l     NC_012920.1     99.781  4107    9       0       41811   45917   16569   12463   0.0     7535    909097  16569
# h1tg000088l     NC_012920.1     99.761  11732   23      4       873759  885487  11730   1       0.0     21505   909097  16569
# h1tg000088l     NC_012920.1     99.361  16590   43      27      885488  902035  16569   1       0.0     29990   909097  16569
# h1tg000088l     NC_012920.1     99.731  7064    15      4       902036  909097  16569   9508    0.0     12936   909097  16569

seqtk gap -l 2 \
    /private/groups/hprc/genbank_upload/batch8/HG02392/analysis/assembly_cleanup_outputs/209d12ce-00cf-48a9-a6c4-830c4479de82/HG02392.hap2_for_genbank.fa.gz	\
    | grep "h1tg000088l"
# HG02392#2#h1tg000088l   35339   863180    

###############################################################################
## 					  	HG02392.hap1: Remove Extra MT Contig                 ##
###############################################################################

## get file uploaded to genbank...
cp \
	/private/groups/hprc/genbank_upload/batch8/HG02392/analysis/assembly_cleanup_outputs/561b3686-7d51-448a-9a4b-de049cc1b662/HG02392.hap1_for_genbank.fa.gz \
	.

## rename for clarity (Genbank requires that "fixed" files have the same name)
mv HG02392.hap1_for_genbank.fa.gz HG02392.hap1_for_genbank.original.fa.gz

gunzip HG02392.hap1_for_genbank.original.fa.gz

## remove the mito contig...
python /private/groups/hprc/hprc_intermediate_assembly/hpc/misc/fasta_editor.py \
	HG02392.hap1_for_genbank.original.fa \
    remove "HG02392#1#h2tg000037l" \
    HG02392.hap1_for_genbank.fa

## check bases/contigs before edit
awk '/^>/ {contigs++} !/^>/ {bases += length($0)} END {print "Total Bases: " bases "\nTotal Contigs: " contigs}' HG02392.hap1_for_genbank.original.fa
# Total Bases: 2936073765
# Total Contigs: 87

## check bases/contigs after edit
awk '/^>/ {contigs++} !/^>/ {bases += length($0)} END {print "Total Bases: " bases "\nTotal Contigs: " contigs}' HG02392.hap1_for_genbank.fa
# Total Bases: 2935131877
# Total Contigs: 86

## gzip for upload...
pigz HG02392.hap1_for_genbank.fa &

rm HG02392.hap1_for_genbank.original.fa

###############################################################################
## 					  	HG02392.hap2: Remove Extra MT Contig                 ##
###############################################################################

## get file uploaded to genbank...
cp \
	/private/groups/hprc/genbank_upload/batch8/HG02392/analysis/assembly_cleanup_outputs/209d12ce-00cf-48a9-a6c4-830c4479de82/HG02392.hap2_for_genbank.fa.gz \
	.

## rename for clarity (Genbank requires that "fixed" files have the same name)
mv HG02392.hap2_for_genbank.fa.gz HG02392.hap2_for_genbank.original.fa.gz

gunzip HG02392.hap2_for_genbank.original.fa.gz

## remove the mito contig...
python /private/groups/hprc/hprc_intermediate_assembly/hpc/misc/fasta_editor.py \
	HG02392.hap2_for_genbank.original.fa \
    remove "HG02392#2#h1tg000061l" \
    HG02392.hap2_for_genbank_temp.fa

python /private/groups/hprc/hprc_intermediate_assembly/hpc/misc/fasta_editor.py \
	HG02392.hap2_for_genbank_temp.fa \
    remove "HG02392#2#h1tg000088l" \
    HG02392.hap2_for_genbank.fa

## check bases/contigs before edit
awk '/^>/ {contigs++} !/^>/ {bases += length($0)} END {print "Total Bases: " bases "\nTotal Contigs: " contigs}' HG02392.hap2_for_genbank.original.fa
# Total Bases: 3028631317
# Total Contigs: 91

## check bases/contigs after edit
awk '/^>/ {contigs++} !/^>/ {bases += length($0)} END {print "Total Bases: " bases "\nTotal Contigs: " contigs}' HG02392.hap2_for_genbank.fa
# Total Bases: 3027554865
# Total Contigs: 89

## gzip for upload...
pigz HG02392.hap2_for_genbank.fa &

rm HG02392.hap2_for_genbank_temp.fa 
rm HG02392.hap2_for_genbank.original.fa

###############################################################################
##                      Upload Assemblies To Genbank                         ##
###############################################################################

cd /private/groups/hprc/genbank_upload/batch8/check_contam

mkdir batch8_fixes_genbank_upload

mv HG02392.hap1_for_genbank.fa.gz batch8_fixes_genbank_upload/
mv HG02392.hap2_for_genbank.fa.gz batch8_fixes_genbank_upload/


ascp \
    -i /private/home/juklucas/.ssh/aspera.openssh \
    -QT \
    -l100m \
    -k1 \
    -d batch8_fixes_genbank_upload \
    subasp@upload.ncbi.nlm.nih.gov:uploads/juklucas_ucsc.edu_tD3gRQfz/int_asm_batch8_fixes


###############################################################################
##                          Upload To HPRC Bucket                            ##
###############################################################################

cd /private/groups/hprc/genbank_upload/batch8/check_contam

mkdir -p batch8_fixes_s3_upload/HG02392/assemblies/freeze_2/assembly_pipeline/ncbi_upload/

cp \
	batch8_fixes_genbank_upload/HG02392.hap1_for_genbank.fa.gz \
	batch8_fixes_s3_upload/HG02392/assemblies/freeze_2/assembly_pipeline/ncbi_upload/HG02392.hap1_for_genbank_fixed.fa.gz

cp \
	batch8_fixes_genbank_upload/HG02392.hap2_for_genbank.fa.gz \
	batch8_fixes_s3_upload/HG02392/assemblies/freeze_2/assembly_pipeline/ncbi_upload/HG02392.hap2_for_genbank_fixed.fa.gz


ssds staging upload \
    --submission-id DC27718F-5F38-43B0-9A78-270F395F13E8 \
    batch8_fixes_s3_upload \
    &>>batch8_s3_upload_fixes.upload.stderr
    

###############################################################################
##                                   DONE                                    ##
###############################################################################