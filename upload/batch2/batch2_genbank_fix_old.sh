## I got a contamination hit from NCBI (not FCS)
# Trim:
# Sequence name, length, span(s), apparent source
# HG02738#2#h2tg000012l	98268417	98228921..98231355	vector/etc-not_cleaned

## based on the checks below, it looks like hifiasm is adding a read to the 
## contig that is just EBV so I will trim off that sequence.

###############################################################################
## 					     	Pull Sequences Identified                        ##   
###############################################################################

cd /private/groups/hprc/genbank_upload/batch2/

mkdir check_contam
cd check_contam

cp \
	/private/groups/hprc/genbank_upload/batch2/HG02738/analysis/assembly_cleanup_outputs/7ce6cdde-4e16-406a-b8a7-390b75554956/HG02738.hap2_for_genbank.fa.gz \
	.

gunzip HG02738.hap2_for_genbank.fa.gz

samtools faidx \
	HG02738.hap2_for_genbank.fa \
	HG02738#2#h2tg000012l:98228921-98231355 \
	> HG02738#2#h2tg000012l_98228921_to_98231355.fa

cat HG02738#2#h2tg000012l_98228921_to_98231355.fa
## put into blast and it's a big stinkin hit to EBV. dang.
## size of region identified is 2434, so not too big, I suppose.
## small enough for introgression?

## check to see if the contig is reasonably sized...
samtools faidx \
	HG02738.hap2_for_genbank.fa

cat HG02738.hap2_for_genbank.fa | grep "HG02738#2#h2tg000012l"
# HG02738#2#h2tg000012l   98268417        2344430591      60      61
## its nearly 98Mbp, so given the position of the EBV hit, it sounds
## like it's at the end of the contig...


###############################################################################
## 					   Is Contig Human At All?                               ##   
###############################################################################

## now let's see where it maps to on chm13 (from mashmap results)
cat /private/groups/hprc/genbank_upload/batch2/HG02738/analysis/assembly_cleanup_outputs/f8935794-500f-4007-bc38-1754eb293ab3/HG02738.hap2_mito_stripped.mashmap.txt \
	| grep "h2tg000012l"
# h2tg000012l 98268417 0 98268416 + chr14 101161492 1862014 100130430 99.7741	


## yup, human chr14...


###############################################################################
## 					     	Align EBV To Contig.                             ##   
###############################################################################

samtools faidx \
	HG02738.hap2_for_genbank.fa \
	HG02738#2#h2tg000012l \
	> HG02738#2#h2tg000012l.fa

# Download EBV genome from NCBI RefSeq
wget https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/002/402/265/GCF_002402265.1_ASM240226v1/GCF_002402265.1_ASM240226v1_genomic.fna.gz

# Unzip the genome
gunzip GCF_002402265.1_ASM240226v1_genomic.fna.gz


# Align the GCF_002402265.1 genome to your assembled genome and output a PAF file
minimap2 -x asm5 \
	-c HG02738#2#h2tg000012l.fa \
	GCF_002402265.1_ASM240226v1_genomic.fna \
	> alignment.paf

cat alignment.paf 
# NC_007605.1     171823  132428  171772  -       HG02738#2#h2tg000012l   98268417        98240899        98268417        27495   39367   60      NM:i:11872      ms:i:27222AS:i:15304       nn:i:0  tp:A:P  cm:i:2788       s1:i:25613      s2:i:2120       de:f:0.0002     rl:i:0  cg:Z:521M17I538M15D510M8D18632M11831I514M1I6780M
# NC_007605.1     171823  0       15947   -       HG02738#2#h2tg000012l   98268417        98222479        98238678        15942   16199   60      NM:i:257        ms:i:15784AS:i:15514       nn:i:0  tp:A:P  cm:i:1602       s1:i:15811      s2:i:804        de:f:0.0004     rl:i:0  cg:Z:7916M252D8031M
# NC_007605.1     171823  15072   19019   -       HG02738#2#h2tg000012l   98268417        98222479        98226426        3940    3947    60      NM:i:7  ms:i:3807       AS:i:3807  nn:i:0  tp:A:P  cm:i:371        s1:i:3814       s2:i:0  de:f:0.0018     rl:i:0  cg:Z:3947M
# NC_007605.1     171823  21216   25163   -       HG02738#2#h2tg000012l   98268417        98222479        98226426        3940    3947    60      NM:i:7  ms:i:3807       AS:i:3807  nn:i:0  tp:A:P  cm:i:371        s1:i:3814       s2:i:0  de:f:0.0018     rl:i:0  cg:Z:3947M
# NC_007605.1     171823  30432   34379   -       HG02738#2#h2tg000012l   98268417        98222479        98226426        3940    3947    60      NM:i:7  ms:i:3807       AS:i:3807  nn:i:0  tp:A:P  cm:i:371        s1:i:3814       s2:i:0  de:f:0.0018     rl:i:0  cg:Z:3947M
# NC_007605.1     171823  27360   31307   -       HG02738#2#h2tg000012l   98268417        98222479        98226426        3940    3947    60      NM:i:7  ms:i:3807       AS:i:3807  nn:i:0  tp:A:P  cm:i:371        s1:i:3814       s2:i:0  de:f:0.0018     rl:i:0  cg:Z:3947M
# NC_007605.1     171823  18144   22091   -       HG02738#2#h2tg000012l   98268417        98222479        98226426        3940    3947    60      NM:i:7  ms:i:3807       AS:i:3807  nn:i:0  tp:A:P  cm:i:371        s1:i:3814       s2:i:0  de:f:0.0018     rl:i:0  cg:Z:3947M
# NC_007605.1     171823  24288   28235   -       HG02738#2#h2tg000012l   98268417        98222479        98226426        3940    3947    60      NM:i:7  ms:i:3807       AS:i:3807  nn:i:0  tp:A:P  cm:i:371        s1:i:3814       s2:i:0  de:f:0.0018     rl:i:0  cg:Z:3947M
# NC_007605.1     171823  33504   35355   -       HG02738#2#h2tg000012l   98268417        98224575        98226426        1846    1851    60      NM:i:5  ms:i:1751       AS:i:1751  nn:i:0  tp:A:P  cm:i:160        s1:i:1747       s2:i:0  de:f:0.0027     rl:i:0  cg:Z:1851M


