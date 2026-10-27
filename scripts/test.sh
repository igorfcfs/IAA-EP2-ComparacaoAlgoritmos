#!/bin/sh

NAME="${0##*/}"
NAME="${NAME%.*}"

PID="$$"

### Config

# Executa a partir da raiz do projeto (pasta acima de scripts/)
cd "$(dirname "$0")/.." || exit 1

SRCDIR="src"
DATDIR="dados"
SCRIPTDIR="scripts"
PROG="sqrt_time"

### Command line

MAX_VAL="$1"
N="$2"

### Sanity check

test -n "$MAX_VAL" || { echo "Usage: ${0##*/} EXPONENT"; exit 1; }

dat="${PROG%%_*}-${MAX_VAL}"
test -z "$N" || dat="${dat}-${N}"

out="$DATDIR/${dat}.dat"
 
### API

compile(){ gcc -O2 -Wall -I include -lrt -o "${1##*/}" "${1}.c" -lm; }
clean(){ rm -f "$1"; }

date_utc(){ date --utc +%Y%m%d%Z%H%M%S; }
ts(){ echo "${NAME}_$(date_utc)_${PID}"; }

### Do the job

set -x

clean "$PROG"

compile "$SRCDIR/$PROG"

for x in $(seq $MAX_VAL)
do
	./$PROG $x "$N" | grep -E "$REGEX" | cut -d' ' -f2 | tr "\n" ' '
	echo
done > "$out"

clean "$PROG"

/usr/bin/Rscript --vanilla "$SCRIPTDIR/plots.R" "$dat" "$N"

### Exit gracefully

exit $?
