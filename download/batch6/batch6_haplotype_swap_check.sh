## some users noticed that two of the samples had odd haplotypes that didn't
## match their expectations and wondered if they were mat/pat swapped.

## looking into this, I found that indeed they had been swapped in the 
## upload/download process (for Genbank) so we need to fix that.

# HG01978   1   83  97  swapped
# HG01978   2   97  83  swapped
# HG02257   2   113 79  swapped
# HG02257   1   79  113 swapped
# HG03516   1   72  74  swapped
# HG03516   2   74  72  swapped

###############################################################################
##							Check My Prior Notes/Logs						 ##
###############################################################################

## Assembly input json...

# "trioHifiasmAssembly.paternalID": "HG02256",
# "trioHifiasmAssembly.maternalID": "HG02255",
# "trioHifiasmAssembly.paternalReadsILM": [
#   "s3://human-pangenomics/working/HPRC/HG02257/raw_data/Illumina/parents/HG02255/HG02255.final.cram"
# ],
# "trioHifiasmAssembly.maternalReadsILM": [
#   "s3://human-pangenomics/working/HPRC/HG02257/raw_data/Illumina/parents/HG02256/HG02256.final.cram"
# ],

## looks like I corrected the Illumina data, but I didn't correct the parent
## sample names. This **should** create a misnaming of the yak files, but 
## that shouldn't matter.

## Can see the misnaming happing in the assembly log file...

# 	+ yak count -t16 -b37 -o HG02256.yak /dev/fd/63 /dev/fd/62
# 	++ cat /mnt/miniwdl_task_container/work/_miniwdl_inputs/0/HG02255.final.fq
# 	++ cat /mnt/miniwdl_task_container/work/_miniwdl_inputs/0/HG02255.final.fq


## QC steps used the yak files from assembly so the pat yak is named HG02256.yak
## but it should actually have data from HG02255

## check the QC input json (to confirm naming)
# "comparisonQC.patYak": "/private/groups/hprc/assembly/batch6/HG02257/analysis/trio_hifiasm_assembly_cutadapt_multistep_outputs/0c649fa6-5aa8-410f-987b-bf47d5377e5f/HG02256.yak",
# "comparisonQC.matYak": "/private/groups/hprc/assembly/batch6/HG02257/analysis/trio_hifiasm_assembly_cutadapt_multistep_outputs/064de5dc-001f-4336-9470-21632625162c/HG02255.yak",

###############################################################################
##							Check One Sample By Hand						 ##
###############################################################################

cd /private/groups/hprc/qc_testing/swap_check

## pat ilmn
## s3://human-pangenomics/working/HPRC/HG02257/raw_data/Illumina/parents/HG02255/HG02255.final.cram

## mat ilmn
## s3://human-pangenomics/working/HPRC/HG02257/raw_data/Illumina/parents/HG02256/HG02256.final.cram


java -jar ~/opt/womtool-54.jar inputs  /private/home/juklucas/github/hpp_production_workflows/assembly/wdl/tasks/yak_no_stats.wdl
# {
#   "runYak.sampleReadsILM": "Array[File]",
#   "runYak.sampleReadsExtracted.dockerImage": "String (optional, default = \"mobinasri/bio_base:dev-v0.1\")",
#   "runYak.referenceFasta": "File? (optional)",
#   "runYak.sampleReadsExtracted.fastqOptions": "String (optional, default = \"\")",
#   "runYak.sampleReadsExtracted.excludeString": "String (optional, default = \"\")",
#   "runYak.fileExtractionDiskSizeGB": "Int (optional, default = 256)",
#   "runYak.yakCountSample.memSizeGB": "Int (optional, default = 128)",
#   "runYak.dockerImage": "String (optional, default = \"tpesout/hpp_yak:latest\")",
#   "runYak.yakCountSample.bloomSize": "Int (optional, default = 37)",
#   "runYak.yakCountSample.threadCount": "Int (optional, default = 16)",
#   "runYak.sampleName": "String"
# }

