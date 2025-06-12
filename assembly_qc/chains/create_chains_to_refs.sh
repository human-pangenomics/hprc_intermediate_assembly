cd /private/groups/hprc/qc

mkdir -p chains/cactus-hal2chains
cd chains/cactus-hal2chains

###############################################################################
##                               Setup Node                                  ##
###############################################################################

srun \
    --partition=long \
    --time=10:00:00 \
    --ntasks=1 \
    --nodes=1 \
    --cpus-per-task=128 \
    --mem=800GB \
    --pty /bin/bash

source /private/groups/cgl/cactus/venv-cactus-latest/bin/activate

## check that binaries work (they do)
halStats --genomes /private/groups/cgl/hprc-graphs/hprc-v2.0-feb28/hprc-v2.0-mc-grch38/hprc-v2.0-mc-grch38.full.hal


mkdir -p logs/batch_logs

export SHARED_FILESYSTEM_RUNFOLDER=`pwd`


###############################################################################
##                        hal2chains: GRCh38-Based                           ##
###############################################################################

LOCAL_FOLDER=/data/tmp/$(whoami)/hal2chains_grch38
mkdir -p ${LOCAL_FOLDER}

## put HAL file (~400GB) on local storage for this node
cp \
    /private/groups/cgl/hprc-graphs/hprc-v2.0-feb28/hprc-v2.0-mc-grch38/hprc-v2.0-mc-grch38.full.hal \
    ${LOCAL_FOLDER}/hprc-v2.0-mc-grch38.full.hal


cactus-hal2chains \
    "${LOCAL_FOLDER}/jobstore" \
    ${LOCAL_FOLDER}/hprc-v2.0-mc-grch38.full.hal \
    "${SHARED_FILESYSTEM_RUNFOLDER}/chains-to-grch38" \
    --batchSystem single_machine \
    --batchLogsDir "${SHARED_FILESYSTEM_RUNFOLDER}/logs/batch_logs" \
    --maxCores 100 \
    --doubleMem true \
    --logFile "${SHARED_FILESYSTEM_RUNFOLDER}/logs/grch38.log.txt" \
    --queryGenomes GRCh38 \
    --bigChain \
    --noStdOutErr

###############################################################################
##                        hal2chains: CHM13-Based                            ##
###############################################################################

LOCAL_FOLDER=/data/tmp/$(whoami)/hal2chains_chm13
mkdir -p ${LOCAL_FOLDER}

cp \
    /private/groups/cgl/hprc-graphs/hprc-v2.0-feb28/hprc-v2.0-mc-chm13/hprc-v2.0-mc-chm13.full.hal \
    ${LOCAL_FOLDER}/hprc-v2.0-mc-chm13.full.hal


cactus-hal2chains \
    "${LOCAL_FOLDER}/jobstore" \
    ${LOCAL_FOLDER}/hprc-v2.0-mc-chm13.full.hal \
    "${SHARED_FILESYSTEM_RUNFOLDER}/chains-to-chm13" \
    --batchSystem single_machine \
    --batchLogsDir "${SHARED_FILESYSTEM_RUNFOLDER}/logs/batch_logs" \
    --maxCores 100 \
    --doubleMem true \
    --logFile "${SHARED_FILESYSTEM_RUNFOLDER}/logs/chm13.log.txt" \
    --queryGenomes CHM13 \
    --bigChain \
    --noStdOutErr


## Clean up! 
# rm /data/tmp/juklucas/hal2chains_chm13/hprc-v2.0-mc-chm13.full.hal
# rm /data/tmp/juklucas/hal2chains_grch38/hprc-v2.0-mc-grch38.full.hal


###############################################################################
##                          Upload To HPRC Bucket                            ##
###############################################################################

cd /private/groups/hprc/qc/chains/cactus-hal2chains

python3 << 'EOL'
#!/usr/bin/env python3
import os
import csv
import re
from collections import defaultdict

# Directory path
dir_paths = [
    "/private/groups/hprc/qc/chains/cactus-hal2chains/chains-to-grch38/"
]
# Dictionary to store files by sample_id
samples = defaultdict(lambda: {"hap1_chain": "", "hap1_bigChain": "", "hap1_bigChain_link": "",
                              "hap2_chain": "", "hap2_bigChain": "", "hap2_bigChain_link": ""})


# Regular expressions to extract sample_id and haplotype
grch38_pattern = re.compile(r"(.+?)\.([12])_(vs_GRCh38\..*)")
chm13_pattern = re.compile(r"(.+?)\.([12])_(vs_CHM13\..*)")

