#!/bin/bash
set -euo pipefail

# =========================================================
# Unifica los GFF3 de anotacion de TEs (*.fasta.mod.EDTA.TEanno.gff3)
# de todos los cromosomas en un unico GFF3 del genoma completo, con
# la MISMA ESTRUCTURA que produce EDTA:
#
# Uso:
#   ./unify_TEanno_gff.sh [directorio_base] [archivo_salida]
#
# Por defecto:
#   directorio_base = directorio actual
#                      (debe contener las carpetas chrN_hap2/)
#   archivo_salida  = Cast.1_0.hap2.EDTA.TEanno.gff3
#
# Ejecutar desde el directorio que contiene chr1_hap2/, chr2_hap2/, etc.
#   (p.ej. ~/Escritorio/Sergio_CA/EDTA_2/hap2_chr)
# =========================================================

BASE_DIR="${1:-.}"
OUTPUT="${2:-Genome.EDTA.TEanno.gff3}" # <-- Cambiar nombre del archivo de salida
PATTERN="*.fasta.mod.EDTA.TEanno.gff3" # <-- Ajustar el patrón

TMP_AWK=$(mktemp)
TMP_BODY=$(mktemp)
trap 'rm -f "$TMP_AWK" "$TMP_BODY"' EXIT

# Buscar el GFF3 "final" de cada cromosoma: solo el que esta en la
# raiz de cada carpeta chrN_hap2/ (profundidad 2 desde BASE_DIR),
# evitando las copias duplicadas dentro de .EDTA.anno/, .EDTA.final/, etc.
mapfile -t GFF_FILES < <(find "$BASE_DIR" -mindepth 2 -maxdepth 2 -type f -name "$PATTERN" | sort -V)

if [ ${#GFF_FILES[@]} -eq 0 ]; then
    echo "Error: no se encontraron archivos '$PATTERN' en '$BASE_DIR'" >&2
    exit 1
fi

echo "Archivos encontrados (${#GFF_FILES[@]}), en este orden:"
printf '  %s\n' "${GFF_FILES[@]}"


cat > "$TMP_AWK" << 'AWK_EOF'
BEGIN { FS = OFS = "\t" }

function split_id(value,    n, num, pre) {
    n = split(value, parts, "_")
    num = parts[n]
    if (num !~ /^[0-9]+$/) return ""
    pre = value
    sub("_" num "$", "", pre)
    return pre SUBSEP num
}

function rewrite_attrs(attrs,    n, i, kv, key, val, sp, pre, num, newnum, out) {
    n = split(attrs, parts2, ";")
    out = ""
    for (i = 1; i <= n; i++) {
        if (parts2[i] ~ /^(ID|Parent)=/) {
            split(parts2[i], kv, "=")
            key = kv[1]; val = kv[2]
            sp = split_id(val)
            if (sp != "") {
                split(sp, pn, SUBSEP)
                pre = pn[1]; num = pn[2] + 0
                if (num > filemax[pre]) filemax[pre] = num
                if (!(pre in offset)) offset[pre] = 0
                newnum = num + offset[pre]
                parts2[i] = key "=" pre "_" newnum
            }
        }
        out = (i == 1) ? parts2[i] : out ";" parts2[i]
    }
    return out
}

# Al empezar un nuevo archivo (nuevo cromosoma), consolidar los
# offsets con los maximos vistos en el archivo anterior.
FNR == 1 {
    if (NR > 1) {
        for (pre in filemax) offset[pre] += filemax[pre] + 1
    }
    delete filemax
}

/^$/ { next }
/^##/ && !/^###$/ { next }
/^###$/ { print; next }

{
    $9 = rewrite_attrs($9)
    print
}
AWK_EOF


{
    head -1 "${GFF_FILES[0]}"
    echo "## NOTE: unified genome-wide GFF3 generated from per-chromosome EDTA TEanno outputs (ID and Parent attributes renumbered to be unique and continuous across the genome)."
    grep -E '^##' "${GFF_FILES[0]}" | grep -v '^###$' | tail -n +2
} > "$OUTPUT"


awk -f "$TMP_AWK" "${GFF_FILES[@]}" > "$TMP_BODY"
cat "$TMP_BODY" >> "$OUTPUT"


echo ""
echo "GFF3 unificado escrito en: $OUTPUT"
echo "Total de lineas de feature (sin contar separadores ###): $(grep -vc '^###$' "$TMP_BODY")"
echo ""
echo "Resumen de features por cromosoma:"
grep -v '^###$' "$TMP_BODY" | cut -f1 | sort -V | uniq -c
echo ""
echo "Comprobacion de IDs duplicados (debería no devolver nada):"
DUPES=$(grep -oP 'ID=[^;]+' "$TMP_BODY" | sort | uniq -d || true)
if [ -z "$DUPES" ]; then
    echo "  (ninguno - OK)"
else
    echo "$DUPES"
fi
