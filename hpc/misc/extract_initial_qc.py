import pandas as pd
import argparse 

import warnings
warnings.simplefilter(action='ignore', category=FutureWarning)

## Call with
# python3 extract_initial_qc.py \
#      --qc_data_table input_data.csv \
#      --extract_column_name filtQCStats
#      --output extracted_qc_results.csv


###############################################################################
##                              Function Def                                 ##
###############################################################################

def get_metric(file_nm, start_of_line, column):
    '''open QC file (file_nm) and search through until start_of_line is found
    then return all matching values from the correct column number'''

    f = open(file_nm, 'r')
    
    values = [] 
    
    for line in f:
        
        line = line.strip()
        if line.startswith(start_of_line):
            values.append(line.split()[column])
            
    return values


def extract_qc_metrics(qc_df):
    '''take in data fram with location of QC file to read, return data frame of values'''
    
    full_sgl_genes = 35405
    
    ## Create empty columns
    qc_df["mat_num_contigs"] = ""
    qc_df["mat_total_len"]   = ""
    qc_df["mat_AUN"]         = ""
    qc_df["mat_full_sgl"]    = ""
    qc_df["mat_full_dup"]    = ""
    qc_df["mat_perc_sgl"]    = ""
    qc_df["mat_switch"]      = ""
    qc_df["mat_hamming"]     = ""
    qc_df["mat_qv"]          = ""

    qc_df["pat_num_contigs"] = ""
    qc_df["pat_total_len"]   = ""
    qc_df["pat_AUN"]         = ""
    qc_df["pat_full_sgl"]    = ""
    qc_df["pat_full_dup"]    = ""
    qc_df["pat_perc_sgl"]    = ""    
    qc_df["pat_switch"]      = ""
    qc_df["pat_hamming"]     = ""
    qc_df["pat_qv"]          = ""

    ## Loop through dataframe rows/samples and download then read in each QC file
    for index, row in qc_df.iterrows():

        qc_fp = row['qc_fp']
        qc_fn = str(qc_fp)         ## if running on cloud, localize then get filename

        ## only update if there is a QC file path to extract
        if (qc_fn) != "nan":

            length_ls     = get_metric(qc_fn, 'a. Total length', 5)
            contig_cnt_ls = get_metric(qc_fn, 'b. Number of Contigs:', 4)
            aun_ls        = get_metric(qc_fn, 'd. auN:', 4)
            full_sgl_ls   = get_metric(qc_fn, 'full_sgl', 2)
            full_dup_ls   = get_metric(qc_fn, 'full_dup', 2)
            switch_ls     = get_metric(qc_fn, 'a. Switch error:', 3)
            hamming_ls    = get_metric(qc_fn, 'b. Hamming error:', 3)
            qv_ls         = get_metric(qc_fn, 'a. QV:', 2)

            qc_df["pat_total_len"][index]   = length_ls[0]
            qc_df["pat_num_contigs"][index] = contig_cnt_ls[0]
            qc_df["pat_AUN"][index]         = aun_ls[0]
            qc_df["pat_full_sgl"][index]    = full_sgl_ls[0]
            qc_df["pat_full_dup"][index]    = full_dup_ls[0]
            qc_df["pat_perc_sgl"][index]    = (int(full_sgl_ls[0]) + int(full_dup_ls[0])) / full_sgl_genes
            qc_df["pat_switch"][index]      = float(switch_ls[0]) / 100
            qc_df["pat_hamming"][index]     = float(hamming_ls[0]) / 100
            qc_df["pat_qv"][index]          = qv_ls[0]

            qc_df["mat_total_len"][index]   = length_ls[1]
            qc_df["mat_num_contigs"][index] = contig_cnt_ls[1]
            qc_df["mat_AUN"][index]         = aun_ls[1]
            qc_df["mat_full_sgl"][index]    = full_sgl_ls[1]
            qc_df["mat_full_dup"][index]    = full_dup_ls[1]
            qc_df["mat_perc_sgl"][index]    = (int(full_sgl_ls[1]) + int(full_dup_ls[1])) / full_sgl_genes
            qc_df["mat_switch"][index]      = float(switch_ls[1]) / 100
            qc_df["mat_hamming"][index]     = float(hamming_ls[1]) / 100
            qc_df["mat_qv"][index]          = qv_ls[1]   
        
    return qc_df.drop('qc_fp', axis=1) 


def extract_qc(input_df, column_name):
    ## Pull just the filepaths to the QC files (and the index)
    to_extract_df = input_df[[column_name]].copy()

    ## rename for reusability (extract_qc_metrics expects "qc_fp")
    to_extract_df.rename(columns = {column_name:'qc_fp'}, inplace = True)

    ## do the extraction
    extracted_df = extract_qc_metrics(to_extract_df)

    return extracted_df


def get_t2t_counts(in_df, pat_t2t_fp, mat_t2t_fp):
    
    chr_names = ["chr1", "chr2", "chr3", "chr4", "chr5", "chr6", "chr7", "chr8",
            "chr9", "chr10", "chr11", "chr12", "chr13", "chr14", "chr15", "chr16",
            "chr17", "chr18", "chr19", "chr20", "chr21", "chr22", "chrX", "chrY"]
    
    t2t_cntg_df = pd.DataFrame(columns=chr_names)
    
    for index, row in in_df.iterrows():

        sample_nm = row.name

        pat_fp = row[pat_t2t_fp]

        if str(pat_fp) != "nan":
            pat_df = pd.read_csv(pat_fp, sep="\t")

            haplotype = sample_nm + "-pat"

            for i in range(len(pat_df)):
                chr_name = pat_df.loc[i, 'chromosome']
                Ns = pat_df.loc[i, 'Ns']
                if Ns == 0:
                    t2t_cntg_df.at[haplotype, chr_name] = "C"
                else:
                    t2t_cntg_df.at[haplotype, chr_name] = "S"

            mat_fp = row[mat_t2t_fp]
            mat_df = pd.read_csv(mat_fp, sep="\t")

            haplotype = sample_nm + "-mat"

            for i in range(len(mat_df)):
                chr_name = mat_df.loc[i, 'chromosome']
                Ns = mat_df.loc[i, 'Ns']
                if Ns == 0:
                    t2t_cntg_df.at[haplotype, chr_name] = "C"
                else:
                    t2t_cntg_df.at[haplotype, chr_name] = "S"
                    
    return t2t_cntg_df

###############################################################################
##                                 MAIN                                      ##
###############################################################################

def main():

    parser = argparse.ArgumentParser(description='Read a CSV file with qc data, extract it, write QC table.')

    parser.add_argument('--qc_data_table', '-d', type=str, action='store',
                        help='Path to the input CSV file. Should have one sample per row.')
    parser.add_argument('--extract_column_name', '-c', type=str, action='store',
                        help='Column name that holds the paths to the QC to extract.')
    parser.add_argument('--output', '-o', type=str, action='store',
                        help='Output file name to write results to as a CSV.')

    args = parser.parse_args()

    
    ## read in input data table (which has column with paths to QC results)
    in_df = pd.read_csv(args.qc_data_table, index_col="sample_id")

    ## extract the QC files and write back to data table
    extracted_verkko_trio_df = extract_qc(in_df, args.extract_column_name)
    extracted_verkko_trio_df.to_csv(args.output)

    ## extract T2T statistics
    t2t_count_df = get_t2t_counts(in_df, "hap1_T2Tscaffolds", "hap2_T2Tscaffolds") 
    t2t_count_df.to_csv("blah.csv")

if __name__ == '__main__':
    main()

###############################################################################
##                                 DONE                                      ##
###############################################################################