for dir_path in dir_paths:
    if not os.path.exists(dir_path):
        print(f"Warning: Directory {dir_path} does not exist. Skipping.")
        continue
        
    # Determine which pattern to use based on directory path
    if "chains-to-grch38" in dir_path:
        pattern = grch38_pattern
        ref = "GRCh38"
    else:
        pattern = chm13_pattern
        ref = "CHM13"

    # List files in the directory
    for filename in os.listdir(dir_path):
        match = pattern.match(filename)
        if match:
            sample_id = f"{match.group(1)}"
            haplotype = match.group(2)
            file_type = match.group(3)
            
            # Determine file type and update dictionary
            if f"vs_{ref}.chain.gz" in file_type:
                samples[sample_id][f"hap{haplotype}_chain"] = os.path.join(dir_path, filename)
            elif f"vs_{ref}.bigChain.bb" == file_type:
                samples[sample_id][f"hap{haplotype}_bigChain"] = os.path.join(dir_path, filename)
            elif f"vs_{ref}.bigChain.link.bb" == file_type:
                samples[sample_id][f"hap{haplotype}_bigChain_link"] = os.path.join(dir_path, filename)


# Write to CSV
output_file = "chains-to-ref_grch38.csv"

with open(output_file, 'w', newline='') as csvfile:
    fieldnames = ["sample_id", "hap1_chain", "hap1_bigChain", "hap1_bigChain_link", 
                 "hap2_chain", "hap2_bigChain", "hap2_bigChain_link"]
    writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
    
    writer.writeheader()
    for sample_id, files in samples.items():
        row = {"sample_id": sample_id}
        row.update(files)
        writer.writerow(row)

print(f"CSV file '{output_file}' has been created.")
EOL

# "/private/groups/hprc/qc/chains/cactus-hal2chains/chains-to-chm13/"
# output_file = "chains-to-ref_chm13.csv"
# "/private/groups/hprc/qc/chains/cactus-hal2chains/chains-to-grch38/",
# output_file = "chains-to-ref_grch38.csv"


mkdir -p s3_upload
cd s3_upload


cat <<EOF > chains_upload_linking_map.csv
column_name,destination
hap1_chain,upload/{sample_id}/assemblies/freeze_2/annotation/chains/minigraph-cactus/
hap1_bigChain,upload/{sample_id}/assemblies/freeze_2/annotation/chains/minigraph-cactus/
hap1_bigChain_link,upload/{sample_id}/assemblies/freeze_2/annotation/chains/minigraph-cactus/
hap2_chain,upload/{sample_id}/assemblies/freeze_2/annotation/chains/minigraph-cactus/
hap2_bigChain,upload/{sample_id}/assemblies/freeze_2/annotation/chains/minigraph-cactus/
hap2_bigChain_link,upload/{sample_id}/assemblies/freeze_2/annotation/chains/minigraph-cactus/
EOF


python3 /private/groups/hprc/hprc_intermediate_assembly/hpc/misc/link_to_subfolder.py \
     --csv_file ../chains-to-ref_chm13.csv \
     --mapping_csv chains_upload_linking_map.csv

python3 /private/groups/hprc/hprc_intermediate_assembly/hpc/misc/link_to_subfolder.py \
     --csv_file ../chains-to-ref_grch38.csv \
     --mapping_csv chains_upload_linking_map.csv
     

###############################################################################
##                                DONE                                       ##
###############################################################################

wget https://raw.githubusercontent.com/human-pangenomics/hprc_intermediate_assembly/refs/heads/main/data_tables/assemblies_pre_release_v0.6.1.index.csv


cat <<'EOF' > rename_chain_files.sh
#!/bin/bash

set -euo pipefail

index="assemblies_pre_release_v0.6.1.index.csv"
dry_run=false

# Check for --dry-run flag
if [[ "${1:-}" == "--dry-run" ]]; then
    dry_run=true
fi

# Read CSV into associative array: key = sample.hap, value = assembly_name
declare -A assembly_map
while IFS=',' read -r sample hap phasing method version date asm_name source acc md5 fai gzi asm; do
    if [[ "$sample" == "sample_id" ]]; then continue; fi
    key="${sample}.${hap}"
    assembly_map[$key]="$asm_name"
done < "$index"

