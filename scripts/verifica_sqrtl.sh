#!/bin/sh

# Verifica como a funcao sqrtl da libm do sistema e implementada,
# desmontando-a com objdump (Secao 3.5 do Relatorio). Grava o resultado em
# dados/sqrtl-objdump.txt. Em x86_64 com glibc, espera-se que sqrtl
# desvie para __sqrtl_finite, que executa a instrucao fsqrt da FPU x87.

NAME="${0##*/}"
NAME="${NAME%.*}"

### Config

# Executa a partir da raiz do projeto (pasta acima de scripts/)
cd "$(dirname "$0")/.." || exit 1

DATDIR="dados"
out="$DATDIR/sqrtl-objdump.txt"

LIBM=$(ldconfig -p | awk '/libm\.so\.6 \(libc6,x86-64\)/{print $NF; exit}')

test -n "$LIBM" || { echo "$NAME: libm nao encontrada"; exit 1; }

# Endereco e tamanho de um simbolo da tabela dinamica
symrange(){ objdump -T "$LIBM" | awk -v s="$1" '$NF == s {print $1, $5; exit}'; }

disasm(){
	set -- $(symrange "$1")
	test -n "$1" || return
	start=$((0x$1)); stop=$((0x$1 + 0x$2))
	objdump -d --no-show-raw-insn --start-address=$start --stop-address=$stop "$LIBM" |
		sed -n '/>:$/,$p'
}

### Do the job

{
	echo "### Biblioteca: $LIBM ($(ldd --version | head -1))"
	echo
	echo "### sqrtl"
	disasm sqrtl
	echo
	echo "### __sqrtl_finite"
	disasm __sqrtl_finite
} > "$out"

grep -q fsqrt "$out" && echo "fsqrt encontrada em $out" || echo "fsqrt NAO encontrada em $out"

### Exit gracefully

exit 0