## check again with a seqeuence I know is EBV (as NCBI would use)
## download genome from https://www.ncbi.nlm.nih.gov/nuccore/NC_007605.1?report=fasta
## to double, check. (Looks the same in alignment.)
minimap2 -x asm5 \
	-c HG02738#2#h2tg000012l.fa \
	NC_007605.1.fasta \
	> ebv_on_HG02738#2#h2tg000012l.paf
	
# NC_007605.1     171823  132428  171772  -       HG02738#2#h2tg000012l   98268417        98240899        98268417        27495   39367   60      NM:i:11872      ms:i:27222AS:i:15304       nn:i:0  tp:A:P  cm:i:2788       s1:i:25613      s2:i:2120       de:f:0.0002     rl:i:0  cg:Z:521M17I538M15D510M8D18632M11831I514M1I6780M
# NC_007605.1     171823  0       15947   -       HG02738#2#h2tg000012l   98268417        98222479        98238678        15942   16199   60      NM:i:257        ms:i:15784AS:i:15514       nn:i:0  tp:A:P  cm:i:1602       s1:i:15811      s2:i:804        de:f:0.0004     rl:i:0  cg:Z:7916M252D8031M
# NC_007605.1     171823  15072   19019   -       HG02738#2#h2tg000012l   98268417        98222479        98226426        3940    3947    60      NM:i:7  ms:i:3807       AS:i:3807  nn:i:0  tp:A:P  cm:i:371        s1:i:3814       s2:i:0  de:f:0.0018     rl:i:0  cg:Z:3947M
# NC_007605.1     171823  21216   25163   -       HG02738#2#h2tg000012l   98268417        98222479        98226426        3940    3947    60      NM:i:7  ms:i:3807       AS:i:3807  nn:i:0  tp:A:P  cm:i:371        s1:i:3814       s2:i:0  de:f:0.0018     rl:i:0  cg:Z:3947M
# NC_007605.1     171823  30432   34379   -       HG02738#2#h2tg000012l   98268417        98222479        98226426        3940    3947    60      NM:i:7  ms:i:3807       AS:i:3807  nn:i:0  tp:A:P  cm:i:371        s1:i:3814       s2:i:0  de:f:0.0018     rl:i:0  cg:Z:3947M
# NC_007605.1     171823  27360   31307   -       HG02738#2#h2tg000012l   98268417        98222479        98226426        3940    3947    60      NM:i:7  ms:i:3807       AS:i:3807  nn:i:0  tp:A:P  cm:i:371        s1:i:3814       s2:i:0  de:f:0.0018     rl:i:0  cg:Z:3947M
# NC_007605.1     171823  18144   22091   -       HG02738#2#h2tg000012l   98268417        98222479        98226426        3940    3947    60      NM:i:7  ms:i:3807       AS:i:3807  nn:i:0  tp:A:P  cm:i:371        s1:i:3814       s2:i:0  de:f:0.0018     rl:i:0  cg:Z:3947M
# NC_007605.1     171823  24288   28235   -       HG02738#2#h2tg000012l   98268417        98222479        98226426        3940    3947    60      NM:i:7  ms:i:3807       AS:i:3807  nn:i:0  tp:A:P  cm:i:371        s1:i:3814       s2:i:0  de:f:0.0018     rl:i:0  cg:Z:3947M
# NC_007605.1     171823  33504   35355   -       HG02738#2#h2tg000012l   98268417        98224575        98226426        1846    1851    60      NM:i:5  ms:i:1751       AS:i:1751  nn:i:0  tp:A:P  cm:i:160        s1:i:1747       s2:i:0  de:f:0.0027     rl:i:0  cg:Z:1851M	


