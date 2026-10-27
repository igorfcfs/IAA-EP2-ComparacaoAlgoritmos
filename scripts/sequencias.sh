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

# Valores de p_k, q_k e u_k para N = 2 (Secoes 3.1.1 a 3.1.4)

PROG="sequencias"

### Do the job

set -x

clean "$PROG"
compile "$SRCDIR/$PROG"

./$PROG 2 5 > "$DATDIR/sequencias-2.txt"

clean "$PROG"

### Exit gracefully

exit $?
