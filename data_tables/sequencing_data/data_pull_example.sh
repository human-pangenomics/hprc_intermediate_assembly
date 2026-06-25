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
