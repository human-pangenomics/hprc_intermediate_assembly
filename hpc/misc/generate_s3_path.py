#!/usr/bin/env python3

import csv
import sys
import argparse
import ast
from pathlib import Path

def generate_s3_paths(data_csv, mapping_csv, s3_base_path):
    # Read the mapping CSV into a list
    mapping = []
    with open(mapping_csv, newline='') as map_file:
        reader = csv.DictReader(map_file)
        for row in reader:
            mapping.append({'column_name': row['column_name'], 'destination': row['destination']})
    
    # Read the data CSV and create a new CSV with S3 paths
    output_rows = []
    
    with open(data_csv, newline='') as data_file:
        reader = csv.DictReader(data_file)
        
        # Ensure the required columns exist in the data CSV
        for map_row in mapping:
            if map_row['column_name'] not in reader.fieldnames:
                print(f"Error: {map_row['column_name']} column not found in the data CSV.")
                sys.exit(1)
        
        # Create header for output CSV
        fieldnames = reader.fieldnames.copy()
        
        # Add new S3 path columns
        for map_row in mapping:
            fieldnames.append(f"{map_row['column_name']}_s3_path")
        
        # Process each row
        for data_row in reader:
            new_row = data_row.copy()
            sample_id = data_row['sample_id']
            
            for map_row in mapping:
                column_name = map_row['column_name']
                destination_template = map_row['destination']
                
                file_paths = data_row[column_name]
                
                # Replace {sample_id} in the destination template
                destination_dir = destination_template.format(sample_id=sample_id)
                
                # Remove leading 'upload/' if present
                if destination_dir.startswith('upload/'):
                    destination_dir = destination_dir[7:]
                
                # Attempt to parse the file paths as a list (array)
                try:
                    file_paths = ast.literal_eval(file_paths)
                    if not isinstance(file_paths, list):
                        file_paths = [file_paths]
                except (ValueError, SyntaxError):
                    file_paths = [file_paths]
                
                # Create S3 paths
                s3_paths = []
                for file_path in file_paths:
                    if file_path:  # Skip empty paths
                        filename = Path(file_path).name
                        s3_path = f"{s3_base_path.rstrip('/')}/{destination_dir}{filename}"
                        s3_paths.append(s3_path)
                
                # Add the S3 path to the row (join multiple paths with semicolon if present)
                new_row[f"{column_name}_s3_path"] = ';'.join(s3_paths) if s3_paths else ''
            
            output_rows.append(new_row)
    
    # Write the output CSV
    output_filename = data_csv.rsplit('.', 1)[0] + '_with_s3_paths.csv'
    with open(output_filename, 'w', newline='') as outfile:
        writer = csv.DictWriter(outfile, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(output_rows)
    
    print(f"Generated S3 paths written to: {output_filename}")

if __name__ == "__main__":
    # Setup argument parsing
    parser = argparse.ArgumentParser(description="Generate S3 paths based on a mapping CSV and a data CSV.")
    parser.add_argument("--csv_file", required=True, help="Path to the data CSV file.")
    parser.add_argument("--mapping_csv", required=True, help="Path to the mapping CSV file.")
    parser.add_argument("--s3_base_path", required=True, 
                      help="Base S3 path (e.g., s3://human-pangenomics/submissions/DC27718F-5F38-43B0-9A78-270F395F13E8--INT_ASM_PRODUCTION)")
    
    # Parse the arguments
    args = parser.parse_args()
    
    # Generate the S3 paths
    generate_s3_paths(args.csv_file, args.mapping_csv, args.s3_base_path)