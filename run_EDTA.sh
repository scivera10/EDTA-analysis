#!/bin/bash

# Script para anotación automática de TEs por cromosoma con EDTA
# 
# Detección automática de carpetas y ficheros fasta
# Uso: bash run_EDTA.sh

BASE_DIR="Ruta/al/directorio/de/trabajo"         #"$HOME/Escritorio/Sergio_CA/EDTA_2/EDTA_Castanea_dentata"
LOG_DIR="$BASE_DIR/logs"
mkdir -p "$LOG_DIR"

echo "=========================================="
echo "Escaneando carpetas en: $BASE_DIR"
echo "=========================================="

# Detecta todos los .fasta dentro de subcarpetas directas de BASE_DIR
mapfile -t FASTAS < <(find "$BASE_DIR" -mindepth 2 -maxdepth 2 -name "*.fasta" | sort)

if [ ${#FASTAS[@]} -eq 0 ]; then
    echo "ERROR: No se encontró ningún .fasta en $BASE_DIR"
    exit 1
fi

echo "Encontrados ${#FASTAS[@]} ficheros fasta:"
for F in "${FASTAS[@]}"; do
    echo "  - $F"
done
echo ""

for FASTA in "${FASTAS[@]}"; do
    CHR_DIR=$(dirname "$FASTA")
    CHR=$(basename "$CHR_DIR")
    LOG="$LOG_DIR/EDTA_report_${CHR}.txt"

    echo "=========================================="
    echo "Iniciando EDTA para $CHR"
    echo "Inicio: $(date)"
    echo "=========================================="

    cd "$CHR_DIR" || { echo "Error al entrar en $CHR_DIR"; continue; }

    EDTA.pl \
        --genome "$FASTA" \
        --species others \
        --overwrite 0 \
        --step all \
        --threads 4 \
        --force 1 \
        --sensitive 1 \
        --anno 1 \
        2>&1 | tee "$LOG"

    EXIT_CODE=${PIPESTATUS[0]}

    if [ $EXIT_CODE -eq 0 ]; then
        echo "[$CHR] Completado con éxito — $(date)" | tee -a "$LOG_DIR/resumen_EDTA.txt"
    else
        echo "[$CHR] ERROR durante la ejecución (exit code: $EXIT_CODE) — $(date)" | tee -a "$LOG_DIR/resumen_EDTA.txt"
    fi

    echo ""
done

echo "=========================================="
echo "Todos los cromosomas procesados"
echo "Fin: $(date)"
echo "=========================================="
