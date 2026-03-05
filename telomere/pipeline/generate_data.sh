#!/usr/bin/env bash
set -euo pipefail

# usage:
# ./generate_data.sh <processed_fastq_dir> <order_tsv> <output_dir>
fqs="$1"
order="$2"
output="$3"

for folder in raw_reads trimmed trimming_reports logs; do
    mkdir -p "$output/$folder"
done

process() {
    local sample="$1"
    local sample_fq="$fqs/$sample.fq"
    if [[ ! -f "$sample_fq" ]]; then
        echo "[WARNING] Missing processed FASTQ for $sample: $sample_fq" >&2
        return 0
    fi

    grep 'TTAGGGTTAGGGTTAGGGTTAGGG' "$sample_fq" -A 2 -B 1 --no-group-separator > "$output/raw_reads/${sample}_g.fq" &
    grep 'CCCTAACCCTAACCCTAACCCTAA' "$sample_fq" -A 2 -B 1 --no-group-separator > "$output/raw_reads/${sample}_c.fq" &
    wait
}

cut -f 2 "$order" | while IFS= read -r sample; do
    process "$sample" &
done
wait
