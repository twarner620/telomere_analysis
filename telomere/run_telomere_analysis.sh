#!/usr/bin/env bash
set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  ./telomere/run_telomere_analysis.sh <processed_fastq_dir> <output_dir> <filtered_bed_dir> <hg38_fasta> <ribose_preference_repo> [order_tsv]

Example:
  ./telomere/run_telomere_analysis.sh \
    /data/processed_fastqs \
    /data/telomere_outputs \
    /data/filtered_beds \
    /refs/hg38-noalts.fa \
    ../RibosePreferenceAnalysis
EOF
}

if [[ $# -lt 5 || $# -gt 6 ]]; then
    usage
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PIPELINE_DIR="$SCRIPT_DIR/pipeline"

PROCESSED_FASTQ_DIR="$1"
OUTPUT_DIR="$2"
FILTERED_BED_DIR="$3"
HG38_FASTA="$4"
RPA_REPO="$5"
ORDER_TSV="${6:-$SCRIPT_DIR/config/order.tsv}"

for path in "$PROCESSED_FASTQ_DIR" "$FILTERED_BED_DIR" "$RPA_REPO"; do
    if [[ ! -e "$path" ]]; then
        echo "[ERROR] Missing path: $path" >&2
        exit 1
    fi
done
if [[ ! -f "$HG38_FASTA" ]]; then
    echo "[ERROR] Missing FASTA: $HG38_FASTA" >&2
    exit 1
fi
if [[ ! -f "$ORDER_TSV" ]]; then
    echo "[ERROR] Missing order TSV: $ORDER_TSV" >&2
    exit 1
fi

bash "$PIPELINE_DIR/analyze.sh" \
    "$PIPELINE_DIR" \
    "$PROCESSED_FASTQ_DIR" \
    "$ORDER_TSV" \
    "$OUTPUT_DIR" \
    "$FILTERED_BED_DIR" \
    "$HG38_FASTA" \
    "$RPA_REPO"
