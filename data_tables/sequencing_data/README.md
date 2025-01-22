# Release 2 Sequencing Data

The release 2 sequencing data tables is synchronized from the latest samples [assemblies_pre_release_version.index.csv](https://github.com/human-pangenomics/hprc_intermediate_assembly/blob/main/data_tables/assemblies_pre_release_v0.5.index.csv) to the most recent [HPRC_metadata/main/data/hprc-data-explorer-tables](https://github.com/human-pangenomics/HPRC_metadata/tree/main/data/hprc-data-explorer-tables).

## How to download
Assembly sequencing data can be downloaded using the path column in the data_SequencingTechnology_pre_release.index.csv file.

### Example:
Individual sequence files can be downloaded via the AWS CLI using the following command:

```
aws s3 --no-sign-request cp \
   s3://human-pangenomics/working/HPRC/HG00558/raw_data/nanopore/guppy_6/02_08_22_R941_HG00558_1_Guppy_6.5.7_450bps_modbases_5mc_cg_sup_prom_pass.bam \
   ./
```

### Downloading All Files Using the Sequencing Technology Index Files:

If you want to download all the assembly sequencing data files listed in the technology index files, you can use the following script:

```bash
# Get the sequence summary files
wget https://github.com/human-pangenomics/hprc_intermediate_assembly/raw/main/data_tables/sequencing_data/data_deepconsensus_pre_release.index.csv
wget https://github.com/human-pangenomics/hprc_intermediate_assembly/raw/main/data_tables/sequencing_data/data_hic_pre_release.index.csv
wget https://github.com/human-pangenomics/hprc_intermediate_assembly/raw/main/data_tables/sequencing_data/data_hifi_pre_release.index.csv
wget https://github.com/human-pangenomics/hprc_intermediate_assembly/raw/main/data_tables/sequencing_data/data_illumina_pre_release.index.csv
wget https://github.com/human-pangenomics/hprc_intermediate_assembly/raw/main/data_tables/sequencing_data/data_ont_pre_release.index.csv

# Function to process each file
download_files_from_index() {
    local index_file=$1
    local path_column_name="path"

    echo "Processing $index_file..."

    # Extract the 'path' column and download files
    tail -n +2 "$index_file" | awk -F',' -v column="$path_column_name" -v index_file="$index_file" '
    BEGIN {
        # Find the column number for "path" dynamically
        getline header < index_file;
        split(header, fields, ",");
        for (i in fields) {
            if (fields[i] == column) {
                col_num = i;
                break;
            }
        }
    }
    { print $col_num }' | while read -r file_path; do
        echo "Downloading $file_path..."
        aws s3 --no-sign-request cp "$file_path" .
    done
}

# Process each sequence summary file
for index_file in \
    data_deepconsensus_pre_release.index.csv \
    data_hic_pre_release.index.csv \
    data_hifi_pre_release.index.csv \
    data_illumina_pre_release.index.csv \
    data_ont_pre_release.index.csv; do
    download_files_from_index "$index_file"
done

```

## Sequence Index File

### Oxford Nanopore Technologies

[data_ont_pre_release.index.csv](https://github.com/human-pangenomics/hprc_intermediate_assembly/blob/main/data_tables/sequencing_data/data_ont_pre_release.index.csv)

### PacBio HiFi
[data_hifi_pre_release.index.csv](https://github.com/human-pangenomics/hprc_intermediate_assembly/blob/main/data_tables/sequencing_data/data_hifi_pre_release.index.csv)

[data_deepconsensus_pre_release.index.csv](https://github.com/human-pangenomics/hprc_intermediate_assembly/blob/main/data_tables/sequencing_data/data_deepconsensus_pre_release.index.csv)

### HiC
[data_hic_pre_release.index.csv](https://github.com/human-pangenomics/hprc_intermediate_assembly/blob/main/data_tables/sequencing_data/data_hic_pre_release.index.csv)

### Illumina 1K Genomes
[data_illumina_pre_release.index.csv](https://github.com/human-pangenomics/hprc_intermediate_assembly/blob/main/data_tables/sequencing_data/data_illumina_pre_release.index.csv)
* NHGRI AnVIL Dataset Catalog Consortia: 1000G Workspace (Terra): [1000G-high-coverage-2019](https://anvil.terra.bio/#workspaces/anvil-datastorage/1000G-high-coverage-2019)

## Sequence Index File Change Log
```
* v0.5 (2025 Jan 22): Add assembly phasing metadata to Illumina table.
```

