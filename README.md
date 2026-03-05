# Telomere Analysis Pipeline

This repo is reduced to only the code required for:
- `telomere/preprocessing/preprocess-telomeres.sh`
- `telomere/run_telomere_analysis.sh`

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
conda activate teleomere_analysis
```

```text
telomere/
  config/
    order.tsv
  pipeline/
    analyze.sh
    generate_data.sh
    barchart/
    genome_comparison/
    heatmap/
  preprocessing/
    preprocess-telomeres.sh
    manifest.example.tsv
  run_telomere_analysis.sh
```

## 1) Preprocess FASTQs

Input manifest format (tab-separated, no header):

```text
sample_id    barcode    fastq_path
```

Use the original barcode in the manifest. Do not reverse-complement barcodes manually; `preprocess-telomeres.sh` handles reverse complementation internally.

Example:

```bash
cd ~/analysis/telomere_analysis
bash telomere/preprocessing/preprocess-telomeres.sh \
  telomere/preprocessing/manifest.example.tsv \
  /path/to/processed_fastqs \
  8
```

## 2) Run Telomere Analysis

```bash
cd ~/analysis/telomere_analysis
bash telomere/run_telomere_analysis.sh \
  /path/to/processed_fastqs \
  /path/to/telomere_outputs \
  /path/to/filtered_beds \
  /path/to/hg38-noalts.fa \
  ../RibosePreferenceAnalysis \
  telomere/config/order.tsv
```

Arguments:
1. `processed_fastq_dir` from preprocessing output
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
