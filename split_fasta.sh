#!/bin/bash

FASTA="Cdentata_673_v1.0.fa"   # <-- cambia esto por la ruta a tu archivo

awk '
/^>/ {
    # Extraer el ID del cromosoma (todo lo que hay después de ">" hasta el primer espacio)
    split($0, a, " ")
    chr = substr(a[1], 2)

    # Crear la carpeta con el ID del cromosoma
    system("mkdir -p " chr)

    # Definir el archivo de salida
    outfile = chr "/" chr ".fasta"
}
{
    print > outfile
}
' "$FASTA"

echo "Hecho. Cromosomas separados en sus respectivas carpetas."
