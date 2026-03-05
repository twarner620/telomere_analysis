#!/usr/bin/env bash
set -euo pipefail

beds="$1"
scripts="$2"
genome="$3"
order="$4"
output="$5"

for folder in bed_extend fa_extend bed_with_seq; do
    mkdir -p "$output/genome_comparison/$folder"
done

process() {
    local file="$1"
    local name="${file%.bed}"

    python3 "$scripts/extend_bed.py" "$beds/$file" -l 5 \
        | grep -v chrM \
        | grep -v chrX \
        | grep -v chrY \
        > "$output/genome_comparison/bed_extend/$file"

    bedtools getfasta \
        -fi "$genome" \
        -bed "$output/genome_comparison/bed_extend/$file" \
        -fo "$output/genome_comparison/fa_extend/${name}.fa" \
        -s -tab

    paste "$beds/$file" "$output/genome_comparison/fa_extend/${name}.fa" \
        | cut -f 1,2,3,4,6,8 \
        | awk 'BEGIN{OFS="\t";FS="\t"}{print $1,$2,$3,$4,$6,$5}' \
        > "$output/genome_comparison/bed_with_seq/$file"
}

mapfile -t samples < <(cut -f 2 "$order")

for sample in "${samples[@]}"; do
    process "${sample}.bed" &
done
wait

shopt -s nullglob
bed_with_seq_files=("$output"/genome_comparison/bed_with_seq/*.bed)
shopt -u nullglob

if [[ ${#bed_with_seq_files[@]} -eq 0 ]]; then
    echo "[ERROR] No BED files generated in $output/genome_comparison/bed_with_seq" >&2
    exit 1
fi

python3 "$scripts/rNMP_in_telomere_units.py" "${bed_with_seq_files[@]}" "$order" -o "$output/genome_telomere_unit.tsv"
echo "Done!"
