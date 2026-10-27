#!/bin/sh

# Compara os metodos p+u, q+u, u (isolado) e q (isolado) para N = 2, 24
# e 67 e expoentes do erro 1..MAX_VAL (Exercicios 16.2.4 a 16.2.7).
# Gera dados/comparacao-N.dat com as colunas:
#   k  iter_pu stall_pu time_pu  iter_qu stall_qu time_qu
#      iter_u stall_u time_u  iter_q stall_q time_q
# (tempos = mediana de REPS repeticoes, em segundos)
# e os graficos graficos/comparacao-iter.png e graficos/comparacao-time.png.

NAME="${0##*/}"
NAME="${NAME%.*}"

### Config

# Executa a partir da raiz do projeto (pasta acima de scripts/)
cd "$(dirname "$0")/.." || exit 1

SRCDIR="src"
DATDIR="dados"
SCRIPTDIR="scripts"
PROG="comparacao"

MAX_VAL="${1:-15}"
REPS="${2:-21}"
LIST_N="2 24 67"

### API

compile(){ gcc -O2 -Wall -o "${1##*/}" "${1}.c" -lm; }
clean(){ rm -f "$1"; }

# Imprime "iteracoes stalled tempo" de uma execucao
measure(){
	./$PROG "$1" "$2" "$3" "$REPS" 2>/dev/null |
		awk -F': ' '/^iterations/{i=$2} /^stalled/{s=$2} /^median_time/{t=$2}
			END{printf "%s %s %s", i, s, t}'
}

### Do the job

set -x

clean "$PROG"
compile "$SRCDIR/$PROG"

for N in $LIST_N
do
	for x in $(seq $MAX_VAL)
	do
		echo "$x $(measure pu $x $N) $(measure qu $x $N) $(measure u $x $N) $(measure q $x $N)"
	done > "$DATDIR/comparacao-$N.dat"
done

clean "$PROG"

/usr/bin/Rscript --vanilla "$SCRIPTDIR/plot_comparacao.R" $LIST_N

### Exit gracefully

exit $?
