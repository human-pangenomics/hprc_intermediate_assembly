#!/usr/bin/env python3
## script to take in a genome info file from Genbank's Genome Submission portal and 
## find the Genbank IDs for each assembly. Reformats the file from long to wide so 
## each row represents a sample.

## requires ncbi_datasets to be installed

# python3 lookup_genbank_accessions.py \
#     genbank_genome_info_file.tsv \
#     genbank_accession_ids.csv 

## Takes in a file with data formatted like this:
# genome_acc  status  messages    biosample_accession sample_name principal_alt   bioproject_accession    bioproject_description  umbrella_bp filename    assembly_date   assembly_name   assembly_methods    genome_coverage sequencing_technologies reference_genome
# JBHDVK000000000 Processed   accessions list SAMN33621943        paternal    PRJNA1153491    Assembly of HG00408 paternal haplotype. PRJNA1152115    HG00408.hap1_for_genbank.fa.gz  2024-08 HG00408_pat_hprc_rel2   [["Hifiasm","0.19.7"]]  63X [["PacBio, Oxford Nanopore"]]   

## note that the following columns are used:
# genome_acc, principal_alt, bioproject_accession, filename

## Returns a file with the following columns:
# sample_id   paternal_bioproject_accession   paternal_genome_acc paternal_genbank_accession  maternal_bioproject_accession   maternal_genome_acc maternal_genbank_accession
# HG00408 PRJNA1153491    JBHDVK000000000 GCA_041900255.1 PRJNA1153498    JBHDVL000000000 GCA_041900245.1

import argparse
import json
import subprocess
from typing import Dict
import pandas as pd

def fetch_genbank_accession(bioproject_accession: str) -> str:
    """
    Fetch the GenBank accession for a given BioProject accession using NCBI datasets.

    Args:
        bioproject_accession (str): The BioProject accession to look up.

    Returns:
        str: The GenBank accession or an error message.
    """
    try:
        result = subprocess.run(
            ['datasets', 'summary', 'genome', 'accession', bioproject_accession],
            capture_output=True,
            text=True,
            check=True
        )
        data = json.loads(result.stdout)
        
        assemblies = data.get('reports', [])

        if assemblies:
            return assemblies[0].get('current_accession', 'Not found')
        return 'Not found'
    except subprocess.CalledProcessError:
        return 'Error'
    except json.JSONDecodeError:
        return 'JSON Error'

def process_data(df: pd.DataFrame) -> pd.DataFrame:
    """
    Process the DataFrame to add GenBank accessions and extract sample IDs.

    Args:
        df (pd.DataFrame): Input DataFrame.

    Returns:
        pd.DataFrame: Processed DataFrame.
    """
    # Add GenBank accessions
    df['genbank_accession'] = df['bioproject_accession'].apply(fetch_genbank_accession)
    
    # Extract sample ID from filename
    df['sample_id'] = df['filename'].str.split('.').str[0]
    
    return df

def convert_to_wide_format(df: pd.DataFrame) -> pd.DataFrame:
    """
    Convert the DataFrame to wide format.

    Args:
        df (pd.DataFrame): Input DataFrame in long format.

    Returns:
        pd.DataFrame: DataFrame in wide format.
    """
    # Create a dictionary to map column names
    column_mapping = {
        'bioproject_accession': 'bioproject_accession',
        'genome_acc': 'genome_acc',
        'genbank_accession': 'genbank_accession'
    }

    # Pivot the DataFrame
    wide_df = df.pivot(index='sample_id', columns='principal_alt', values=list(column_mapping.keys()))

    # Flatten column names
    wide_df.columns = [f'{col[1]}_{col[0]}' for col in wide_df.columns]

    # Reset index to make sample_id a column
    wide_df = wide_df.reset_index()

    # Reorder columns
    column_order = ['sample_id'] + [f'{alt}_{col}' for alt in ['paternal', 'maternal'] for col in column_mapping.values()]
    wide_df = wide_df[column_order]

    return wide_df

def main():
    parser = argparse.ArgumentParser(description="Process genome data and add GenBank accessions using pandas.")
    parser.add_argument("input_file", help="Path to the input file (CSV or TSV)")
    parser.add_argument("output_file", help="Path to the output file (CSV or TSV)")
    args = parser.parse_args()

    # Determine the file format
    input_sep = '\t' if args.input_file.endswith('.tsv') else ','
    output_sep = '\t' if args.output_file.endswith('.tsv') else ','

    # Read the input file
    df = pd.read_csv(args.input_file, sep=input_sep)

    ## Only pull rows where the assembly has been processed (we can expect that if one haplotype
    ## of a diploid assembly fails, genbank will not assign "processed" to the other haplotype)
    df = df[df['status'] == 'Processed']
    
    # Process the data
    processed_df = process_data(df)

    # Convert to wide format
    wide_df = convert_to_wide_format(processed_df)

    # Write the output file
    wide_df.to_csv(args.output_file, sep=output_sep, index=False)

    print(f"Processing complete. Results written to {args.output_file}")

if __name__ == "__main__":
    main()