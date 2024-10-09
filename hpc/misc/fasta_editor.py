#!/usr/bin/env python3

import argparse
import gzip
from typing import List, Tuple, Union, TextIO
from Bio import SeqIO
from Bio.Seq import Seq
from Bio.SeqRecord import SeqRecord

def parse_arguments() -> argparse.Namespace:
    """Parse command-line arguments."""
    parser = argparse.ArgumentParser(description="Edit FASTA sequences.")
    parser.add_argument("input_fasta", help="Input FASTA file (may be gzipped)")
    parser.add_argument("edit", choices=["mask", "break", "trim", "remove"], help="Edit to perform")
    parser.add_argument("coord", help="Coordinates for edit (e.g., h2tg000012l:98240899-98268417) or sequence name for remove")
    parser.add_argument("output_fasta", help="Output FASTA file name (add .gz extension for gzipped output)")
    return parser.parse_args()

def parse_coord(coord: str) -> Tuple[str, int, int]:
    """Parse the coordinate string into sequence name, start, and end positions."""
    parts = coord.split(':')
    if len(parts) != 2 or '-' not in parts[1]:
        raise ValueError(f"Invalid coordinate format: {coord}")
    seq_name = parts[0]
    start, end = map(int, parts[1].split('-'))
    return seq_name, start, end

def mask_sequence(sequence: Seq, start: int, end: int) -> Seq:
    """Replace the specified region of the sequence with N's."""
    return sequence[:start-1] + Seq('N' * (end - start + 1)) + sequence[end:]

def break_sequence(record: SeqRecord, start: int, end: int) -> List[SeqRecord]:
    """Break the sequence into two parts, removing the specified region."""
    seq1 = record.seq[:start-1]
    seq2 = record.seq[end:]
    return [
        SeqRecord(seq1, id=f"{record.id}-1", description=record.description),
        SeqRecord(seq2, id=f"{record.id}-2", description=record.description)
    ]

def trim_sequence(record: SeqRecord, start: int, end: int) -> SeqRecord:
    """Trim the sequence at the specified coordinates."""
    if start == 1:
        new_seq = record.seq[end:]
        suffix = "-5trim"
    elif end == len(record.seq):
        new_seq = record.seq[:start-1]
        suffix = "-3trim"
    else:
        raise ValueError(f"Trim coordinates must coincide with sequence ends. Sequence range: 1-{len(record.seq)}")
    return SeqRecord(new_seq, id=f"{record.id}{suffix}", description=record.description)

def open_file(filename: str, mode: str) -> Union[TextIO, gzip.GzipFile]:
    """Open a file, automatically handling gzip compression if the filename ends with .gz"""
    if filename.endswith('.gz'):
        return gzip.open(filename, mode)
    return open(filename, mode)

def process_fasta(args: argparse.Namespace):
    """Process the FASTA file and perform the specified edit."""
    if args.edit == "remove":
        target_name = args.coord
        start, end = None, None
    else:
        target_name, start, end = parse_coord(args.coord)
    
    with open_file(args.input_fasta, 'rt') as infile, open_file(args.output_fasta, 'wt') as outfile:
        for record in SeqIO.parse(infile, "fasta"):
            if record.id == target_name:
                if args.edit == "mask":
                    record.seq = mask_sequence(record.seq, start, end)
                    check_n_proximity(record.seq)
                    SeqIO.write(record, outfile, "fasta")
                elif args.edit == "break":
                    check_n_stretch(record.seq, start, end)
                    new_records = break_sequence(record, start, end)
                    SeqIO.write(new_records, outfile, "fasta")
                elif args.edit == "trim":
                    new_record = trim_sequence(record, start, end)
                    check_n_proximity(new_record.seq)
                    SeqIO.write(new_record, outfile, "fasta")
                elif args.edit == "remove":
                    continue  # Skip this record, effectively removing it
            else:
                SeqIO.write(record, outfile, "fasta")

def check_n_proximity(sequence: Seq, threshold: int = 50):
    """Check if there are N's within the specified threshold of sequence ends."""
    if 'N' in sequence[:threshold] or 'N' in sequence[-threshold:]:
        raise ValueError(f"N's found within {threshold}bp of sequence ends after editing.")

def check_n_stretch(sequence: Seq, start: int, end: int):
    """Check if the break occurs in the middle of a stretch of N's."""
    n_start = str(sequence).rfind('N' * (start - 1), 0, start)
    n_end = str(sequence).find('N' * (len(sequence) - end), end)
    if n_start != -1 or n_end != -1:
        raise ValueError(f"Break occurs in N stretch. N region: {max(1, n_start+1)}-{min(len(sequence), n_end+1)}")

def main():
    args = parse_arguments()
    process_fasta(args)

if __name__ == "__main__":
    main()