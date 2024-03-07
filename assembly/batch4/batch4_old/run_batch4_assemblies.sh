
###############################################################################
##                             create input jsons                            ##
###############################################################################

## on personal computer...

cd /Users/juklucas/Desktop/github/hprc_intermediate_assembly/assembly/batch4/hifiasm_input_jsons

python3 ../../../hpc/launch_from_table.py \
     --data_table ../HPRC_Intermediate_Assembly_s3Locs_batch4.csv \
     --field_mapping ../hifiasm_hic_input_mapping.csv \
     --workflow_name hifiasm

## add/commit/push to github (hprc_intermediate_assembly)

###############################################################################
##                                 launch assemblies                         ##
###############################################################################

## on HPC...
cd /private/groups/hprc/

## check that github repo is up to date
git -C /private/groups/hprc/hprc_intermediate_assembly pull

mkdir assembly/batch4
cd assembly/batch4

## get files to run hifiasm in sandbox...
cp -r /private/groups/hprc/hprc_intermediate_assembly/assembly/batch4/* ./


mkdir hifiasm_submit_logs

## launch with slurm array job
sbatch --array=[1-24]%24 \
     launch_hifiasm_array.sh \
     HPRC_Intermediate_Assembly_s3Locs_Batch4.csv

## HG02965 failed to finish downloading...
rm -rf HG02965

sbatch --array=[5]%1 \
     launch_hifiasm_array.sh \
     HPRC_Intermediate_Assembly_s3Locs_Batch4.csv    


###############################################################################
##                         Update table with outputs                         ##
###############################################################################

cd /private/groups/hprc/assembly/batch4

python3 /private/groups/hprc/hprc_intermediate_assembly/hpc/update_table_with_outputs.py \
      --input_data_table HPRC_Intermediate_Assembly_s3Locs_Batch4.csv  \
      --output_data_table HPRC_Intermediate_Assembly_s3Locs_Batch4_w_hifiasm.csv \
      --json_location '{sample_id}_hifiasm_outputs.json'

cp HPRC_Intermediate_Assembly_s3Locs_Batch4_w_hifiasm.csv \
     /private/groups/hprc/hprc_intermediate_assembly/assembly/batch4/


## hard code in female samples so I can rerun groupbyxy WDL on all...
nano female_samples.txt
```
HG03195
HG00099
HG00323
HG02976
HG02165
HG02155
HG02273
HG02922
```
while IFS= read -r sample; do
  find "${sample}/assembly_bigstore/files/for-job/kind-WDLTaskJob/" -type f \( -name "*.hap1.fa.gz" -or -name "*.hap2.fa.gz" \)
done < female_samples.txt
```
HG03195/assembly_bigstore/files/for-job/kind-WDLTaskJob/instance-a2fcz778/file-9ea5c4274b9943818f9224832fc0ee4e/HG03195.hap2.fa.gz
HG03195/assembly_bigstore/files/for-job/kind-WDLTaskJob/instance-a2fcz778/file-2fd89e1528434c68930ecc48edbfff3d/HG03195.hap1.fa.gz
HG00099/assembly_bigstore/files/for-job/kind-WDLTaskJob/instance-phbmes7j/file-1100f2ed96e1491685bcf6a01787424d/HG00099.hap2.fa.gz
HG00099/assembly_bigstore/files/for-job/kind-WDLTaskJob/instance-phbmes7j/file-394bbb2b2892477c9e2357cae878efa8/HG00099.hap1.fa.gz
HG00323/assembly_bigstore/files/for-job/kind-WDLTaskJob/instance-j7mmglle/file-e8ba1f2f97b34898ba41eb4c125f8c61/HG00323.hap2.fa.gz
HG00323/assembly_bigstore/files/for-job/kind-WDLTaskJob/instance-j7mmglle/file-4c2bcc46fcda46059767067af776f2e9/HG00323.hap1.fa.gz
HG02976/assembly_bigstore/files/for-job/kind-WDLTaskJob/instance-ty9h1ex8/file-6b11cf7197734e2db444c7e7d831f7ed/HG02976.hap2.fa.gz
HG02976/assembly_bigstore/files/for-job/kind-WDLTaskJob/instance-ty9h1ex8/file-f9dde3c1ba584c7ab010f61684c56ccf/HG02976.hap1.fa.gz
HG02165/assembly_bigstore/files/for-job/kind-WDLTaskJob/instance-3bavpj4y/file-d1cdf940459f4ff7adab0989a7d8e38c/HG02165.hap2.fa.gz
HG02165/assembly_bigstore/files/for-job/kind-WDLTaskJob/instance-3bavpj4y/file-7fec05d6fb664f7b8614e55e2a5662ce/HG02165.hap1.fa.gz
HG02155/assembly_bigstore/files/for-job/kind-WDLTaskJob/instance-o73al72a/file-76ba709a3d814e449c2a7e0dc0e508f6/HG02155.hap2.fa.gz
HG02155/assembly_bigstore/files/for-job/kind-WDLTaskJob/instance-o73al72a/file-c25e553cf74e4b0280a719a3d44e129b/HG02155.hap1.fa.gz
HG02273/assembly_bigstore/files/for-job/kind-WDLTaskJob/instance-jjtfodim/file-92b705718fb84d8fb1c4d5a1fe5aa4f4/HG02273.hap2.fa.gz
HG02273/assembly_bigstore/files/for-job/kind-WDLTaskJob/instance-jjtfodim/file-475473923fc74c698a33c56abbf9b7d4/HG02273.hap1.fa.gz
HG02922/assembly_bigstore/files/for-job/kind-WDLTaskJob/instance-s5tj1na4/file-667d24c5e3564c36aad1ee816f2a5cb4/HG02922.hap2.fa.gz
HG02922/assembly_bigstore/files/for-job/kind-WDLTaskJob/instance-s5tj1na4/file-03496619140c47dea2ead935f24167a6/HG02922.hap1.fa.gz
```

###############################################################################
##                        create input jsons for groupbyxy                   ##   
###############################################################################

mkdir rerun_groupbyxy
cd rerun_groupbyxy

mkdir groupbyxy_input_jsons
cd groupbyxy_input_jsons

python3 /Users/juklucas/Desktop/github/hprc_intermediate_assembly/hpc/launch_from_table.py \
     --data_table ../../HPRC_Intermediate_Assembly_s3Locs_Batch4_w_hifiasm.csv \
     --field_mapping ../groupbyxy_input_mapping.csv \
     --workflow_name groupbyxy    


###############################################################################
##                               launch groupbyxy                            ##   
###############################################################################

cd /private/groups/hprc/assembly/batch4

mkdir rerun_groupbyxy
mkdir groupbyxy_submit_logs

cp -r /private/groups/hprc/hprc_intermediate_assembly/assembly/batch4/rerun_groupbyxy/* rerun_groupbyxy/

sbatch \
    --array=[1-24]%24 \
    rerun_groupbyxy/launch_groupbyxy_array.sh \
    HPRC_Intermediate_Assembly_s3Locs_Batch4_w_hifiasm.csv 


###############################################################################
##                         Update table with outputs                         ##
###############################################################################

python3 /private/groups/hprc/hprc_intermediate_assembly/hpc/update_table_with_outputs.py \
      --input_data_table HPRC_Intermediate_Assembly_s3Locs_Batch4_w_hifiasm.csv \
      --output_data_table HPRC_Intermediate_Assembly_s3Locs_Batch4_w_hifiasm_groupbyxy.csv \
      --json_location '{sample_id}_hifiasm_groupbyxy_outputs.json'  

mkdir initial_qc
cd initial_qc

mkdir qc_input_jsons
cd qc_input_jsons

python3 /private/groups/hprc/hprc_intermediate_assembly/hpc/launch_from_table.py \
     --data_table ../../HPRC_Intermediate_Assembly_s3Locs_Batch4_w_hifiasm_groupbyxy.csv \
     --field_mapping ../qc_input_mapping.csv \
     --workflow_name initial_qc    

## copy to github repo for notetaking
cd ../../

cp \
    HPRC_Intermediate_Assembly_s3Locs_Batch4_w_hifiasm_groupbyxy.csv \
    /private/groups/hprc/hprc_intermediate_assembly/assembly/batch4/HPRC_Intermediate_Assembly_s3Locs_Batch4_w_hifiasm_groupbyxy_updated.csv

cp -r initial_qc/ /private/groups/hprc/hprc_intermediate_assembly/assembly/batch4/        


###############################################################################
##                               launch initial QC                           ##   
###############################################################################

cd /private/groups/hprc/assembly/batch4

mkdir qc_submit_logs

sbatch \
    --array=[1-24]%24 \
    initial_qc/launch_initial_qc_array.sh \
    HPRC_Intermediate_Assembly_s3Locs_Batch4_w_hifiasm_groupbyxy.csv 


###############################################################################
##                     Update table with hifiasm qc outputs                  ##
###############################################################################

## collect location of QC results
python3 /private/groups/hprc/hprc_intermediate_assembly/hpc/update_table_with_outputs.py \
      --input_data_table HPRC_Intermediate_Assembly_s3Locs_Batch4.csv  \
      --output_data_table HPRC_Intermediate_Assembly_s3Locs_Batch4_w_hifiasm_w_QC.csv  \
      --json_location '{sample_id}_hifiasm_qc_outputs.json'

## extract QC results
python3 /private/groups/hprc/hprc_intermediate_assembly/hpc/misc/extract_initial_qc_non_trio.py \
     --qc_data_table HPRC_Intermediate_Assembly_s3Locs_Batch4_w_hifiasm_w_QC.csv \
     --extract_column_name filtQCStats \
     --output initial_qc/batch4_extracted_qc_results.csv

cp \
     HPRC_Intermediate_Assembly_s3Locs_Batch3_w_hifiasm_w_qc.csv \
     /private/groups/hprc/hprc_intermediate_assembly/assembly/batch3/HPRC_Intermediate_Assembly_s3Locs_Batch3_w_hifiasm_w_qc.csv

## add/commit/push to github (hprc_intermediate_assembly)