cat <<EOF > yak_input_mapping.csv
input,type,value
runYak.sampleReadsILM,array,\$input.ilmn
runYak.referenceFasta,scalar,"/private/groups/hprc/ref_files/grch38/hs38DH.fa"
runYak.sampleName,scalar,\$input.sample_id
EOF

cat <<EOF > check_swap.csv
sample_id,ilmn
HG02255,s3://human-pangenomics/working/HPRC/HG02257/raw_data/Illumina/parents/HG02255/HG02255.final.cram
HG02256,s3://human-pangenomics/working/HPRC/HG02257/raw_data/Illumina/parents/HG02256/HG02256.final.cram
EOF

mkdir input_jsons
cd input_jsons

## create input jsons
python3 /private/groups/hprc/hprc_intermediate_assembly/hpc/launch_from_table.py \
     --data_table ../check_swap.csv \
     --field_mapping ../yak_input_mapping.csv \
     --workflow_name yak_no_stats


cd ..
mkdir -p slurm_logs

## download assemblies from genbank and rename sequence IDs
sbatch \
     --job-name=HPRC-yak \
     --array=[1-2] \
     --partition=high_priority \
     /private/groups/hprc/hprc_intermediate_assembly/hpc/toil_sbatch_slurm.sh \
     --wdl /private/home/juklucas/github/hpp_production_workflows/assembly/wdl/tasks/yak_no_stats.wdl \
     --sample_csv check_swap.csv \
     --input_json_path '../input_jsons/${SAMPLE_ID}_yak_no_stats.json' 


## collect results into data table    
python3 /private/groups/hprc/hprc_intermediate_assembly/hpc/update_table_with_outputs.py \
    --input_data_table check_swap.csv \
    --output_data_table check_swap_results.csv  \
    --json_location '{sample_id}_yak_no_stats_outputs.json'


aws s3 cp \
	s3://human-pangenomics/submissions/DC27718F-5F38-43B0-9A78-270F395F13E8--INT_ASM_PRODUCTION/HG02257/assemblies/freeze_2/HG02257_mat_hprc_r2_v1.0.1.fa.gz \
	./

aws s3 cp \
	s3://human-pangenomics/submissions/DC27718F-5F38-43B0-9A78-270F395F13E8--INT_ASM_PRODUCTION/HG02257/assemblies/freeze_2/HG02257_pat_hprc_r2_v1.0.1.fa.gz \
	./	

docker run \
	-it \
	-v $(pwd):/data \
	-u 30145:620 \
	juklucas/hpp_yak:latest \
	/bin/bash


## pat then mat   
yak trioeval \
	-t 8 \
	HG02255/analysis/yak_no_stats_outputs/d40b96db-46b1-4485-b44e-7b6c91b0f12e/HG02255.yak \
	HG02256/analysis/yak_no_stats_outputs/924e1b8d-0852-44d5-80fd-bb26651c288e/HG02256.yak \
	HG02257_pat_hprc_r2_v1.0.1.fa.gz \
	> HG02257_pat.yak.switch-error.txt

# C	S  seqName     #patKmer  #matKmer  #pat-pat  #pat-mat  #mat-pat  #mat-mat  seqLen
# S	HG02257#1#CM089263.1	348	110247	116	232	232	110014	137764123
# S	HG02257#1#CM089264.1	392	95081	141	251	251	94829	134667366
# S	HG02257#1#CM089265.1	377	89946	114	263	263	89682	134086697
# S	HG02257#1#CM089266.1	376	95580	129	247	246	95333	133600428
# S	HG02257#1#CM089267.1	305	81555	120	185	185	81369	102606376
# S	HG02257#1#CM089268.1	324	72229	117	206	207	72022	83085470
# S	HG02257#1#CM089269.1	262	60316	101	161	161	60154	66768376
        

