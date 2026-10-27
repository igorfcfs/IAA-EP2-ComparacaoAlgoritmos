#!/bin/sh

# Registra o ambiente de execucao (sistema, processador, compilador,
# bibliotecas e R) em dados/ambiente.txt e gera dados/ambiente_macros.tex,
# incluido no preambulo do Relatorio (Secao 2.1).

NAME="${0##*/}"
NAME="${NAME%.*}"

### Config

# Executa a partir da raiz do projeto (pasta acima de scripts/)
cd "$(dirname "$0")/.." || exit 1

DATDIR="dados"

### Do the job

so=$(. /etc/os-release 2>/dev/null && echo "$PRETTY_NAME")
kernel=$(uname -r)
arch=$(uname -m)
cpu=$(lscpu 2>/dev/null | sed -n 's/^Model name: *//p' | head -1)
gccv=$(gcc -dumpfullversion 2>/dev/null)
glibc=$(ldd --version 2>/dev/null | head -1 | sed 's/.* //')
rv=$(Rscript -e 'cat(paste(R.version$major, R.version$minor, sep = "."))' 2>/dev/null)
ggv=$(Rscript -e 'cat(as.character(packageVersion("ggplot2")))' 2>/dev/null)
bcv=$(bc --version 2>/dev/null | head -1)

{
	echo "Sistema:     $so"
	echo "Kernel:      $kernel ($arch)"
	echo "Processador: $cpu"
	echo "GCC:         $gccv"
	echo "glibc:       $glibc"
	echo "R:           $rv"
	echo "ggplot2:     $ggv"
	echo "bc:          $bcv"
} > "$DATDIR/ambiente.txt"

# printf evita que o echo do sh interprete \\n em \\newcommand
macro(){ printf '\\newcommand{\\%s}{%s}\n' "$1" "$2"; }

tex(){ printf '%s' "$1" | sed 's/_/\\_/g; s/(R)/\\textregistered{}/g; s/(TM)/\\texttrademark{}/g'; }

{
	echo "% ARQUIVO GERADO AUTOMATICAMENTE por scripts/ambiente.sh. Nao edite a mao."
	macro AmbienteSO "$(tex "$so")"
	macro AmbienteKernel "$(tex "$kernel") ($(tex "$arch"))"
	macro AmbienteCPU "$(tex "$cpu")"
	macro AmbienteGCC "$(tex "$gccv")"
	macro AmbienteGlibc "$(tex "$glibc")"
	macro AmbienteR "$(tex "$rv")"
	macro AmbienteGgplot "$(tex "$ggv")"
} > "$DATDIR/ambiente_macros.tex"

### Exit gracefully

exit 0
