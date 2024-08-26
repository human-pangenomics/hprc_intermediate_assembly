import argparse
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from matplotlib.colors import Normalize

def parse_paf_file(paf_file):
    filtered_data = []
    with open(paf_file, 'r') as file:
        for line in file:
            columns = line.strip().split('\t')
            query_length = int(columns[1])
            if query_length < 35000:
                residue_matches = int(columns[9])
                alignment_block_length = int(columns[10])
                mismatch_rate = None
                for column in columns[12:]:
                    if column.startswith("de:f:"):
                        mismatch_rate = float(column.split(':')[-1])
                        break
                if mismatch_rate is not None:
                    filtered_data.append([query_length, residue_matches, alignment_block_length, mismatch_rate])
    return filtered_data

def save_to_csv(data, output_file):
    df = pd.DataFrame(data, columns=['query_length', 'residue_matches', 'alignment_block_length', 'mismatch_rate'])
    df.to_csv(output_file, index=False)
    return df

def plot_data(df, output_plot, output_plot_jittered):
    norm = Normalize(vmin=df['mismatch_rate'].min(), vmax=df['mismatch_rate'].max())

    plt.figure(figsize=(10, 6))

    scatter = plt.scatter(df['query_length'], df['alignment_block_length'],
                          c=df['mismatch_rate'], cmap='viridis', s=10, alpha=0.6, norm=norm)

    # Create a custom legend to display the colorbar label
    colorbar = plt.colorbar(scatter, norm=norm)
    colorbar.set_label('Mismatch Rate')

    plt.axvline(x=16569, color='black', linestyle='--')

    plt.xlabel('Read Length (bp)')
    plt.ylabel('Alignment Block Length (bp)')
    plt.title('Alignment vs Read Size')
    plt.savefig(output_plot, dpi=600)

    # Jittered scatter plot for the region around 16,500 bp
    plt.figure(figsize=(10, 6))
    zoomed_df = df[(df['alignment_block_length'] >= 12000) & (df['alignment_block_length'] <= 17500)].copy()
    jitter = 50
    zoomed_df['query_length'] += np.random.uniform(-jitter, jitter, size=zoomed_df.shape[0])
    zoomed_df['alignment_block_length'] += np.random.uniform(-jitter, jitter, size=zoomed_df.shape[0])
    scatter_jittered = plt.scatter(zoomed_df['query_length'], zoomed_df['alignment_block_length'],
                                   c=zoomed_df['mismatch_rate'], cmap='viridis', s=10, alpha=0.6, edgecolors='face', norm=norm)

    # Create a custom legend to display the colorbar label
    colorbar_jittered = plt.colorbar(scatter_jittered, norm=norm)
    colorbar_jittered.set_label('Mismatch Rate')

    plt.axvline(x=16569, color='black', linestyle='--')

    plt.xlabel('Read Length (bp)')
    plt.ylabel('Alignment Block Length (bp)')
    plt.title('Alignment vs Read Size (With 50bp Jitter)')
    plt.savefig(output_plot_jittered, dpi=600)

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Process a PAF file and generate plots.')
    parser.add_argument('--input_paf', type=str, help='Input PAF file')
    parser.add_argument('--output_prefix', type=str, help='Output file prefix')

    args = parser.parse_args()

    input_paf = args.input_paf
    output_prefix = args.output_prefix

    output_csv = f'{output_prefix}_over_rCRS_length.csv'
    output_plot = f'{output_prefix}_over_rCRS_length.png'
    output_plot_jittered = f'{output_prefix}_over_rCRS_length_jittered.png'

    filtered_data = parse_paf_file(input_paf)
    df = save_to_csv(filtered_data, output_csv)
    plot_data(df, output_plot, output_plot_jittered)