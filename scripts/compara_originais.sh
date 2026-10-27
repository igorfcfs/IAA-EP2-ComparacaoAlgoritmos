#!/bin/sh

# Compara os Scripts do Professor originais (anexos/sqrt.zip e
# anexos/sqrt_time.zip) com as versoes usadas no Trabalho (src/ e
# scripts/), gravando as diferencas em dados/diff_scripts_professor.txt.
# Base da Secao "Fontes" do Relatorio (original x adaptado).

NAME="${0##*/}"
NAME="${NAME%.*}"

### Config

# Executa a partir da raiz do projeto (pasta acima de scripts/)
cd "$(dirname "$0")/.." || exit 1

out="dados/diff_scripts_professor.txt"
tmp=$(mktemp -d) || exit 1
trap 'rm -rf "$tmp"' EXIT

# original no zip -> arquivo no Trabalho
PAIRS="sqrt/sqrt.c:src/sqrt.c
sqrt/plots.sh:scripts/plots.sh
sqrt/plots.R:scripts/plot_trajetoria.R
sqrt_time/sqrt_time.c:src/sqrt_time.c
sqrt_time/test.sh:scripts/test.sh
sqrt_time/plots.R:scripts/plots.R"

### Do the job

unzip -oq anexos/sqrt.zip -d "$tmp" || exit 1
unzip -oq anexos/sqrt_time.zip -d "$tmp" || exit 1

{
	for p in $PAIRS
	do
		orig="${p%%:*}"; atual="${p#*:}"
		if cmp -s "$tmp/$orig" "$atual"
		then
			echo "### $orig -> $atual: ORIGINAL (sem alteracoes)"
		else
			echo "### $orig -> $atual: ADAPTADO"
			diff -u "$tmp/$orig" "$atual" | tail -n +3
		fi
		echo
	done
} > "$out"

grep '^###' "$out"

### Exit gracefully

exit 0
