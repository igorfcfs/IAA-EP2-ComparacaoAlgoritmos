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
PROG="sqrt"

### API

compile(){ gcc -O2 -Wall -I include -lrt -o "${1##*/}" "${1}.c" -lm; }
clean(){ rm -f "$1"; }

date_utc(){ date --utc +%Y%m%d%Z%H%M%S; }
ts(){ echo "${NAME}_$(date_utc)_${PID}"; }

### Do the job

set -x

clean "$PROG"

compile "$SRCDIR/$PROG"

./$PROG 18 > "$DATDIR/${PROG}-18.dat"
sleep 3
./$PROG 18 24 > "$DATDIR/${PROG}-18-24.dat"

clean "$PROG"

/usr/bin/Rscript --vanilla "$SCRIPTDIR/plot_trajetoria.R" sqrt-18 2
/usr/bin/Rscript --vanilla "$SCRIPTDIR/plot_trajetoria.R" sqrt-18-24 24

### Exit gracefully

exit $?
