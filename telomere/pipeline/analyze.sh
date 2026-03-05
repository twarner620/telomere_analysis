#!/usr/bin/env bash
set -euo pipefail

# usage:
# analyze.sh <pipeline_dir> <processed_fastq_dir> <order_tsv> <output_dir> <filtered_bed_dir> <hg38_fasta> <rpa_repo>
pipeline_dir="$1"
fqs="$2"
order="$3"
output="$4"
beds="$5"
genome="$6"
rpa_repo="$7"

for folder in reads plots genome_comparison heatmap; do
    mkdir -p "$output/$folder"
done

bash "$pipeline_dir/generate_data.sh" "$fqs" "$order" "$output/reads"
echo "Telomere reads generated."

shopt -s nullglob
raw_fastqs=("$output"/reads/raw_reads/*.fq)
shopt -u nullglob
if [[ ${#raw_fastqs[@]} -eq 0 ]]; then
    echo "[ERROR] No raw read FASTQs found in $output/reads/raw_reads" >&2
    exit 1
fi

python3 "$pipeline_dir/barchart/loc_freq.py" "${raw_fastqs[@]}" "$order" -o "$output/telomere.tsv" --umi_length 0
python3 "$pipeline_dir/barchart/draw_freq.py" "$output/telomere.tsv" -o "$output/plots/telomere_barchart.png"
echo "Telomere bar chart generated."

bash "$pipeline_dir/genome_comparison/generate_comparison.sh" "$beds" "$pipeline_dir/genome_comparison" "$genome" "$order" "$output"
python3 "$pipeline_dir/barchart/draw_freq.py" "$output/genome_telomere_unit.tsv" -o "$output/plots/genome_barchart.png"
echo "Genome comparison bar chart generated."

bash "$pipeline_dir/heatmap/draw.sh" "$rpa_repo" "$pipeline_dir/heatmap" "$output" "$pipeline_dir/heatmap/bg" "$order"
echo "Heatmaps generated."
