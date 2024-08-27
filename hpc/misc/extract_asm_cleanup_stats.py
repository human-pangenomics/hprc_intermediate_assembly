import os
import pandas as pd
import argparse

import warnings
warnings.simplefilter(action='ignore', category=FutureWarning)

###############################################################################
##                              Function Def                                 ##
###############################################################################

def extract_file_name(file_path):
    '''Extract the file name from a file path'''
    return os.path.basename(file_path)

def read_report_file(file_path):
    '''Read in the report file, skip comments, and add the filename as the first column'''
    skip_lines = 0
    header_line = None
    
    # First, read through the file to count comment lines and find the actual header
    with open(file_path, 'r') as f:
        for line in f:
            line = line.strip()
            skip_lines += 1
            if line.startswith("##"):
                continue  # Skip comment lines
            elif line.startswith("#"):
                header_line = line[1:].strip()  # Strip the leading '#' from the header
                break
            else:
                header_line = line.strip()  # If no '#', assume it's the header
                break

    # Split the header line into column names
    columns = header_line.split('\t')
    
    try:
        df = pd.read_csv(file_path, sep='\t', skiprows=skip_lines, names=columns)
    except pd.errors.EmptyDataError:
        # If the file only contains a header, create an empty DataFrame with the columns and NaN values
        df = pd.DataFrame(columns=columns)

    # Handle the case where the file is empty except for the header
    if df.empty:
        df = pd.DataFrame(columns=columns)
        df.loc[0] = [None] * len(columns)

    # Add the filename as the first column
    df.insert(0, 'file_name', extract_file_name(file_path))

    return df

def aggregate_report_files(report_file_paths):
    '''Aggregate all report files into a single dataframe, ensuring headers are handled correctly'''
    aggregated_df = pd.DataFrame()

    for file_path in report_file_paths:
        if pd.notna(file_path):  # Ensure the file path is not NaN
            df = read_report_file(file_path)
            aggregated_df = pd.concat([aggregated_df, df], ignore_index=True)
                
    return aggregated_df

def process_qc_outputs(input_df, column1, column2=None):
    '''Process the QC files by extracting file names and aggregating report files'''
    # Extract file names from the fasta columns
    # input_df['hap1_output_fasta_name'] = input_df['hap1_output_fasta_gz'].apply(extract_file_name)
    # input_df['hap2_output_fasta_name'] = input_df['hap2_output_fasta_gz'].apply(extract_file_name)
    
    if column2 is None:
        combined_reports_df    = aggregate_report_files(input_df[column1])
    else:
        hap1_report_aggregated = aggregate_report_files(input_df[column1])
        hap2_report_aggregated = aggregate_report_files(input_df[column2])
    
        combined_reports_df    = pd.concat([hap1_report_aggregated, hap2_report_aggregated], ignore_index=True)

    return combined_reports_df

###############################################################################
##                                 MAIN                                      ##
###############################################################################

def main():
    parser = argparse.ArgumentParser(description='Read a CSV file with file paths, extract and aggregate report files, and write the result.')

    parser.add_argument('--input_csv', '-i', type=str, action='store',
                        help='Path to the input CSV file. Should have one sample per row.')
    parser.add_argument('--output_prefix', '-o', type=str, action='store',
                        help='Output prefix for extracted results')

    args = parser.parse_args()

    input_csv     = args.input_csv
    output_prefix = args.output_prefix

    # Read input CSV
    input_df = pd.read_csv(args.input_csv)


    fcs_gx_output_name = f"{output_prefix}_gx_results_aggregated.csv"
    fcs_gx_aggregated_results = process_qc_outputs(input_df, 'fcs_hap1_gx_report', 'fcs_hap2_gx_report')
    fcs_gx_aggregated_results.to_csv(fcs_gx_output_name, index=False)

    fcs_ad_output_name = f"{output_prefix}_fcs_adapter_results_aggregated.csv"
    fcs_adapter_aggregated_results = process_qc_outputs(input_df, 'fcs_hap1_adapter_report', 'fcs_hap2_adapter_report')
    fcs_adapter_aggregated_results.to_csv(fcs_ad_output_name, index=False)

    mito_stats_output_name = f"{output_prefix}_mitohifi_aggregated_stats.csv"    
    mitohifi_aggregated_stats = process_qc_outputs(input_df, 'mitoHiFi_stats')
    mitohifi_aggregated_stats.to_csv(mito_stats_output_name, index=False)    

if __name__ == '__main__':
    main()

###############################################################################
##                                 DONE                                      ##
###############################################################################
