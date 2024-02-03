import csv
import json
import os
import argparse

## Call with
# python3 update_table_with_outputs.py \
#      --input_data_table test.csv \
#      --output_data_table test_updated.csv \
#      --json_location '{sample_id}/{sample_id}_hifiasm_output.json' \
#      --field_mapping mapping.csv (optional) \
#      --submit_logs_directory (optional)


# Note on optional field mapping file:

# If none is provided all json keys are added to output CSV.
# If one is provided, keys in the json are looked up and the output CSV
# has a column with the name specified for that key. If no key mapping is found
# then the key is not written to the output (useful for workflows with a lot of
# outputs.)

# Note on optional submit logs directory:

# if the location of the submit logs directory in cwd is provided, the log for each sample
# run will be added to the outputs data table also. The sample ID must be the first
# line of each submit log in this directory

###############################################################################
##                          Function Definitions                             ##
###############################################################################

def read_json_file(file_path):
    if os.path.exists(file_path) and os.path.getsize(file_path) > 0:
        with open(file_path, 'r') as file:
            return json.load(file)
    return None

def read_mapping_csv(mapping_csv_path):
    mapping = {}
    if os.path.exists(mapping_csv_path):
        with open(mapping_csv_path, mode='r', newline='', encoding='utf-8-sig') as file:
            reader = csv.DictReader(file)
            header = reader.fieldnames
            # Check if the header matches the expected values
            if header != ['json_key', 'output_name']:
                raise ValueError("Mapping CSV does not have the required header ['json_key', 'output_name']")

            for row in reader:
                mapping[row['json_key']] = row['output_name']
    return mapping

def validate_csv_header(csv_file_path):
    with open(csv_file_path, mode='r', newline='', encoding='utf-8-sig') as file:
        reader = csv.reader(file)
        header = next(reader, None)
        if not header or header[0] != 'sample_id':
            raise ValueError("Input CSV file does not have 'sample_id' as its first column")

def parse_submit_logs(submit_logs_directory, base_dir):
    submit_logs_dict={}
    dir=os.path.join(base_dir, submit_logs_directory)
    if os.path.exists(dir):
        for filename in os.listdir(dir):
            filepath=os.path.join(dir, filename)
            with open(filepath) as f:
                sampleID = f.readline().strip('\n')
            submit_logs_dict[sampleID] = filepath
    else:
        raise ValueError("Invalid submit logs directory path")

    return submit_logs_dict

def update_csv_with_json(csv_file_path, output_csv_path, json_pattern, mapping_csv_path=None,submit_logs_directory=None):
    updated_rows = []
    header_updated = False
    base_dir = os.getcwd()
    mapping = read_mapping_csv(mapping_csv_path) if mapping_csv_path else {}
    submit_logs_dict=parse_submit_logs(submit_logs_directory,base_dir) if submit_logs_directory else {}

    validate_csv_header(csv_file_path)  # Validate the header of the input CSV file

    with open(csv_file_path, mode='r', newline='', encoding='utf-8-sig') as file:
        reader = csv.DictReader(file)
        fieldnames = reader.fieldnames.copy()

        for row in reader:
            sample_id = row.get('sample_id')

            sample_dir = os.path.join(base_dir, sample_id)
            json_file_path = os.path.join(sample_dir, json_pattern.format(sample_id=sample_id))
            json_data = read_json_file(json_file_path)

            if json_data:
                for key, value in json_data.items():
                    key = key.split('.')[1]
                    if mapping_csv_path and key not in mapping:
                        continue

                    column_name = mapping.get(key, key)
                    if column_name not in fieldnames:
                        fieldnames.append(column_name)
                        header_updated = True

                    value_with_path = os.path.join(sample_dir, value)
                    row[column_name] = value_with_path

            if submit_logs_directory:
                column_name="Submission_Log_filepath"
                if column_name not in fieldnames:
                    fieldnames.append(column_name)
                    header_updated = True
                try:
                    row[column_name]=submit_logs_dict[sample_id]
                except:
                    row[column_name]="NA"

            updated_rows.append(row)

        if header_updated:
            with open(output_csv_path, mode='w', newline='') as write_file:
                writer = csv.DictWriter(write_file, fieldnames=fieldnames)
                writer.writeheader()
                writer.writerows(updated_rows)


def main():
    parser = argparse.ArgumentParser(description='Update a CSV file with data from JSON files.')

    parser.add_argument('--input_data_table', '-d', type=str, action='store',
                        help='Path to the input CSV file. Should have one sample per row.')
    parser.add_argument('--output_data_table', '-o', default='output.csv', type=str, action='store',
                        help='Path to the output CSV file')
    parser.add_argument('--json_location', '-j', default='{sample_id}_hifiasm_outputs.json', type=str, action='store',
                        help='location and name relative to CWD of the output JSON files, use {sample_id} as placeholder for sample ID')
    parser.add_argument('--field_mapping', '-m', type=str, action='store',
                        help='Optional path to the mapping CSV file', default=None)
    parser.add_argument('--submit_logs_directory', '-s', type=str, action='store',
                        help='Optional path to submit logs for sbatch array run, relative to cwd', default=None)
    args = parser.parse_args()

    update_csv_with_json(args.input_data_table, args.output_data_table, args.json_location, args.field_mapping, args.submit_logs_directory)


if __name__ == '__main__':
    main()
