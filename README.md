# EP2 - IAA: quicksort vs radix sort

Ver `respostas_EP2.docx` (ou `.md`) para as respostas às 5 questões do
questionário, incluindo a discussão científica pedida na questão 5.

- `src/` - todo o código-fonte (C), incluindo o fornecido pelo professor
  (rng, utilarray, elapsedRunningTime) sem alterações, e o implementado
  para este EP (quicksort.c, radixsort.c, gen_input.c, run_sort.c,
  secretkey_gen.c, bench.sh).
- `resultados/` - CSV bruto de todas as execuções, agregados (média/desvio)
  em JSON, e o gráfico comparativo.

## Como compilar e rodar
```
cd src
gcc -O2 rng.c utilarray.c gen_input.c -o gen_input
gcc -O2 rng.c utilarray.c elapsedRunningTime.c quicksort.c radixsort.c run_sort.c -o run_sort
./bench.sh   # roda toda a bateria de testes, gera raw_results.csv
```
