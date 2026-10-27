#!/bin/sh

# Regenera todos os dados (dados/), graficos (graficos/) e tabelas
# automaticas do Relatorio, e recompila o Relatorio.
#
# Os tempos de execucao variam a cada rodada. As tabelas e frases do
# Relatorio que dependem de execucao NAO sao escritas a mao: elas sao
# geradas por tabela_tempos.sh e tabela_comparacao.sh a partir dos
# arquivos de dados/ e incluidas no Relatorio com \input. Assim, ao rodar
# este script, tabelas, graficos e texto ficam sempre consistentes.

cd "$(dirname "$0")" || exit 1

### Scripts do Professor (adaptados)
./plots.sh            || exit 1	# Trajetorias (N = 2 e 24)
./test.sh 15 2        || exit 1	# Iteracoes e tempo de q+u, N = 2
./test.sh 15 24       || exit 1	# Iteracoes e tempo de q+u, N = 24
./test.sh 15 67       || exit 1	# Iteracoes e tempo de q+u, N = 67

### Scripts do Grupo
./compara_originais.sh || exit 1	# Original x adaptado (Secao Fontes)
./comparacao.sh       || exit 1	# p+u, q+u, u e q (Exercicios 16.2.4-7)
./varredura_n.sh      || exit 1	# Varredura em N (p. 256 das Notas)
./sequencias.sh       || exit 1	# Valores das secoes 3.1.x
./precisao.sh         || exit 1	# Secao 3.5 (sqrt_time, babilonico, bc)
./verifica_sqrtl.sh   || exit 1	# Implementacao de sqrtl (objdump)
./ambiente.sh         || exit 1	# Ambiente de execucao (Secao 2.1)
./tabela_tempos.sh    || exit 1	# Tabela de tempos de test.sh
./tabela_comparacao.sh || exit 1	# Demais tabelas automaticas

### Recompila o Relatorio

cd .. || exit 1

if command -v latexmk >/dev/null 2>&1
then
	latexmk -pdf -interaction=nonstopmode -halt-on-error relatorio.tex \
		> /dev/null || { echo "Erro ao compilar relatorio.tex (veja relatorio.log)"; exit 1; }
	latexmk -c relatorio.tex > /dev/null
	echo "relatorio.pdf atualizado."
else
	echo "latexmk nao encontrado: compile relatorio.tex manualmente."
fi

exit 0
