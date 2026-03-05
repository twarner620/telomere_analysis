#!/usr/bin/env bash
set -euo pipefail

# usage:
# draw.sh <ribose_preference_repo> <scripts_dir> <output_dir> <bg_dir> <order_tsv>
rpa_repo="$1"
scripts="$2"
output="$3"
bg="$4"
order="$5"

if [[ ! -f "$rpa_repo/resort.py" ]]; then
    echo "[ERROR] Missing required script: $rpa_repo/resort.py" >&2
    exit 1
fi

for folder in raw normalized tsv; do
    mkdir -p "$output/heatmap/$folder"
done

python3 "$scripts/format.py" "$output/telomere.tsv" -o "$output/heatmap/raw/telomere" &
python3 "$scripts/format.py" "$output/genome_telomere_unit.tsv" -o "$output/heatmap/raw/genomic" &
wait

for ty in both cstrand gstrand; do
    python3 "$scripts/calc_ef.py" "$output/heatmap/raw/telomere_mono_${ty}.raw" "$bg/telomere_mono.raw" --name "$ty" -o "$output/heatmap/normalized/telomere_mono_${ty}.norm" &
    python3 "$scripts/calc_ef.py" "$output/heatmap/raw/telomere_dinuc_d1_nr_${ty}.raw" "$bg/telomere_dinuc_d1.raw" --name "$ty" -o "$output/heatmap/normalized/telomere_dinuc_d1_nr_${ty}.norm" &
    python3 "$scripts/calc_ef.py" "$output/heatmap/raw/genomic_mono_${ty}.raw" "$bg/telomere_mono.raw" --name "$ty" -o "$output/heatmap/normalized/genomic_mono_${ty}.norm" &
    python3 "$scripts/calc_ef.py" "$output/heatmap/raw/genomic_dinuc_d1_nr_${ty}.raw" "$bg/telomere_dinuc_d1.raw" --name "$ty" -o "$output/heatmap/normalized/genomic_dinuc_d1_nr_${ty}.norm" &
done
wait

for norm_file in "$output"/heatmap/normalized/*.norm; do
    [[ -e "$norm_file" ]] || continue
    file_name="$(basename "$norm_file")"
    python3 "$rpa_repo/resort.py" "$norm_file" "$order" -c 2 -o "$output/heatmap/tsv/${file_name}.tsv" &
done
wait

for f in "$output"/heatmap/tsv/*.norm.tsv; do
    [[ -e "$f" ]] || continue
    mv "$f" "${f%.norm.tsv}.tsv"
done

for ty in cstrand gstrand; do
    strand="${ty::-6}"
    python3 "$scripts/draw_heatmap.py" "$output/heatmap/tsv/telomere_mono_${ty}.tsv" -o "$output/plots/telomere_mono_${ty}.png" --palette RdBu_r --strand "$strand" &
    python3 "$scripts/draw_heatmap.py" "$output/heatmap/tsv/telomere_dinuc_d1_nr_${ty}.tsv" -o "$output/plots/telomere_dinuc_d1_nr_${ty}.png" --palette RdBu_r --strand "$strand" &
    python3 "$scripts/draw_heatmap.py" "$output/heatmap/tsv/genomic_mono_${ty}.tsv" -o "$output/plots/genomic_mono_${ty}.png" --palette RdBu_r --strand "$strand" &
    python3 "$scripts/draw_heatmap.py" "$output/heatmap/tsv/genomic_dinuc_d1_nr_${ty}.tsv" -o "$output/plots/genomic_dinuc_d1_nr_${ty}.png" --palette RdBu_r --strand "$strand" &
done

for ty in both; do
    python3 "$scripts/draw_heatmap.py" "$output/heatmap/tsv/telomere_mono_${ty}.tsv" -o "$output/plots/telomere_mono_${ty}.png" --palette RdBu_r &
    python3 "$scripts/draw_heatmap.py" "$output/heatmap/tsv/telomere_dinuc_d1_nr_${ty}.tsv" -o "$output/plots/telomere_dinuc_d1_nr_${ty}.png" --palette RdBu_r &
    python3 "$scripts/draw_heatmap.py" "$output/heatmap/tsv/genomic_mono_${ty}.tsv" -o "$output/plots/genomic_mono_${ty}.png" --palette RdBu_r &
    python3 "$scripts/draw_heatmap.py" "$output/heatmap/tsv/genomic_dinuc_d1_nr_${ty}.tsv" -o "$output/plots/genomic_dinuc_d1_nr_${ty}.png" --palette RdBu_r &
done
wait