###############################################################################
## 					           Check Graph                                   ##   
###############################################################################

cd /private/groups/hprc/genbank_upload/batch2/check_contam

mkdir graph
cd graph

cp /private/groups/hprc/assembly/batch2/HG02738/analysis/assembly/HG02738.raw_unitig_gfa.tar.gz	.
cp /private/groups/hprc/assembly/batch2/HG02738/analysis/assembly/HG02738.mat.contig_gfa.tar.gz	.
cp /private/groups/hprc/assembly/batch2/HG02738/analysis/assembly/HG02738.pat.contig_gfa.tar.gz .


for file in *.tar.gz; do tar -xzf "$file"; done

rm *.tar.gz

## clean up gfas (already have noseq gfas)
for folder in *raw_unitig_gfa; do rm "$folder"/*r_utg.gfa; done

for folder in *contig_gfa; do
full_gfa=("$folder"/*ctg.gfa)
echo $full_gfa
python3 - <<EOF
input_gfa = "$full_gfa"
output_gfa="${full_gfa%.gfa}.noseq.gfa"

with open(input_gfa, 'r') as infile, open(output_gfa, 'w') as outfile:
    for line in infile:
        parts = line.strip().split('\t')
        if parts[0] == 'S' and len(parts) > 2:
            parts[2] = '*'  # Replace the sequence with an asterisk
            outfile.write('\t'.join(parts) + '\n')
        else:
            outfile.write(line)
EOF
done


grep -B 10 -m 1 'h2tg000013l' HG02738.mat.contig_gfa/HG02738.dip.hap2.p_ctg.noseq.gfa
# A       h2tg000012l     98206250        -       m64076_210711_102225/15008250/ccs       0       25613   id:i:1595452    HG:A:m
# A       h2tg000012l     98214060        +       m64076_210711_102225/50266899/ccs       0       18936   id:i:1938630    HG:A:m
# A       h2tg000012l     98214101        +       m64076_210714_200553/28574576/ccs       0       25035   id:i:3408378    HG:A:m
# A       h2tg000012l     98218317        +       m84046_230623_213746_s2/102242136/ccs   0       21332   id:i:7092112    HG:A:m
# A       h2tg000012l     98223936        -       m84046_230628_182559_s4/156504411/ccs   0       29078   id:i:9486052    HG:A:a
# A       h2tg000012l     98226505        +       m64076_210718_085619/1312355/ccs        0       30025   id:i:4723581    HG:A:a
# A       h2tg000012l     98227188        +       m64076_210718_085619/147524031/ccs      0       30503   id:i:6056898    HG:A:a
# A       h2tg000012l     98236815        +       m64076_210718_085619/145752067/ccs      0       21258   id:i:6040010    HG:A:a
# A       h2tg000012l     98237383        +       m84046_230623_213746_s2/245956814/ccs   0       24133   id:i:7719725    HG:A:a
# A       h2tg000012l     98237416        +       m64076_210706_214544/125568804/ccs      0       30891   id:i:1016405    HG:A:a
# S       h2tg000013l     *       LN:i:62408324   rd:i:32


## the very last section is just one read that seems to exactly encompass
## the EBV section (which implies that the EBV is misplaced).


###############################################################################
## 					        Check Verkko Assembly                            ##   
###############################################################################

cd /private/groups/hprc/genbank_upload/batch2/check_contam


## pull haplotype 1 from verkko (currently the haplotype numbering is switched)
aws s3 cp \
	s3://human-pangenomics/submissions/0624338D-1A6F-4E29-A276-D2C247FE0558--verkko-v2.1_intermediate_asms/HG02738/verkko-thic/HG02738.assembly.haplotype1.fasta.bz \
	.

bgzip -d HG02738.assembly.haplotype1.fasta.bz

minimap2 -x asm5 \
	-c HG02738.assembly.haplotype1.fasta \
	NC_007605.1.fasta \
	> ebv_on_HG02738_verkko_hap1.paf	

cat ebv_on_HG02738_verkko_hap1.paf
# NC_007605.1     171823  0       38938   +       mat-0000039     60254   11829   60236   38929   48416   60      NM:i:9487       ms:i:38318      AS:i:28813      nn:i:0  tp:A:P     cm:i:3899       s1:i:37227      s2:i:35071      de:f:0.0003     rl:i:335        cg:Z:8028M252D4619M9216D22794M1I91M1I882M9D274M1I30M1I678M1I39M1I450M1I534M1D340M1I115M1I55M
# NC_007605.1     171823  12000   48621   -       mat-0000106     46801   0       36503   36478   36639   60      NM:i:161        ms:i:36046      AS:i:35779      nn:i:0  tp:A:P     cm:i:3664       s1:i:36215      s2:i:8286       de:f:0.0004     rl:i:335        cg:Z:22M8I8D98M1I16M1I424M1D1849M1I6374M125I3233M9D24469M
# NC_007605.1     171823  0       35352   +       mat-0000035     56425   11829   47432   35344   35604   0       NM:i:260        ms:i:35106      AS:i:34836      nn:i:0  tp:A:S     cm:i:3517       s1:i:35071      de:f:0.0003     rl:i:335        cg:Z:8028M252D27151M1I172M
# NC_007605.1     171823  0       32827   +       mat-0000037     37869   4797    37869   32815   33079   0       NM:i:264        ms:i:32363      AS:i:32093      nn:i:0  tp:A:S     cm:i:3260       s1:i:32520      de:f:0.0004     rl:i:335        cg:Z:8028M252D24122M1I66M1I34M1I64M1I69M1I175M1I119M1I143M
# NC_007605.1     171823  162170  171772  +       mat-0000039     60254   0       9608    9583    9627    0       NM:i:44 ms:i:9264       AS:i:9178       nn:i:0  tp:A:P  cm:i:970   s1:i:9491       s2:i:9491       de:f:0.0007     rl:i:335        cg:Z:196M1I838M1D425M1D2250M1I4293M8D521M15D538M17I522M
# NC_007605.1     171823  162170  171772  +       mat-0000035     56425   0       9608    9583    9627    0       NM:i:44 ms:i:9264       AS:i:9178       nn:i:0  tp:A:S  cm:i:970   s1:i:9491       de:f:0.0007     rl:i:335        cg:Z:196M1I838M1D425M1D2250M1I4293M8D521M15D538M17I522M
# NC_007605.1     171823  143283  144328  -       mat-0000106     46801   7210    8254    1033    1045    29      NM:i:12 ms:i:782        AS:i:782        nn:i:0  tp:A:P  cm:i:87    s1:i:878        s2:i:874        de:f:0.0115     rl:i:335        cg:Z:829M1I215M
# NC_007605.1     171823  143283  144328  +       mat-0000004     102184957       1155634 1156679 1033    1046    0       NM:i:13 ms:i:740        AS:i:740        nn:i:0  tp:A:S     cm:i:84 s1:i:874        de:f:0.0124     rl:i:335        cg:Z:210M1I374M1D460M


## now check the other haplotype just to be sure...
aws s3 cp \
	s3://human-pangenomics/submissions/0624338D-1A6F-4E29-A276-D2C247FE0558--verkko-v2.1_intermediate_asms/HG02738/verkko-thic/HG02738.assembly.haplotype2.fasta.bz \
	.

bgzip -d HG02738.assembly.haplotype2.fasta.bz

minimap2 -x asm5 \
	-c HG02738.assembly.haplotype2.fasta \
	NC_007605.1.fasta \
	> ebv_on_HG02738_verkko_hap2.paf	


cat ebv_on_HG02738_verkko_hap2.paf
## empty


###############################################################################
##                      Check EBV Contamination                              ##
###############################################################################

cd /private/groups/hprc/genbank_upload/batch2/

mkdir genbank_fix
cd genbank_fix


cp /private/groups/hprc/genbank_upload/batch2/HG02738/analysis/assembly_cleanup_outputs/7ce6cdde-4e16-406a-b8a7-390b75554956/HG02738.hap2_for_genbank.fa.gz ./

gunzip HG02738.hap2_for_genbank.fa.gz

## genbank requires that fixed assembly has the same name as the final assembly
mv HG02738.hap2_for_genbank.fa HG02738.hap2_for_genbank_raw.fa

awk '/^>/ {contigs++} !/^>/ {bases += length($0)} END {print "Total Bases: " bases "\nTotal Contigs: " contigs}' HG02738.hap2_for_genbank_raw.fa
# Total Bases: 3038268697
# Total Contigs: 65

python /private/groups/hprc/hprc_intermediate_assembly/hpc/misc/fasta_editor.py \
	HG02738.hap2_for_genbank_raw.fa \
    trim "HG02738#2#h2tg000012l:98237417-98268417" \
                                98222479
    HG02738.hap2_for_genbank.fa

gzip HG02738.hap2_for_genbank.fa

###############################################################################
## 					            	DONE                                     ##   
###############################################################################