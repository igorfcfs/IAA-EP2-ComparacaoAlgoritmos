#!/bin/sh

# Gera, a partir de dados/sqrt-15-N.dat (saida de test.sh):
#   - dados/tabela_tempos.tex: a Tabela de tempos (rotulo tab:tempo),
#     incluida no corpo do relatorio com \input;
#   - dados/tempos_macros.tex: macros incluidas no preambulo do relatorio.
# Assim, a tabela e o texto que cita tempos acompanham sempre a ultima
# execucao de test.sh.
#
# Macros definidas em tempos_macros.tex:
#   - \TempoGeradoEm: data e hora da medicao (modificacao do .dat mais
#     recente);
#   - \ExemploRuido: frase com o primeiro caso em que o tempo diminui
#     embora o numero de iteracoes aumente (ou frase alternativa, se nao
#     houver tal caso).

NAME="${0##*/}"
NAME="${NAME%.*}"

### Config

# Executa a partir da raiz do projeto (pasta acima de scripts/)
cd "$(dirname "$0")/.." || exit 1

DATDIR="dados"
LIST_N="2 24 67"
ROWS="2 4 6 10 15"

out="$DATDIR/tabela_tempos.tex"
macros="$DATDIR/tempos_macros.tex"

### Sanity check

for N in $LIST_N
do
	test -f "$DATDIR/sqrt-15-$N.dat" || {
		echo "$NAME: falta $DATDIR/sqrt-15-$N.dat (rode scripts/test.sh 15 $N)"
		exit 1
	}
done

# Data da medicao: arquivo .dat mais recente
newest=$(ls -t $(for N in $LIST_N; do echo "$DATDIR/sqrt-15-$N.dat"; done) | head -1)
when=$(date -r "$newest" '+%d/%m/%Y às %H:%M')

### Do the job

set -x

awk -v rows="$ROWS" -v listn="$LIST_N" -v when="$when" -v mfile="$macros" '
# Formata um numero como $m{,}m \times 10^{e}$
function sci(x,    s, m, e) {
	s = sprintf("%.1e", x)
	split(s, part, "e")
	m = part[1]; e = part[2] + 0
	sub(/\./, "{,}", m)
	return "$" m " \\times 10^{" e "}$"
}
function us(x,    s) {
	s = sprintf("%.3f", x * 1e6)
	sub(/\./, "{,}", s)
	return s "\\,\\mu$s"
}
{
	# FILENAME = dados/sqrt-15-N.dat
	n = FILENAME
	sub(/.*sqrt-15-/, "", n); sub(/\.dat$/, "", n)
	iter[n, $1] = $2
	t[n, $1] = $3
	if ($1 > kmax[n]) kmax[n] = $1
}
END {
	nn = split(listn, N, " ")
	nr = split(rows, R, " ")

	hdr = "% ARQUIVO GERADO AUTOMATICAMENTE por scripts/tabela_tempos.sh.\n" \
	      "% Nao edite a mao: rode scripts/gerar_tudo.sh (ou test.sh e\n" \
	      "% tabela_tempos.sh) para atualizar.\n"
	print hdr
	print hdr > mfile
	print "\\newcommand{\\TempoGeradoEm}{" when "}" > mfile

	# Exemplo de ruido: primeiro k em que o tempo cai com mais iteracoes
	# (com diferenca visivel na precisao exibida)
	found = 0
	for (i = 1; i <= nn && !found; i++)
		for (k = 1; k < kmax[N[i]] && !found; k++)
			if (t[N[i], k+1] < t[N[i], k] && us(t[N[i], k+1]) != us(t[N[i], k])) {
				found = 1
				printf "\\newcommand{\\ExemploRuido}{para $N = %s$, por exemplo, o tempo medido com $k = %d$ ($%s, %d iterações) é maior que o de $k = %d$ ($%s, %d iterações), como se vê na Figura~\\ref{fig:time%s}}\n", \
					N[i], k, us(t[N[i], k]), iter[N[i], k], \
					k+1, us(t[N[i], k+1]), iter[N[i], k+1], N[i] > mfile
			}
	if (!found)
		print "\\newcommand{\\ExemploRuido}{nesta execução os tempos cresceram de forma monótona, mas ao repetir a medição é comum surgirem casos em que um tempo diminui mesmo com mais iterações}" > mfile

	print "\\begin{table}[H]"
	print "\\centering"
	print "\\caption{Tempo de execução do laço (em segundos) via \\texttt{CLOCK\\_MONOTONIC}, medido em \\TempoGeradoEm.}"
	print "\\label{tab:tempo}"
	printf "\\begin{tabular}{c "
	for (i = 1; i <= nn; i++) printf "c"
	print "}"
	print "\\toprule"
	printf "Expoente ($k$)"
	for (i = 1; i <= nn; i++) printf " & $N = %s$ (s)", N[i]
	print "\\\\"
	print "\\midrule"
	for (j = 1; j <= nr; j++) {
		printf "%s", R[j]
		for (i = 1; i <= nn; i++) printf " & %s", sci(t[N[i], R[j]])
		print " \\\\"
	}
	print "\\bottomrule"
	print "\\end{tabular}"
	print "\\end{table}"
}
' $(for N in $LIST_N; do echo "$DATDIR/sqrt-15-$N.dat"; done) > "$out"

### Exit gracefully

exit $?