# Find relevant symlinks
find upload/*/assemblies/freeze_2/annotation/chains/minigraph-cactus/ \
    -type l \( -name '*.bb' -o -name '*.chain.gz' \) | while read -r filepath; do

    filename=$(basename "$filepath")

    # Match e.g., HG00408.1_vs_CHM13.bigChain.bb or HG00408.1_vs_GRCh38.chain.gz
    if [[ "$filename" =~ ^([A-Z]+[0-9]+)\.([12])_vs_([^_]+)(.+)$ ]]; then
        sample="${BASH_REMATCH[1]}"
        hap="${BASH_REMATCH[2]}"
        ref="${BASH_REMATCH[3]}"
        suffix="${BASH_REMATCH[4]}"
        key="${sample}.${hap}"
        new_prefix="${assembly_map[$key]}"
        
        if [[ -n "$new_prefix" ]]; then
            new_filename="${new_prefix}_vs_${ref}${suffix}"
            new_path="$(dirname "$filepath")/$new_filename"

            echo "relink: $filename → $new_filename"
            if ! $dry_run; then
                ln -sf "$(readlink "$filepath")" "$new_path"
                rm "$filepath"
            fi
        else
            echo "Warning: No match found for ${sample}.${hap}"
        fi
    else
        echo "Skipping unrecognized filename: $filename"
    fi
done
EOF

chmod +x rename_chain_files.sh
./rename_chain_files.sh


###############################################################################
##                            Actual Upload                                  ##
###############################################################################

ssds staging upload \
    --submission-id DC27718F-5F38-43B0-9A78-270F395F13E8 \
    upload \
    &>>chains_s3_upload.stderr


###############################################################################
##                              Create Index: CHM13-Based                    ##
###############################################################################

aws s3 ls \
    --recursive \
    s3://human-pangenomics/submissions/DC27718F-5F38-43B0-9A78-270F395F13E8--INT_ASM_PRODUCTION/ \
    | awk '{ print $4 }' | grep -e "_vs_CHM13.chain.gz" \
    > chm13_chains_locs.txt

sed -i 's/^/s3:\/\/human-pangenomics\//' \
    chm13_chains_locs.txt

#!/bin/bash

echo "sample_id,haplotype,assembly_name,location" > chains_to_chm13_v0.1.index.csv

while read -r uri; do

    ## will be of the form "HG00423_mat_hprc_r2_v1.0.1_vs_CHM13.chain.gz"
    filename=$(basename "$uri")

    sample_id=$(echo "$filename" | cut -d'_' -f1)

    hap_string=$(echo "$filename" | cut -d'_' -f2)
    if [[ "$hap_string" == "hap1" || "$hap_string" == "pat" ]]; then
        hap_int=1
    elif [[ "$hap_string" == "hap2" || "$hap_string" == "mat" ]]; then
        hap_int=2
    else
        hap_int=NA
    fi

    assembly_name=$(echo "$filename" | sed 's/_vs_.*//')

    echo "$sample_id,$hap_int,$assembly_name,$uri" >> chains_to_chm13_v0.1.index.csv
done < chm13_chains_locs.txt

## had to fix HG002 by hand since it's naming is different.


###############################################################################
##                              Create Index: GRCh38-Based                   ##
###############################################################################

aws s3 ls \
    --recursive \
    s3://human-pangenomics/submissions/DC27718F-5F38-43B0-9A78-270F395F13E8--INT_ASM_PRODUCTION/ \
    | awk '{ print $4 }' | grep -e "_vs_GRCh38.chain.gz" \
    > grch38_chains_locs.txt

sed -i 's/^/s3:\/\/human-pangenomics\//' \
    grch38_chains_locs.txt

#!/bin/bash

echo "sample_id,haplotype,assembly_name,location" > chains_to_grch38_v0.1.index.csv

while read -r uri; do

    ## will be of the form "HG00423_mat_hprc_r2_v1.0.1_vs_GRCh38.chain.gz"
    filename=$(basename "$uri")

    sample_id=$(echo "$filename" | cut -d'_' -f1)

    hap_string=$(echo "$filename" | cut -d'_' -f2)
    if [[ "$hap_string" == "hap1" || "$hap_string" == "pat" ]]; then
        hap_int=1
    elif [[ "$hap_string" == "hap2" || "$hap_string" == "mat" ]]; then
        hap_int=2
    else
        hap_int=NA
    fi

    assembly_name=$(echo "$filename" | sed 's/_vs_.*//')

    echo "$sample_id,$hap_int,$assembly_name,$uri" >> chains_to_grch38_v0.1.index.csv
done < grch38_chains_locs.txt

## had to fix HG002 by hand since it's naming is different.


###############################################################################
##                              Update Git                                   ##
###############################################################################

cd /private/groups/hprc/qc/chains/cactus-hal2chains

## copy to github repo for notetaking
cp chains-to-ref_*.csv \
     /private/groups/hprc/hprc_intermediate_assembly/assembly_qc/chains/


cp s3_upload/chains_to_chm13_v0.1.index.csv \
    /private/groups/hprc/hprc_intermediate_assembly/assembly_qc/chains/mc_chains_to_chm13_v0.1.index.csv

cp s3_upload/chains_to_grch38_v0.1.index.csv \
    /private/groups/hprc/hprc_intermediate_assembly/assembly_qc/chains/mc_chains_to_grch38_v0.1.index.csv


###############################################################################
##                                DONE                                       ##
###############################################################################