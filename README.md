# EDTA-analysis

Pipeline for annotation and analysis of transposable elements (TEs) in *Castanea* species genomes using [EDTA v2.3](https://github.com/oushujun/EDTA).


---

## Repository contents

| File | Description |
|---|---|
| `split_fasta.sh` | Splits a whole-genome FASTA into one file per chromosome, each in its own folder |
| `run_EDTA.sh` | Runs EDTA v2.3 chromosome by chromosome across all folders detected automatically |
| `unify_TEanno_gff.sh` | Merges per-chromosome EDTA GFF3 outputs into a single genome-wide GFF3, renumbering `ID` and `Parent` attributes to be unique and continuous |
| `Analisis_EDTA_v4.Rmd` | R Markdown pipeline for TE composition, chromosomal distribution, insertion age estimation, and gene proximity analysis |

---

## Workflow overview

```
Genome FASTA
     │
     ▼
split_fasta.sh          → one chrN/chrN.fasta per chromosome
     │
     ▼
run_EDTA.sh             → per-chromosome EDTA annotation (*.EDTA.TEanno.gff3)
     │
     ▼
unify_TEanno_gff.sh     → single genome-wide GFF3
     │
     ▼
Analisis_EDTA_v4.Rmd    → figures, statistics, and report
```

---

## Usage

### 1. Split genome FASTA by chromosome

Edit the `FASTA` variable at the top of the script to point to your genome file, then run:

```bash
bash split_fasta.sh
```

Each chromosome will be written to `chrN/chrN.fasta`.

### 2. Run EDTA per chromosome

Edit `BASE_DIR` in the script to point to the directory containing the per-chromosome folders, then run:

```bash
bash run_EDTA.sh
```

EDTA is launched sequentially for each chromosome. Logs are written to `BASE_DIR/logs/`.

### 3. Unify per-chromosome GFF3 outputs

```bash
bash unify_TEanno_gff.sh [base_dir] [output_file]
```

- `base_dir`: directory containing the per-chromosome folders (default: current directory)
- `output_file`: name of the unified GFF3 (default: `Genome.EDTA.TEanno.gff3`)

The script finds all `*.fasta.mod.EDTA.TEanno.gff3` files at depth 2, merges them in chromosome order, and renumbers `ID`/`Parent` attributes continuously so the output is equivalent to a single-run EDTA annotation. A duplicate-ID check is printed at the end.

### 4. R Markdown analysis

Open `Analisis_EDTA_v4.Rmd` in RStudio and update the file paths in the `rutas-archivos` chunk:

```r
ruta_gff3_edta    <- "path/to/Genome.EDTA.TEanno.gff3"
ruta_fasta_genoma <- "path/to/genome.fa"
ruta_gff_genes    <- "path/to/genes.gff"
```

Then knit the document (`Ctrl+Shift+K`). The report covers:

- Global TE composition and repeat masking statistics
- LTR retrotransposon families (Gypsy, Copia, Unknown): chromosomal distribution, insertion age, size distribution, and distance to genes
- DNA transposons (TIR families): chromosomal distribution, MITE vs. autonomous element comparison
- Genome-wide density analysis in 1–2 Mb sliding windows with Spearman correlations against gene density

---

## Dependencies

### Bash scripts

- `bash` ≥ 4.0 (for `mapfile`)
- `awk` (gawk recommended)
- [EDTA v2.3](https://github.com/oushujun/EDTA) and its dependencies (required for `run_EDTA.sh`)

### R Markdown analysis

R ≥ 4.0 and the following packages:

```r
install.packages(c(
  "data.table", "dplyr", "tidyr", "stringr",
  "ggplot2", "forcats", "readr", "scales", "patchwork", "DT"
))

if (!require("BiocManager")) install.packages("BiocManager")
BiocManager::install(c(
  "rtracklayer", "GenomicRanges", "Biostrings",
  "GenomeInfoDb", "karyoploteR"
))
```

---

## Notes

- EDTA is run with `--species others`, `--sensitive 1`, and `--anno 1`. Adjust `--threads` in `run_EDTA.sh` to match your system.
- The unification script expects per-chromosome folders at depth 2 from `base_dir` (e.g. `base_dir/chr1/chr1.fasta.mod.EDTA.TEanno.gff3`). Adjust `PATTERN` in the script if your file naming differs.
- The R analysis was developed and tested on *Castanea sativa* hap2 but is applicable to any species with a chromosomal assembly annotated by EDTA, by updating the file paths and the chromosome filter in the `preparar-cromosomas` chunk.
