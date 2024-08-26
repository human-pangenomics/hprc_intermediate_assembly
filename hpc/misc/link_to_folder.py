import os
import csv
import sys
import argparse

## This script reads in a data table and soft links in all of the files held
## in the filepaths under the columns provided. Use this script if you want
## to put a bunch of files all in one place. (For upload to Genbank, for example.)

## Example call:
# python3 link_to_folder.py \
#      --data_table_csv example_data_table.csv \
#      --columns_to_link assembly_output_hap1 assembly_output_hap2 \
#      --target_dir example_upload_folder

###############################################################################
##                          Function Definitions                             ##
###############################################################################

def create_symlinks(csv_file, columns, target_dir):
    '''
    read in csv file (which holds a data table) and soft link all files in the 
    columns provided into the target directory. 
    '''

    os.makedirs(target_dir, exist_ok=True)
    
    # Open the CSV file
    with open(csv_file, newline='') as f:
        reader = csv.DictReader(f)
        
        # Ensure the required columns exist
        for col in columns:
            if col not in reader.fieldnames:
                print(f"Error: {col} column not found in the CSV.")
                sys.exit(1)
        
        # Iterate over each row in the CSV
        for row in reader:
            for col in columns:
                print(col)
                file_path = row[col]
                
                # Create symbolic links in the target directory
                try:
                    if os.path.exists(file_path):
                        os.symlink(file_path, os.path.join(target_dir, os.path.basename(file_path)))
                    else:
                        print(f"Warning: {file_path} does not exist.")
                
                except OSError as e:
                    print(f"Error creating symbolic link for {file_path}: {e}")
    
    print(f"Symbolic links created successfully in {target_dir}.")


###############################################################################
##                                    Main                                   ##
###############################################################################

def main():

    parser = argparse.ArgumentParser(description="Create symbolic links for files listed in specific CSV columns.")
    parser.add_argument("--data_table_csv", required=True, help="Data table CSV file. Should contain a header which contains the columns listed in columns_to_link.")
    parser.add_argument("--columns_to_link", required=True, nargs='+', help="List of columns which hold the files to link into the target_dir.")
    parser.add_argument("--target_dir", required=True, help="Directory where the symbolic links will be created.")
    
    args = parser.parse_args()
    
    ## link files held in columns_to_link of the data_table_csv to the target_dir
    create_symlinks(args.data_table_csv, args.columns_to_link, args.target_dir)

if __name__ == '__main__':
    main()