yak trioeval \
	-t 8 \
	HG02255/analysis/yak_no_stats_outputs/d40b96db-46b1-4485-b44e-7b6c91b0f12e/HG02255.yak \
	HG02256/analysis/yak_no_stats_outputs/924e1b8d-0852-44d5-80fd-bb26651c288e/HG02256.yak \
	HG02257_mat_hprc_r2_v1.0.1.fa.gz \
	> HG02257_mat.yak.switch-error.txt


# S	HG02257#2#CM089218.1	155116	684	154717	398	398	286	243244210
# S	HG02257#2#CM089219.1	121440	497	121146	293	293	204	194750200
# S	HG02257#2#CM089220.1	147528	389	147304	223	224	165	180961285
# S	HG02257#2#CM089221.1	115047	436	114786	261	260	175	172638302
# S	HG02257#2#CM089222.1	124054	459	123781	272	273	186	160434370
# S	HG02257#2#CM089223.1	112124	352	111886	237	238	114	145977212

## Check HG02255.yak (misnamed QC yak)
ls -l /private/groups/hprc/assembly/batch6/HG02257/analysis/trio_hifiasm_assembly_cutadapt_multistep_outputs/064de5dc-001f-4336-9470-21632625162c/HG02255.yak
# 21618312304

## Check HG02256.yak (misnamed QC yak)
ls -l /private/groups/hprc/assembly/batch6/HG02257/analysis/trio_hifiasm_assembly_cutadapt_multistep_outputs/0c649fa6-5aa8-410f-987b-bf47d5377e5f/HG02256.yak
# 21815059816


ls -l HG02256/analysis/yak_no_stats_outputs/924e1b8d-0852-44d5-80fd-bb26651c288e/HG02256.yak
# 21618312304

ls -l HG02255/analysis/yak_no_stats_outputs/d40b96db-46b1-4485-b44e-7b6c91b0f12e/HG02255.yak
# 21815059816


aws s3 cp s3://human-pangenomics/submissions/DC27718F-5F38-43B0-9A78-270F395F13E8--INT_ASM_PRODUCTION/HG02257/assemblies/freeze_2/assembly_pipeline/ncbi_upload/HG02257.hap2_for_genbank.fa.gz .
gunzip HG02257.hap2_for_genbank.fa.gz
samtools faidx HG02257.hap2_for_genbank.fa


###############################################################################
##                          Check Upload vs Download                         ##
###############################################################################

## check what went up to genbank vs what I downloaded by looking at the 
## fai file and looking for differences

wget https://raw.githubusercontent.com/human-pangenomics/hprc_intermediate_assembly/refs/heads/main/data_tables/assemblies_pre_release_v0.5.index.csv


cat <<EOF > check_swap.py
import pandas as pd
import os
import subprocess
import gzip
import tempfile

def count_sequences_in_fai(fai_path):
    """Count number of sequences in an fai file."""
    with open(fai_path, 'r') as f:
        return sum(1 for line in f)

def transform_path_for_check(fai_path):
    """Transform FAI path to check file path."""
    # Parse the path components
    parts = fai_path.split('/')
    sample_id = parts[-1].split('_')[0]  # Extract sample ID
    
    # Determine if pat/mat needs to be transformed to hap1/hap2
    if '_pat_' in fai_path:
        haplotype = 'hap1'
    elif '_mat_' in fai_path:
        haplotype = 'hap2'
    else:
        # If it's already hap1/hap2, keep it as is
        for part in parts:
            if 'hap1' in part:
                haplotype = 'hap1'
                break
            elif 'hap2' in part:
                haplotype = 'hap2'
                break
    
    # Reconstruct the path with new components
    base_path = '/'.join(parts[:-1])  # Get path up to the filename
    base_path = base_path.replace('freeze_2', 'freeze_2/assembly_pipeline/ncbi_upload')
    
    # Construct new filename
    new_filename = f"{sample_id}.{haplotype}_for_genbank.fa.gz"
    
    return f"{base_path}/{new_filename}"

