#!/bin/bash
set -euo pipefail

# =============================================================================
# preprocess_for_telomere.sh
#
# Preprocesses ribose-seq FASTQs for the telomere analysis pipeline.
#
# Usage:
#   ./preprocess-telomere.sh <manifest.tsv> <output_dir> [threads]
#
# Manifest TSV (no header):
#   sample_id    barcode    fastq_path
#
# Barcodes should be the ORIGINAL molecular barcode — reverse complementation
# is handled automatically.
#
# Output:
#   <output_dir>/<sample_id>.fq  (ready for generate_data.sh)
# =============================================================================

if [[ $# -lt 2 ]]; then
    echo "Usage: $0 <manifest.tsv> <output_dir> [threads]"
    exit 1
fi

MANIFEST="$1"
OUTDIR="$2"
MAX_JOBS="${3:-4}"
PATTERN="NNNNNNXXXNN"

mkdir -p "$OUTDIR"

revcomp() {
    echo "$1" | tr 'ACGTacgt' 'TGCAtgca' | rev
}

process_sample() {
    local sample="$1" barcode_orig="$2" fastq="$3" outdir="$4"
    local barcode_rc
    barcode_rc=$(revcomp "$barcode_orig")
    local tmpfq="${outdir}/.tmp_${sample}_extracted.fq"

    echo "[$(date '+%H:%M:%S')] ${sample}: barcode ${barcode_orig} -> ${barcode_rc}"

    umi_tools extract -v 0 -I "$fastq" -p "$PATTERN" -S "$tmpfq"

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

    process_sample "$sample" "$barcode" "$fastq" "$OUTDIR" &

    job_count=$(( job_count + 1 ))
    if (( job_count >= MAX_JOBS )); then
        wait -n 2>/dev/null || wait
        job_count=$(( job_count - 1 ))
    fi
done < "$MANIFEST"

wait
echo "All samples complete. Output: ${OUTDIR}/"