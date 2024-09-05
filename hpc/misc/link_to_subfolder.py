import os
import csv
import sys
import argparse
import ast

def create_symlinks(data_csv, mapping_csv):
    # Read the mapping CSV into a dictionary
    mapping = []
    with open(mapping_csv, newline='') as map_file:
        reader = csv.DictReader(map_file)
        for row in reader:
            mapping.append({'column_name': row['column_name'], 'destination': row['destination']})
    
    # Open the data CSV
    with open(data_csv, newline='') as data_file:
        reader = csv.DictReader(data_file)
        
        # Ensure the required columns exist in the data CSV
        for map_row in mapping:
            if map_row['column_name'] not in reader.fieldnames:
                print(f"Error: {map_row['column_name']} column not found in the data CSV.")
                sys.exit(1)
        
        # Iterate over each row in the data CSV
        for data_row in reader:
            sample_id = data_row['sample_id']
            
            for map_row in mapping:
                column_name = map_row['column_name']
                destination_template = map_row['destination']
                
                file_paths = data_row[column_name]
                
                # Replace {sample_id} in the destination template
                destination_dir = destination_template.format(sample_id=sample_id)
                
                # Attempt to parse the file paths as a list (array)
                try:
                    file_paths = ast.literal_eval(file_paths)
                    if not isinstance(file_paths, list):
                        file_paths = [file_paths]
                except (ValueError, SyntaxError):
                    file_paths = [file_paths]

                # Create the destination directory if it doesn't exist
                os.makedirs(destination_dir, exist_ok=True)
                
                # Create the symbolic link in the destination directory
                for file_path in file_paths:
                    try:
                        if os.path.exists(file_path):
                            link_name = os.path.join(destination_dir, os.path.basename(file_path))
                            
                            # Check if the link name already exists and add a suffix if necessary
                            suffix = 1
                            while os.path.exists(link_name):
                                if suffix > 20:
                                    print(f"Error: Too many files with the same name ({file_path}) in {destination_dir}. Aborting.")
                                    sys.exit(1)
                                link_name = os.path.join(destination_dir, f"{os.path.basename(file_path)}.{suffix}")
                                suffix += 1
                            
                            os.symlink(file_path, link_name)
                        else:
                            print(f"Warning: {file_path} does not exist for sample_id {sample_id}.")
                    
                    except OSError as e:
                        print(f"Error creating symbolic link for {file_path} in {destination_dir}: {e}")
    
    print("Symbolic links created successfully.")

if __name__ == "__main__":
    # Setup argument parsing
    parser = argparse.ArgumentParser(description="Create symbolic links based on a mapping CSV and a data CSV.")
    parser.add_argument("--csv_file", required=True, help="Path to the data CSV file.")
    parser.add_argument("--mapping_csv", required=True, help="Path to the mapping CSV file.")
    
    # Parse the arguments
    args = parser.parse_args()
    
    # Run the symbolic link creation process
    create_symlinks(args.csv_file, args.mapping_csv)