def main():
    # Read the index file
    df = pd.read_csv('assemblies_pre_release_v0.5.index.csv')
    
    # Filter for HPRC rows
    df = df[df['source'] == 'hprc']
    
    # Initialize results list
    results = []
    
    # Create temporary directory for downloads
    with tempfile.TemporaryDirectory() as tmpdir:
        # Process each FAI file
        for _, row in df.iterrows():
            try:
                sample_id = row['sample_id']
                haplotype = row['haplotype']
                fai_url = row['assembly_fai']
                
                print(f"Processing {sample_id} haplotype {haplotype}")
                
                # Download FAI file using aws s3 cp
                fai_local_path = os.path.join(tmpdir, f"{sample_id}_original.fai")
                subprocess.run(['aws', 's3', 'cp', fai_url, fai_local_path], check=True)
                fai_count = count_sequences_in_fai(fai_local_path)
                
                # Get and process check file
                check_url = transform_path_for_check(fai_url)
                check_gz_path = os.path.join(tmpdir, f"{sample_id}_check.fa.gz")
                check_fa_path = os.path.join(tmpdir, f"{sample_id}_check.fa")
                check_fai_path = os.path.join(tmpdir, f"{sample_id}_check.fa.fai")
                
                # Download check file using aws s3 cp
                subprocess.run(['aws', 's3', 'cp', check_url, check_gz_path], check=True)
                
                # Gunzip check file
                with gzip.open(check_gz_path, 'rb') as f_in:
                    with open(check_fa_path, 'wb') as f_out:
                        f_out.write(f_in.read())
                
                # Run samtools faidx
                subprocess.run(['samtools', 'faidx', check_fa_path], check=True)
                
                # Count sequences in check fai
                check_count = count_sequences_in_fai(check_fai_path)
                
                # Store results
                results.append({
                    'sample_id': sample_id,
                    'haplotype': haplotype,
                    'fai_count': fai_count,
                    'check_count': check_count
                })
                
                # Clean up temporary files
                os.remove(check_gz_path)
                os.remove(check_fa_path)
                os.remove(check_fai_path)
                
            except Exception as e:
                print(f"Error processing {sample_id}: {str(e)}")
                results.append({
                    'sample_id': sample_id,
                    'haplotype': haplotype,
                    'fai_count': -1,
                    'check_count': -1
                })
    
    # Create and save results DataFrame
    results_df = pd.DataFrame(results)
    results_df.to_csv('fasta_sequence_counts.csv', index=False)
    print("Results saved to fasta_sequence_counts.csv")

if __name__ == "__main__":
    main()
EOF

python check_swap.py

# sample_id	haplotype	fai_count	check_count	notes
# HG01978	1	83	97	swapped
# HG01978	2	97	83	swapped
# HG02257	2	113	79	swapped
# HG02257	1	79	113	swapped
# HG03516	1	72	74	swapped
# HG03516	2	74	72	swapped
# HG03139	1	64	65	mito, ok
# HG03470	1	94	95	mito, ok
# HG03470	2	69	70	mito, ok
# HG02392	2	89	91	mito, ok
# HG02392	1	86	87	mito, ok
# NA20805	2	89	90	mito, ok


###############################################################################
##                     View FAI Files For Asm W/ -1 Entries                  ##
###############################################################################

cd /private/groups/hprc/qc_testing/swap_check

