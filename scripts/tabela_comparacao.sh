#!/bin/sh

# Gera as tabelas LaTeX do relatorio que dependem de execucao, a partir de
# dados/comparacao-N.dat (comparacao.sh) e dados/sqrt-15-N.dat (test.sh):
#   dados/tabela_iter.tex        Iteracoes de q+u via test.sh   (tab:iter)
#   dados/tabela_inclinacao.tex  Iteracoes por digito           (tab:inclinacao)
#   dados/tabela_comp_iter.tex   Iteracoes de p+u e q+u         (tab:comp-iter)
#   dados/tabela_comp_tempo.tex  Tempos (mediana) de p+u e q+u  (tab:comp-tempo)
#   dados/tabela_isolados.tex    Babilonico isolado vs q_k      (tab:isolados)
#   dados/comparacao_macros.tex  Macros citadas no texto (incluido no preambulo)
#
# Nao edite os arquivos gerados a mao: rode scripts/gerar_tudo.sh.

NAME="${0##*/}"
NAME="${NAME%.*}"

### Config

# Executa a partir da raiz do projeto (pasta acima de scripts/)
cd "$(dirname "$0")/.." || exit 1

DATDIR="dados"
LIST_N="2 24 67"

HDR="% ARQUIVO GERADO AUTOMATICAMENTE por scripts/tabela_comparacao.sh.
% Nao edite a mao: rode scripts/gerar_tudo.sh para atualizar.
"

### Sanity check

for N in $LIST_N
do
	for f in "$DATDIR/comparacao-$N.dat" "$DATDIR/sqrt-15-$N.dat"
	do
		test -f "$f" || { echo "$NAME: falta $f"; exit 1; }
	done
done

COMP=$(for N in $LIST_N; do echo "$DATDIR/comparacao-$N.dat"; done)
SQRT=$(for N in $LIST_N; do echo "$DATDIR/sqrt-15-$N.dat"; done)

newest=$(ls -t $COMP | head -1)
when=$(date -r "$newest" '+%d/%m/%Y às %H:%M')

# Funcoes awk comuns: N a partir do nome do arquivo e formatacao numerica
AWKLIB='
function fileN(f) { sub(/.*-/, "", f); sub(/\.dat$/, "", f); return f }
function sci(x,    s, p, m, e) {
	s = sprintf("%.1e", x); split(s, p, "e")
	m = p[1]; e = p[2] + 0; sub(/\./, "{,}", m)
	return "$" m " \\times 10^{" e "}$"
}
function milhar(n,    s, r) {
	s = sprintf("%d", n); r = ""
	while (length(s) > 3) { r = "." substr(s, length(s) - 2) r; s = substr(s, 1, length(s) - 3) }
	return s r
}
function dec(x, d,    s) { s = sprintf("%." d "f", x); sub(/\./, "{,}", s); return s }
'

### Do the job

set -x

# --- Iteracoes de q+u (test.sh) --------------------------------------
awk -v listn="$LIST_N" -v hdr="$HDR" "$AWKLIB"'
{ n = fileN(FILENAME); it[n, $1] = $2 }
END {
	nn = split(listn, N, " "); nr = split("1 2 3 4 5 6 8 10 12 15", R, " ")
	print hdr
	print "\\begin{table}[H]\n\\centering"
	print "\\caption{Número de iterações do laço conjunto $q_k + u_k$ até $u - q < 10^{-k}$, obtido com \\texttt{scripts/test.sh} (adaptado).}"
	print "\\label{tab:iter}"
	print "\\begin{tabular}{cc rrr}\n\\toprule"
	printf "Expoente ($k$) & Tolerância ($\\varepsilon$)"
	for (i = 1; i <= nn; i++) printf " & $N = %s$", N[i]
	print "\\\\\n\\midrule"
	for (j = 1; j <= nr; j++) {
		printf "%s & $10^{-%s}$", R[j], R[j]
		for (i = 1; i <= nn; i++) printf " & %s", milhar(it[N[i], R[j]])
		print " \\\\"
	}
	print "\\bottomrule\n\\end{tabular}\n\\end{table}"
}' $SQRT > "$DATDIR/tabela_iter.tex"

# --- Iteracoes por digito: teoria x observado -------------------------
awk -v listn="$LIST_N" -v hdr="$HDR" "$AWKLIB"'
{ n = fileN(FILENAME); it[n, $1] = $2; if ($1 > km[n]) km[n] = $1 }
END {
	nn = split(listn, N, " ")
	print hdr
	print "\\begin{table}[H]\n\\centering"
	print "\\caption{Iterações por dígito decimal do laço $q_k + u_k$: previsão $-1/\\log_{10} r$, com $r = 1 - 2\\sqrt{N}/(2N+1)$, e inclinação observada na Tabela~\\ref{tab:iter} (de $k = 1$ a $k = 15$).}"
	print "\\label{tab:inclinacao}"
	printf "\\begin{tabular}{l "; for (i = 1; i <= nn; i++) printf "c"; print "}\n\\toprule"
	printf " "; for (i = 1; i <= nn; i++) printf " & $N = %s$", N[i]; print "\\\\\n\\midrule"
	printf "Razão $r$"
	for (i = 1; i <= nn; i++) { s = sqrt(N[i]); r[i] = 1 - 2*s/(2*N[i]+1); printf " & %s", dec(r[i], 3) }
	print " \\\\"
	printf "Iterações por dígito (previsão)"
	for (i = 1; i <= nn; i++) printf " & %s", dec(-1/(log(r[i])/log(10)), 1)
	print " \\\\"
	printf "Iterações por dígito (observado)"
	for (i = 1; i <= nn; i++) printf " & %s", dec((it[N[i], km[N[i]]] - it[N[i], 1]) / (km[N[i]] - 1), 1)
	print " \\\\"
	print "\\bottomrule\n\\end{tabular}\n\\end{table}"
}' $SQRT > "$DATDIR/tabela_inclinacao.tex"

