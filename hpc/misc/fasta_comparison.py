
import argparse
import gzip
from Bio import SeqIO
import csv

def parse_fasta(fasta_fp):
    sequences = {}
    open_func = gzip.open if fasta_fp.endswith('.gz') else open
    
    with open_func(fasta_fp, 'rt') as handle:
        for record in SeqIO.parse(handle, 'fasta'):
            # Extract the sequence name after the last '#'
            sequence_name = record.id.split('#')[-1].split()[0]
            sequences[sequence_name] = len(record.seq)
    
    return sequences

def write_csv(filename, header, rows):
    with open(filename, 'w', newline='') as csvfile:
        writer = csv.writer(csvfile)
        writer.writerow(header)
        writer.writerows(rows)

def compare_assemblies(fasta1_name, fasta2_name, fasta1_sequences, fasta2_sequences):
    
    fasta1_not_fasta2 = []
    fasta2_not_fasta1 = []
    modified_sequences = []
    identical_sequences = []
    
    fasta1_set = set(fasta1_sequences.keys())
    fasta2_set = set(fasta2_sequences.keys())
    
    # Sequences in fasta1 but not in fasta2
    for seq_name in fasta1_set - fasta2_set:
        fasta1_not_fasta2.append([seq_name, fasta1_sequences[seq_name]])
    
    # Sequences in fasta2 but not in fasta1
    for seq_name in fasta2_set - fasta1_set:
        fasta2_not_fasta1.append([seq_name, fasta2_sequences[seq_name]])
    
    # Sequences in both but possibly modified
    for seq_name in fasta1_set & fasta2_set:
        size1 = fasta1_sequences[seq_name]
        size2 = fasta2_sequences[seq_name]
        
        if size1 == size2:
            identical_sequences.append([seq_name, size1])
        else:
            size_diff_bp = abs(size1 - size2)
            size_diff_perc = (size_diff_bp / min(size1, size2)) * 100
            modified_sequences.append([seq_name, size1, size2, size_diff_bp, size_diff_perc])
    
    return fasta1_not_fasta2, fasta2_not_fasta1, modified_sequences, identical_sequences

def write_summary(filename, summary_data):
    with open(filename, 'w') as summary_file:
        for key, value in summary_data.items():
            summary_file.write(f"{key}: {value}\n")

def main():
    parser = argparse.ArgumentParser(description="Compare two assemblies in FASTA format.")
    parser.add_argument('--fasta_fp', help="Path to the first fasta file (can be .gz)")
    parser.add_argument('--fasta2_fp', help="Path to the second fasta file (can be .gz)")
    parser.add_argument('--fasta1_name', help="Name of the first assembly")
    parser.add_argument('--fasta2_name', help="Name of the second assembly")
    
    args = parser.parse_args()
    
    fasta_fp     = args.fasta_fp
    fasta2_fp    = args.fasta2_fp
    fasta1_name  = args.fasta1_name
    fasta2_name  = args.fasta2_name

    # Parse both FASTA files
    fasta1_sequences = parse_fasta(fasta_fp)
    fasta2_sequences = parse_fasta(fasta2_fp)
    
    # Compare the assemblies
    fasta1_not_fasta2, fasta2_not_fasta1, modified_sequences, identical_sequences = compare_assemblies(
        fasta1_name, fasta2_name, fasta1_sequences, fasta2_sequences
    )
    
    # Write intersection/union files:
    ## A not B, B not A, A and B, A and B w/ size differences
    write_csv(f"{fasta1_name}_not_{fasta2_name}.csv", [fasta1_name, "size"], fasta1_not_fasta2)
    write_csv(f"{fasta2_name}_not_{fasta1_name}.csv", [fasta2_name, "size"], fasta2_not_fasta1)
    write_csv(f"{fasta1_name}_and_{fasta2_name}_modified.csv", 
              [fasta1_name, "size1", fasta2_name, "size2", "size_difference_bp", "size_difference_perc"], 
              modified_sequences)
    write_csv(f"{fasta1_name}_and_{fasta2_name}.csv", [fasta1_name, "size"], identical_sequences)
    

    # Write a summary file
    summary_data = {
        f"number of sequences in {fasta1_name}": len(fasta1_sequences),
        f"total bp in {fasta1_name}": sum(fasta1_sequences.values()),
        f"number of sequences in {fasta2_name}": len(fasta2_sequences),
        f"total bp in {fasta2_name}": sum(fasta2_sequences.values()),
        f"number of sequences in {fasta1_name} not in {fasta2_name}": len(fasta1_not_fasta2),
        f"total bp in {fasta1_name} not in {fasta2_name}": sum(seq[1] for seq in fasta1_not_fasta2),
        f"number of sequences in {fasta2_name} not in {fasta1_name}": len(fasta2_not_fasta1),
        f"total bp in {fasta2_name} not in {fasta1_name}": sum(seq[1] for seq in fasta2_not_fasta1)
    }
    
    write_summary(f"{fasta1_name}_vs_{fasta2_name}_summary.txt", summary_data)

if __name__ == "__main__":
    main()