mkdir manual_fai_check
cd manual_fai_check
# List of S3 files
files=(
"s3://human-pangenomics/submissions/DC27718F-5F38-43B0-9A78-270F395F13E8--INT_ASM_PRODUCTION/HG02514/assemblies/freeze_2/HG02514_pat_hprc_r2_v1.0.1.fa.gz.fai"
"s3://human-pangenomics/submissions/DC27718F-5F38-43B0-9A78-270F395F13E8--INT_ASM_PRODUCTION/HG02841/assemblies/freeze_2/HG02841_pat_hprc_r2_v1.0.1.fa.gz.fai"
"s3://human-pangenomics/submissions/DC27718F-5F38-43B0-9A78-270F395F13E8--INT_ASM_PRODUCTION/HG02984/assemblies/freeze_2/HG02984_pat_hprc_r2_v1.0.1.fa.gz.fai"
"s3://human-pangenomics/submissions/DC27718F-5F38-43B0-9A78-270F395F13E8--INT_ASM_PRODUCTION/HG03050/assemblies/freeze_2/HG03050_pat_hprc_r2_v1.0.1.fa.gz.fai"
"s3://human-pangenomics/submissions/DC27718F-5F38-43B0-9A78-270F395F13E8--INT_ASM_PRODUCTION/NA20799/assemblies/freeze_2/NA20799_hap1_hprc_r2_v1.0.1.fa.gz.fai"
"s3://human-pangenomics/submissions/DC27718F-5F38-43B0-9A78-270F395F13E8--INT_ASM_PRODUCTION/HG00733/assemblies/freeze_2/HG00733_pat_hprc_r2_v1.0.1.fa.gz.fai"
"s3://human-pangenomics/submissions/DC27718F-5F38-43B0-9A78-270F395F13E8--INT_ASM_PRODUCTION/HG01243/assemblies/freeze_2/HG01243_pat_hprc_r2_v1.0.1.fa.gz.fai"
"s3://human-pangenomics/submissions/DC27718F-5F38-43B0-9A78-270F395F13E8--INT_ASM_PRODUCTION/HG00097/assemblies/freeze_2/HG00097_hap1_hprc_r2_v1.0.1.fa.gz.fai"
"s3://human-pangenomics/submissions/DC27718F-5F38-43B0-9A78-270F395F13E8--INT_ASM_PRODUCTION/HG00235/assemblies/freeze_2/HG00235_hap1_hprc_r2_v1.0.1.fa.gz.fai"
"s3://human-pangenomics/submissions/DC27718F-5F38-43B0-9A78-270F395F13E8--INT_ASM_PRODUCTION/HG00253/assemblies/freeze_2/HG00253_hap1_hprc_r2_v1.0.1.fa.gz.fai"
"s3://human-pangenomics/submissions/DC27718F-5F38-43B0-9A78-270F395F13E8--INT_ASM_PRODUCTION/HG00272/assemblies/freeze_2/HG00272_hap1_hprc_r2_v1.0.1.fa.gz.fai"
"s3://human-pangenomics/submissions/DC27718F-5F38-43B0-9A78-270F395F13E8--INT_ASM_PRODUCTION/HG00329/assemblies/freeze_2/HG00329_hap1_hprc_r2_v1.0.1.fa.gz.fai"
"s3://human-pangenomics/submissions/DC27718F-5F38-43B0-9A78-270F395F13E8--INT_ASM_PRODUCTION/HG00344/assemblies/freeze_2/HG00344_hap1_hprc_r2_v1.0.1.fa.gz.fai"
"s3://human-pangenomics/submissions/DC27718F-5F38-43B0-9A78-270F395F13E8--INT_ASM_PRODUCTION/HG00350/assemblies/freeze_2/HG00350_hap1_hprc_r2_v1.0.1.fa.gz.fai"
"s3://human-pangenomics/submissions/DC27718F-5F38-43B0-9A78-270F395F13E8--INT_ASM_PRODUCTION/HG01167/assemblies/freeze_2/HG01167_hap1_hprc_r2_v1.0.1.fa.gz.fai"
"s3://human-pangenomics/submissions/DC27718F-5F38-43B0-9A78-270F395F13E8--INT_ASM_PRODUCTION/HG03369/assemblies/freeze_2/HG03369_hap1_hprc_r2_v1.0.1.fa.gz.fai"
"s3://human-pangenomics/submissions/DC27718F-5F38-43B0-9A78-270F395F13E8--INT_ASM_PRODUCTION/HG03521/assemblies/freeze_2/HG03521_hap1_hprc_r2_v1.0.1.fa.gz.fai"
"s3://human-pangenomics/submissions/DC27718F-5F38-43B0-9A78-270F395F13E8--INT_ASM_PRODUCTION/HG03784/assemblies/freeze_2/HG03784_hap1_hprc_r2_v1.0.1.fa.gz.fai"
"s3://human-pangenomics/submissions/DC27718F-5F38-43B0-9A78-270F395F13E8--INT_ASM_PRODUCTION/NA18565/assemblies/freeze_2/NA18565_hap1_hprc_r2_v1.0.1.fa.gz.fai"
"s3://human-pangenomics/submissions/DC27718F-5F38-43B0-9A78-270F395F13E8--INT_ASM_PRODUCTION/NA19682/assemblies/freeze_2/NA19682_hap1_hprc_r2_v1.0.1.fa.gz.fai"
"s3://human-pangenomics/submissions/DC27718F-5F38-43B0-9A78-270F395F13E8--INT_ASM_PRODUCTION/NA19776/assemblies/freeze_2/NA19776_hap1_hprc_r2_v1.0.1.fa.gz.fai"
"s3://human-pangenomics/submissions/DC27718F-5F38-43B0-9A78-270F395F13E8--INT_ASM_PRODUCTION/NA19835/assemblies/freeze_2/NA19835_hap1_hprc_r2_v1.0.1.fa.gz.fai"
"s3://human-pangenomics/submissions/DC27718F-5F38-43B0-9A78-270F395F13E8--INT_ASM_PRODUCTION/NA19909/assemblies/freeze_2/NA19909_hap1_hprc_r2_v1.0.1.fa.gz.fai"
"s3://human-pangenomics/submissions/DC27718F-5F38-43B0-9A78-270F395F13E8--INT_ASM_PRODUCTION/NA20282/assemblies/freeze_2/NA20282_hap1_hprc_r2_v1.0.1.fa.gz.fai"
"s3://human-pangenomics/submissions/DC27718F-5F38-43B0-9A78-270F395F13E8--INT_ASM_PRODUCTION/NA20346/assemblies/freeze_2/NA20346_hap1_hprc_r2_v1.0.1.fa.gz.fai"
"s3://human-pangenomics/submissions/DC27718F-5F38-43B0-9A78-270F395F13E8--INT_ASM_PRODUCTION/NA20809/assemblies/freeze_2/NA20809_hap1_hprc_r2_v1.0.1.fa.gz.fai"
"s3://human-pangenomics/submissions/DC27718F-5F38-43B0-9A78-270F395F13E8--INT_ASM_PRODUCTION/NA20850/assemblies/freeze_2/NA20850_hap1_hprc_r2_v1.0.1.fa.gz.fai"
"s3://human-pangenomics/submissions/DC27718F-5F38-43B0-9A78-270F395F13E8--INT_ASM_PRODUCTION/NA21102/assemblies/freeze_2/NA21102_hap1_hprc_r2_v1.0.1.fa.gz.fai"
"s3://human-pangenomics/submissions/DC27718F-5F38-43B0-9A78-270F395F13E8--INT_ASM_PRODUCTION/NA21144/assemblies/freeze_2/NA21144_hap1_hprc_r2_v1.0.1.fa.gz.fai"
"s3://human-pangenomics/submissions/DC27718F-5F38-43B0-9A78-270F395F13E8--INT_ASM_PRODUCTION/HG02514/assemblies/freeze_2/HG02514_mat_hprc_r2_v1.0.1.fa.gz.fai"
"s3://human-pangenomics/submissions/DC27718F-5F38-43B0-9A78-270F395F13E8--INT_ASM_PRODUCTION/HG02841/assemblies/freeze_2/HG02841_mat_hprc_r2_v1.0.1.fa.gz.fai"
"s3://human-pangenomics/submissions/DC27718F-5F38-43B0-9A78-270F395F13E8--INT_ASM_PRODUCTION/HG02984/assemblies/freeze_2/HG02984_mat_hprc_r2_v1.0.1.fa.gz.fai"
"s3://human-pangenomics/submissions/DC27718F-5F38-43B0-9A78-270F395F13E8--INT_ASM_PRODUCTION/HG03050/assemblies/freeze_2/HG03050_mat_hprc_r2_v1.0.1.fa.gz.fai"
"s3://human-pangenomics/submissions/DC27718F-5F38-43B0-9A78-270F395F13E8--INT_ASM_PRODUCTION/NA20799/assemblies/freeze_2/NA20799_hap2_hprc_r2_v1.0.1.fa.gz.fai"
"s3://human-pangenomics/submissions/DC27718F-5F38-43B0-9A78-270F395F13E8--INT_ASM_PRODUCTION/HG00733/assemblies/freeze_2/HG00733_mat_hprc_r2_v1.0.1.fa.gz.fai"
"s3://human-pangenomics/submissions/DC27718F-5F38-43B0-9A78-270F395F13E8--INT_ASM_PRODUCTION/HG01243/assemblies/freeze_2/HG01243_mat_hprc_r2_v1.0.1.fa.gz.fai"
"s3://human-pangenomics/submissions/DC27718F-5F38-43B0-9A78-270F395F13E8--INT_ASM_PRODUCTION/HG00097/assemblies/freeze_2/HG00097_hap2_hprc_r2_v1.0.1.fa.gz.fai"
"s3://human-pangenomics/submissions/DC27718F-5F38-43B0-9A78-270F395F13E8--INT_ASM_PRODUCTION/HG00235/assemblies/freeze_2/HG00235_hap2_hprc_r2_v1.0.1.fa.gz.fai"
"s3://human-pangenomics/submissions/DC27718F-5F38-43B0-9A78-270F395F13E8--INT_ASM_PRODUCTION/HG00253/assemblies/freeze_2/HG00253_hap2_hprc_r2_v1.0.1.fa.gz.fai"
"s3://human-pangenomics/submissions/DC27718F-5F38-43B0-9A78-270F395F13E8--INT_ASM_PRODUCTION/HG00272/assemblies/freeze_2/HG00272_hap2_hprc_r2_v1.0.1.fa.gz.fai"
"s3://human-pangenomics/submissions/DC27718F-5F38-43B0-9A78-270F395F13E8--INT_ASM_PRODUCTION/HG00329/assemblies/freeze_2/HG00329_hap2_hprc_r2_v1.0.1.fa.gz.fai"
"s3://human-pangenomics/submissions/DC27718F-5F38-43B0-9A78-270F395F13E8--INT_ASM_PRODUCTION/HG00344/assemblies/freeze_2/HG00344_hap2_hprc_r2_v1.0.1.fa.gz.fai"
"s3://human-pangenomics/submissions/DC27718F-5F38-43B0-9A78-270F395F13E8--INT_ASM_PRODUCTION/HG00350/assemblies/freeze_2/HG00350_hap2_hprc_r2_v1.0.1.fa.gz.fai"
"s3://human-pangenomics/submissions/DC27718F-5F38-43B0-9A78-270F395F13E8--INT_ASM_PRODUCTION/HG01167/assemblies/freeze_2/HG01167_hap2_hprc_r2_v1.0.1.fa.gz.fai"
"s3://human-pangenomics/submissions/DC27718F-5F38-43B0-9A78-270F395F13E8--INT_ASM_PRODUCTION/HG03369/assemblies/freeze_2/HG03369_hap2_hprc_r2_v1.0.1.fa.gz.fai"
"s3://human-pangenomics/submissions/DC27718F-5F38-43B0-9A78-270F395F13E8--INT_ASM_PRODUCTION/HG03521/assemblies/freeze_2/HG03521_hap2_hprc_r2_v1.0.1.fa.gz.fai"
"s3://human-pangenomics/submissions/DC27718F-5F38-43B0-9A78-270F395F13E8--INT_ASM_PRODUCTION/HG03784/assemblies/freeze_2/HG03784_hap2_hprc_r2_v1.0.1.fa.gz.fai"
"s3://human-pangenomics/submissions/DC27718F-5F38-43B0-9A78-270F395F13E8--INT_ASM_PRODUCTION/NA18565/assemblies/freeze_2/NA18565_hap2_hprc_r2_v1.0.1.fa.gz.fai"
"s3://human-pangenomics/submissions/DC27718F-5F38-43B0-9A78-270F395F13E8--INT_ASM_PRODUCTION/NA19682/assemblies/freeze_2/NA19682_hap2_hprc_r2_v1.0.1.fa.gz.fai"
"s3://human-pangenomics/submissions/DC27718F-5F38-43B0-9A78-270F395F13E8--INT_ASM_PRODUCTION/NA19776/assemblies/freeze_2/NA19776_hap2_hprc_r2_v1.0.1.fa.gz.fai"
"s3://human-pangenomics/submissions/DC27718F-5F38-43B0-9A78-270F395F13E8--INT_ASM_PRODUCTION/NA19835/assemblies/freeze_2/NA19835_hap2_hprc_r2_v1.0.1.fa.gz.fai"
"s3://human-pangenomics/submissions/DC27718F-5F38-43B0-9A78-270F395F13E8--INT_ASM_PRODUCTION/NA19909/assemblies/freeze_2/NA19909_hap2_hprc_r2_v1.0.1.fa.gz.fai"
"s3://human-pangenomics/submissions/DC27718F-5F38-43B0-9A78-270F395F13E8--INT_ASM_PRODUCTION/NA20282/assemblies/freeze_2/NA20282_hap2_hprc_r2_v1.0.1.fa.gz.fai"
"s3://human-pangenomics/submissions/DC27718F-5F38-43B0-9A78-270F395F13E8--INT_ASM_PRODUCTION/NA20346/assemblies/freeze_2/NA20346_hap2_hprc_r2_v1.0.1.fa.gz.fai"
"s3://human-pangenomics/submissions/DC27718F-5F38-43B0-9A78-270F395F13E8--INT_ASM_PRODUCTION/NA20809/assemblies/freeze_2/NA20809_hap2_hprc_r2_v1.0.1.fa.gz.fai"
"s3://human-pangenomics/submissions/DC27718F-5F38-43B0-9A78-270F395F13E8--INT_ASM_PRODUCTION/NA20850/assemblies/freeze_2/NA20850_hap2_hprc_r2_v1.0.1.fa.gz.fai"
"s3://human-pangenomics/submissions/DC27718F-5F38-43B0-9A78-270F395F13E8--INT_ASM_PRODUCTION/NA21102/assemblies/freeze_2/NA21102_hap2_hprc_r2_v1.0.1.fa.gz.fai"
"s3://human-pangenomics/submissions/DC27718F-5F38-43B0-9A78-270F395F13E8--INT_ASM_PRODUCTION/NA21144/assemblies/freeze_2/NA21144_hap2_hprc_r2_v1.0.1.fa.gz.fai"
)

# Loop through each file and download it
for file in "${files[@]}"; do
    echo "Downloading $file..."
    aws s3 cp "$file" . &
done

## checked these by eye to make sure there was a mito sized contig in mat but not pat. all these are fine.

###############################################################################
##                                    DONE                                   ##
###############################################################################