# --- Comparacao p+u x q+u: iteracoes e tempos ------------------------
for kind in iter tempo
do
	awk -v listn="$LIST_N" -v hdr="$HDR" -v kind="$kind" -v when="$when" "$AWKLIB"'
	{ n = fileN(FILENAME)
	  ip[n, $1] = $2; sp[n, $1] = $3; tp[n, $1] = $4
	  iq[n, $1] = $5; sq[n, $1] = $6; tq[n, $1] = $7 }
	END {
		nn = split(listn, N, " "); nr = split("1 4 8 12 15", R, " ")
		print hdr
		print "\\begin{table}[H]\n\\centering"
		if (kind == "iter") {
			print "\\caption{Iterações até a cota do erro ficar menor que $10^{-k}$: $p_k + u_k$ (critério $u - p$) e $q_k + u_k$ (critério $u - q$). Fonte: \\texttt{scripts/comparacao.sh}.}"
			print "\\label{tab:comp-iter}"
		} else {
			print "\\caption{Tempo de execução (mediana de \\RepeticoesComparacao{} repetições, em segundos) até a cota do erro ficar menor que $10^{-k}$, medido em \\ComparacaoMedidaEm. Fonte: \\texttt{scripts/comparacao.sh}.}"
			print "\\label{tab:comp-tempo}"
		}
		printf "\\begin{tabular}{c"; for (i = 1; i <= nn; i++) printf " rr"; print "}\n\\toprule"
		printf " "; for (i = 1; i <= nn; i++) printf " & \\multicolumn{2}{c}{$N = %s$}", N[i]; print "\\\\"
		for (i = 1; i <= nn; i++) printf "\\cmidrule(lr){%d-%d}", 2*i, 2*i+1; print ""
		printf "$k$"; for (i = 1; i <= nn; i++) printf " & $p_k + u_k$ & $q_k + u_k$"; print "\\\\\n\\midrule"
		for (j = 1; j <= nr; j++) {
			k = R[j]; printf "%s", k
			for (i = 1; i <= nn; i++) {
				n = N[i]
				if (kind == "iter") {
					printf " & %s%s & %s%s", milhar(ip[n, k]), (sp[n, k] ? "$^{\\dagger}$" : ""), \
						milhar(iq[n, k]), (sq[n, k] ? "$^{\\dagger}$" : "")
				} else
					printf " & %s & %s", sci(tp[n, k]), sci(tq[n, k])
			}
			print " \\\\"
		}
		print "\\bottomrule\n\\end{tabular}"
		if (kind == "iter")
			print "\n\\smallskip\n{\\small $^{\\dagger}$O laço foi interrompido porque $p_k$ estacionou em \\texttt{long double} antes de atingir a tolerância.}"
		print "\\end{table}"
	}' $COMP > "$DATDIR/tabela_comp_$kind.tex"
done

# --- Babilonico isolado x q_k isolado (k = 15) -----------------------
awk -v listn="$LIST_N" -v hdr="$HDR" "$AWKLIB"'
{ n = fileN(FILENAME); if ($1 > km[n]) km[n] = $1
  iu[n, $1] = $8; tu[n, $1] = $10; iq[n, $1] = $11; tq[n, $1] = $13 }
END {
	nn = split(listn, N, " ")
	print hdr
	print "\\begin{table}[H]\n\\centering"
	print "\\caption{Babilônico isolado (critério $u - N/u$) e $q_k$ isolado (critério $N/q - q$), com erro menor que $10^{-15}$. Tempos: mediana de \\RepeticoesComparacao{} repetições. Fonte: \\texttt{scripts/comparacao.sh}.}"
	print "\\label{tab:isolados}"
	print "\\begin{tabular}{c rr cc r}\n\\toprule"
	print " & \\multicolumn{2}{c}{Iterações} & \\multicolumn{2}{c}{Tempo (s)} & \\\\"
	print "\\cmidrule(lr){2-3}\\cmidrule(lr){4-5}"
	print "$N$ & $u_k$ & $q_k$ & $u_k$ & $q_k$ & Razão de tempo $q_k/u_k$\\\\\n\\midrule"
	for (i = 1; i <= nn; i++) {
		n = N[i]; k = km[n]
		printf "%s & %s & %s & %s & %s & %s \\\\\n", n, milhar(iu[n, k]), milhar(iq[n, k]), \
			sci(tu[n, k]), sci(tq[n, k]), dec(tq[n, k] / tu[n, k], 0)
	}
	print "\\bottomrule\n\\end{tabular}\n\\end{table}"
}' $COMP > "$DATDIR/tabela_isolados.tex"

# --- Macros citadas no texto -----------------------------------------
reps=$(grep -m1 '^REPS=' scripts/comparacao.sh | sed 's/.*:-\([0-9]*\)}.*/\1/')
awk -v hdr="$HDR" -v when="$when" -v reps="$reps" "$AWKLIB"'
{ n = fileN(FILENAME); tp[n, $1] = $4; tq[n, $1] = $7 }
END {
	print hdr
	print "\\newcommand{\\ComparacaoMedidaEm}{" when "}"
	print "\\newcommand{\\RepeticoesComparacao}{" reps "}"
	print "\\newcommand{\\FatorTempoPuQu}{" milhar(tp[67, 12] / tq[67, 12] + 0.5) "}"
}' $COMP > "$DATDIR/comparacao_macros.tex"

### Exit gracefully

exit $?
