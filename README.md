# Telomere Analysis Pipeline

## Recent Changes

**2026-06-24**
- Added `preprocess-telomeres-aviti.sh` for AVITI sequencing (PCR-free, no UMIs, already demultiplexed)
- AVITI preprocessing uses the same manifest format as Illumina (barcode column ignored)
- Analysis pipeline (`run_telomere_analysis.sh`) is shared between both workflows

**2026-04-25**
- `preprocess-telomeres.sh` now accepts `.fq.gz` and `.fq` inputs
- Preprocessing output is written to a configurable `SCRATCH_DIR` (default: `/storage/scratch1/8/twarner31/telomere_analysis/processed_fastqs`); upon completion, processed FASTQs are symlinked into `processed_fastqs/` in the repo root
- `preprocess-telomeres.sh` interface simplified — output directory is no longer a CLI argument (hardcoded to scratch + symlink pattern above); default parallelism raised to 50 jobs

---

This repo supports two sequencing platforms:
- **Illumina** (ribose-seq with UMIs) — `telomere/preprocessing/preprocess-telomeres.sh`
- **AVITI** (PCR-free, no UMIs, already demultiplexed) — `telomere/preprocessing/preprocess-telomeres-aviti.sh`

Both preprocessing scripts produce per-sample FASTQs that feed into the shared analysis pipeline (`telomere/run_telomere_analysis.sh`).

It also depends on `resort.py` from the co-requisite `RibosePreferenceAnalysis` repo.
The vast majority of this code is repurposed from Penghao Xu.

## Clone Repos

```bash
mkdir -p ~/analysis && cd ~/analysis

git clone git@github.com:twarner620/telomere_analysis.git
git clone git@github.com:xph9876/RibosePreferenceAnalysis.git
```

Recommended layout:

```text
~/analysis/
  telomere_analysis/
  RibosePreferenceAnalysis/
```

## Conda Environment

The Conda environment file lives at the repo root: `./environment.yml`.

```bash
cd ~/analysis/telomere_analysis
conda env create -f environment.yml
conda activate telomere_analysis
```

```text
telomere/
  config/
    order.tsv
    manifest.example.tsv
    <your-manifest>.tsv   # gitignored
  pipeline/
    analyze.sh
    generate_data.sh
    barchart/
    genome_comparison/
    heatmap/
  preprocessing/
    preprocess-telomeres.sh
    preprocess-telomeres-aviti.sh
  run_telomere_analysis.sh
```

## 1) Preprocess FASTQs

Both workflows use the same manifest format (tab-separated, no header):

```text
sample_id	barcode	fastq_path
```

- `fastq_path` may be `.fq` or `.fq.gz` — both are handled automatically
- For AVITI, the barcode column is present but ignored
- For Illumina, use the original barcode; do not reverse-complement manually — `preprocess-telomeres.sh` handles that internally

Before running, confirm `SCRATCH_DIR` at the top of the preprocessing script points to your scratch space. The default is:

```bash
SCRATCH_DIR="/storage/scratch1/8/twarner31/telomere_analysis/processed_fastqs"
```

### Illumina

```bash
bash telomere/preprocessing/preprocess-telomeres.sh \
  telomere/config/my-manifest.tsv \
  [threads]   # optional, default 50
```

### AVITI

```bash
bash telomere/preprocessing/preprocess-telomeres-aviti.sh \
  telomere/config/my-manifest.tsv
```

On completion, processed FASTQs are symlinked into `processed_fastqs/` at the repo root. Pass that directory as input to the next step.

## 2) Run Telomere Analysis

```bash
bash telomere/run_telomere_analysis.sh \
  processed_fastqs \
  /path/to/telomere_outputs \
  /path/to/filtered_beds \
  /path/to/hg38-noalts.fa \
  ../RibosePreferenceAnalysis \
  telomere/config/order.tsv
```

Arguments:
1. `processed_fastqs/` — symlinked output from preprocessing
2. output directory for analysis results
3. directory containing per-sample filtered BED files (`<sample>.bed`)
4. hg38 FASTA
5. path to `RibosePreferenceAnalysis` (must contain `resort.py`)
6. optional order TSV (defaults to `telomere/config/order.tsv`)

## Output

Main outputs are written under your selected output directory:
- `reads/`
- `plots/`
- `genome_comparison/`
- `heatmap/`
- `telomere.tsv`
- `genome_telomere_unit.tsv`

## Citation

Human ribomes reveal DNA-embedded ribonucleotides as a new type of epigenetic mark. Deepali Lalchand Kundnani, Taehwan Yang, Tejasvi Channagiri, Penghao Xu, Yeunsoo Lee, Mo Sun, Francisco Martinez-Figueroa, Supreet Randhawa, Ashlesha Gogate, Youngkyu Jeon, Stefania Marsili, Gary Newnam, Yilin Lu, Vivian Park, Sijia Tao, Justin Ling, Raymond Schinazi, Zachary Pursell, Abdulmelik Mohammed, Patricia Opresko, Bret Freudenthal, Baek Kim, Soojin Yi, Nataša Jonoska, Francesca Storici, bioRxiv 2025, https://doi.org/10.1101/2025.06.27.661996
