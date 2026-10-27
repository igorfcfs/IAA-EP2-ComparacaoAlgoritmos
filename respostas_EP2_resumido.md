---
title: "EP2 — IAA: Quicksort vs Radix Sort (Resumo)"
author: "Igor Fernando Casita Ferreira da Silva — RA 18245598"
date: \today
---

# Resumo

Comparação empírica entre **Quicksort** (mediana-de-3 + partição de
Hoare + corte para inserção + eliminação de recursão de cauda) e
**Radix Sort** (LSD, base 256, 4 passadas), em C, rodando no computador
pessoal do aluno (Windows 11, i7-1355U, 16 GB RAM, gcc/MinGW-w64 `-O2`).
Chave secreta: **1906028835** (RA 18245598, 31 iterações de `next(31)`
sobre o LCG de `java.util.Random`).

## Algoritmos — o essencial

| | Quicksort | Radix Sort |
|---|---|---|
| Tipo | Comparação, *in-place*, divisão e conquista | Contagem/distribuição, não-comparativo, LSD |
| Tempo médio | Θ(n log n) | Θ(n) (4 passadas fixas, base 256, p/ int de 32 bits) |
| Pior caso | Θ(n²) (raro, mitigado por mediana-de-3) | Θ(n) sempre |
| Espaço extra | O(log n) (pilha) | O(n) (array auxiliar do mesmo tamanho) |
| Por que o radix não viola Ω(n log n)? | — | Nunca compara chaves entre si; indexa diretamente pelos dígitos, por isso escapa do limite inferior que vale só para ordenação por comparação |

## Resultados (tempo de parede, médias)

| n | Quicksort (s) | Radix Sort (s) | razão |
|---:|---:|---:|---:|
| 1.000 | 0,0000377 | 0,0000057 | 6,6× |
| 100.000 | 0,005271 | 0,000667 | 7,9× |
| 1.000.000 | 0,055610 | 0,008487 | 6,6× |
| 10.000.000 | 0,614553 | 0,078156 | 7,9× |
| 100.000.000 | 7,713330 | 0,951264 | 8,1× |
| 200.000.000 | 14,147100 | 1,563120 | 9,1× |

![Tempo vs n](graficos/01_tempo_vs_n_loglog.png)

**Regressão log-log** (tempo ~ n^k): quicksort k = 1,056 (R² = 0,9999);
radix sort k = 1,023 (R² = 0,9993) — confirma que o quicksort cresce
visivelmente mais rápido que linear (fator log n extra), enquanto o
radix sort é estatisticamente compatível com Θ(n) puro.

**Teste pareado (Wilcoxon, 68 pares, mesma entrada nos dois algoritmos):**
quicksort mais lento que radix em 100% dos pares, p ≈ 7,8×10⁻¹³ —
diferença sistemática, não ruído.

## O achado mais interessante: em n = 2 bilhões, a vantagem se inverte

| | Quicksort | Radix Sort |
|---|---:|---:|
| T(2E9), execução única | 222,2 s | **503,5 s** (mais lento!) |

Motivo: em n=2×10⁹, um array de `int` ocupa 8 GB. O quicksort é
in-place (usa só esses 8 GB). O radix sort aloca um **segundo** array
auxiliar do mesmo tamanho — ~16 GB no pico, basicamente toda a RAM da
máquina (16 GB), forçando paginação em disco. `platforminfo.h` registrou
28,8 GB de memória virtual em uso no momento dos testes, confirmando a
pressão de memória. **Conclusão prática:** o radix sort tem melhor
complexidade de tempo, mas sua maior complexidade espacial (O(n) vs.
O(log n) do quicksort) o torna mais lento assim que o problema se
aproxima do limite de RAM física — complexidade assintótica de tempo não
é tudo quando o espaço auxiliar também escala com n.

**T(6E9), T(8E9), T(10E9): não testados** — exigiriam 24–40 GB (além dos
16 GB disponíveis) e, no Windows (modelo de dados LLP64), o campo
`long int length` do array é de apenas 32 bits (ao contrário do Linux,
onde é de 64 bits), limitando o tamanho máximo representável a
~2,147 bilhões independentemente da RAM.

## Código-fonte

Entregue em `src/`: `quicksort.c/h`, `radixsort.c/h` (implementações
próprias), `rng.c/h`, `utilarray.c/h`, `elapsedRunningTime.c/h`
(fornecidos pelo professor, sem alteração), `gen_input.c`, `run_sort.c`,
`benchmark_clock.c`, `secretkey_gen.c`. Compilado com
`gcc -O2` (MinGW-w64 13.2.0).

*(Ver relatório completo para fundamentação teórica detalhada, tabela
estatística completa, metodologia e demais gráficos.)*
