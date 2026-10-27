#!/bin/sh

NAME="${0##*/}"
NAME="${NAME%.*}"

### Config

# Executa a partir da raiz do projeto (pasta acima de scripts/)
cd "$(dirname "$0")/.." || exit 1

SRCDIR="src"
DATDIR="dados"

### API

compile(){ gcc -O2 -Wall -o "${1##*/}" "${1}.c" -lm; }
clean(){ rm -f "$1"; }

# Babilonico vs. sqrtl vs. bc para N = 67 (Secao 3.5)

out="$DATDIR/precisao-67.txt"

### Do the job

set -x

clean babilonico
clean sqrt_time
compile "$SRCDIR/babilonico"
compile "$SRCDIR/sqrt_time"

{
	echo "### ./sqrt_time 15 67"
	./sqrt_time 15 67 2>&1
	echo
	echo "### ./babilonico 67 8"
	./babilonico 67 8
	echo
	echo "### echo 'scale=30; sqrt(67)' | bc"
	echo 'scale=30; sqrt(67)' | bc
} > "$out"

clean babilonico
clean sqrt_time

### Exit gracefully

exit $?
