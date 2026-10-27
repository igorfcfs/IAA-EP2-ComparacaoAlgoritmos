#!/bin/sh

# Varredura em N (numeros que nao sao quadrados perfeitos, de 2 a MAX_N)
# com tolerancia fixa 10^-EXPONENT, para os metodos p+u e q+u
# (observacao da p. 256 das Notas de Aula sobre a degradacao com N).
# Gera dados/varredura-EXPONENT.dat com as colunas:
#   N  iter_pu stall_pu time_pu  iter_qu stall_qu time_qu
# e o grafico graficos/varredura-EXPONENT.png.

NAME="${0##*/}"
NAME="${NAME%.*}"

### Config

# Executa a partir da raiz do projeto (pasta acima de scripts/)
cd "$(dirname "$0")/.." || exit 1

SRCDIR="src"
DATDIR="dados"
SCRIPTDIR="scripts"
PROG="comparacao"

EXPONENT="${1:-10}"
MAX_N="${2:-200}"
REPS="${3:-5}"

out="$DATDIR/varredura-$EXPONENT.dat"

### API

compile(){ gcc -O2 -Wall -o "${1##*/}" "${1}.c" -lm; }
clean(){ rm -f "$1"; }

measure(){
	./$PROG "$1" "$2" "$3" "$REPS" 2>/dev/null |
		awk -F': ' '/^iterations/{i=$2} /^stalled/{s=$2} /^median_time/{t=$2}
			END{printf "%s %s %s", i, s, t}'
}

is_square(){ awk -v n="$1" 'BEGIN{ r = int(sqrt(n) + 0.5); exit !(r*r == n) }'; }

### Do the job

set -x

clean "$PROG"
compile "$SRCDIR/$PROG"

for N in $(seq 2 $MAX_N)
do
	is_square $N && continue
	echo "$N $(measure pu $EXPONENT $N) $(measure qu $EXPONENT $N)"
done > "$out"

clean "$PROG"

/usr/bin/Rscript --vanilla "$SCRIPTDIR/plot_varredura.R" "$EXPONENT"

### Exit gracefully

exit $?
