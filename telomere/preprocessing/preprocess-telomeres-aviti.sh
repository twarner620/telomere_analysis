#!/bin/bash
set -euo pipefail

# =============================================================================
# preprocess-telomeres-aviti.sh
#
# Stages already demultiplexed, PCR-free AVITI FASTQs for the telomere analysis
# pipeline.  Unlike the Illumina workflow there is no UMI extraction or
# barcode demultiplexing — FASTQs are already one file per sample.
#
# Usage:
#   ./preprocess-telomeres-aviti.sh telomere/config/<manifest.tsv>
#
# Manifest TSV (no header) — same format as Illumina:
#   sample_id    barcode    fastq_path   (.fq or .fq.gz)
#
# The barcode column is ignored (AVITI data is already demultiplexed).
#
# Output:
#   Processed FASTQs written to SCRATCH_DIR, then symlinked into
#   <repo_root>/processed_fastqs/.
# =============================================================================

# --- Configurable ---
SCRATCH_DIR="/storage/scratch1/8/twarner31/telomere_analysis/processed_fastqs"
# --------------------

if [[ $# -lt 1 ]]; then
    echo "Usage: $0 <manifest.tsv>"
    exit 1
fi

MANIFEST="$1"

REPO_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
PROCESSED_DIR="${REPO_DIR}/processed_fastqs"

mkdir -p "$SCRATCH_DIR"
mkdir -p "$PROCESSED_DIR"

while IFS=$'\t' read -r sample _barcode fastq || [[ -n "$sample" ]]; do
    [[ -z "$sample" || "$sample" == \#* ]] && continue
    if [[ ! -f "$fastq" ]]; then
        echo "[WARNING] FASTQ not found for ${sample}: ${fastq} — skipping"
        continue
    fi

    dest="${SCRATCH_DIR}/${sample}.fq"

    if [[ "$fastq" == *.gz ]]; then
        echo "[$(date '+%H:%M:%S')] ${sample}: decompressing ${fastq}"
        zcat "$fastq" > "$dest"
    else
        echo "[$(date '+%H:%M:%S')] ${sample}: copying ${fastq}"
        cp "$fastq" "$dest"
    fi

    echo "[$(date '+%H:%M:%S')] ${sample}: done ($(( $(wc -l < "$dest") / 4 )) reads)"
done < "$MANIFEST"

echo "All samples staged. Symlinking into ${PROCESSED_DIR}/"

for fq in "${SCRATCH_DIR}"/*.fq; do
    [[ -f "$fq" ]] || continue
    ln -sf "$fq" "${PROCESSED_DIR}/$(basename "$fq")"
done

echo "Done. Processed FASTQs linked in ${PROCESSED_DIR}/"
