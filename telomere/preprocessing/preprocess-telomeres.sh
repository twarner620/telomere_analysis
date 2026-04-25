#!/bin/bash
set -euo pipefail

# =============================================================================
# preprocess_for_telomere.sh
#
# Preprocesses ribose-seq FASTQs for the telomere analysis pipeline.
#
# Usage:
#   ./preprocess-telomeres.sh telomere/config/<manifest.tsv> [threads]
#
# Manifest TSV (no header):
#   sample_id    barcode    fastq_path   (.fq or .fq.gz)
#
# Barcodes should be the ORIGINAL molecular barcode — reverse complementation
# is handled automatically.
#
# Output:
#   Processed FASTQs written to SCRATCH_DIR during processing, then
#   symlinked into <repo_root>/processed_fastqs/ upon completion.
# =============================================================================

# --- Configurable ---
SCRATCH_DIR="/storage/scratch1/8/twarner31/telomere_analysis/processed_fastqs"
# --------------------

if [[ $# -lt 1 ]]; then
    echo "Usage: $0 <manifest.tsv> [threads]"
    exit 1
fi

MANIFEST="$1"
MAX_JOBS="${2:-50}"
PATTERN="NNNNNNXXXNN"

REPO_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
PROCESSED_DIR="${REPO_DIR}/processed_fastqs"

mkdir -p "$SCRATCH_DIR"
mkdir -p "$PROCESSED_DIR"

revcomp() {
    echo "$1" | tr 'ACGTacgt' 'TGCAtgca' | rev
}

process_sample() {
    local sample="$1" barcode_orig="$2" fastq="$3" outdir="$4"
    local barcode_rc
    barcode_rc=$(revcomp "$barcode_orig")
    local tmpfq="${outdir}/.tmp_${sample}_extracted.fq"

    echo "[$(date '+%H:%M:%S')] ${sample}: barcode ${barcode_orig} -> ${barcode_rc}"

    if [[ "$fastq" == *.gz ]]; then
        umi_tools extract -v 0 -I <(zcat "$fastq") -p "$PATTERN" -S "$tmpfq"
    else
        umi_tools extract -v 0 -I "$fastq" -p "$PATTERN" -S "$tmpfq"
    fi

    grep -B 1 -A 2 "^${barcode_rc}" "$tmpfq" \
        | sed '/^--$/d' \
        | seqtk trimfq -b "${#barcode_rc}" - \
        > "${outdir}/${sample}.fq"

    rm -f "$tmpfq"
    echo "[$(date '+%H:%M:%S')] ${sample}: done ($(( $(wc -l < "${outdir}/${sample}.fq") / 4 )) reads)"
}

export -f process_sample revcomp
export PATTERN

job_count=0

# the || [[ -n "$sample" ]] here is necessary for preventing the last sample from being ignored w/o a \n
while IFS=$'\t' read -r sample barcode fastq || [[ -n "$sample" ]]; do
    [[ -z "$sample" || "$sample" == \#* ]] && continue
    if [[ ! -f "$fastq" ]]; then
        echo "[WARNING] FASTQ not found for ${sample}: ${fastq} — skipping"
        continue
    fi

    process_sample "$sample" "$barcode" "$fastq" "$SCRATCH_DIR" &

    job_count=$(( job_count + 1 ))
    if (( job_count >= MAX_JOBS )); then
        wait -n 2>/dev/null || wait
        job_count=$(( job_count - 1 ))
    fi
done < "$MANIFEST"

wait
echo "All samples complete. Symlinking into ${PROCESSED_DIR}/"

for fq in "${SCRATCH_DIR}"/*.fq; do
    [[ -f "$fq" ]] || continue
    ln -sf "$fq" "${PROCESSED_DIR}/$(basename "$fq")"
done

echo "Done. Processed FASTQs linked in ${PROCESSED_DIR}/"
