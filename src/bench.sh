#!/bin/bash
# bench.sh - roda os benchmarks de quicksort e radix sort para vários
# tamanhos de entrada, repetindo medições pequenas para reduzir ruído.
# Gera: raw_results.csv (uma linha por execução) em /home/claude/iaa-ep2/build
set -uo pipefail

OUT=raw_results.csv
echo "algoritmo;n;repeticao;seed;tempo_clock_s;tempo_wall_s;ok_ordenado" > "$OUT"

# tamanho -> número de repetições (tamanhos pequenos repetem mais para
# compensar o ruído de medição; tamanhos grandes já são pouco ruidosos e
# repetir muitas vezes custaria tempo sem ganho estatístico relevante)
declare -A REPS=(
  [1000]=7
  [10000]=7
  [100000]=5
  [500000]=5
  [1000000]=3
  [5000000]=3
  [10000000]=3
  [50000000]=2
  [100000000]=2
  [200000000]=1
)

SIZES=(1000 10000 100000 500000 1000000 5000000 10000000 50000000 100000000 200000000)
TIMEOUT_S=3600

for n in "${SIZES[@]}"; do
  reps=${REPS[$n]}
  for r in $(seq 1 "$reps"); do
    seed=$(( n * 1000003 + r * 7919 + 12345 ))
    infile="/tmp/arr_${n}_${r}.bin"
    ./gen_input "$n" "$seed" "$infile"
    for algo in qs radix; do
      line=$(timeout ${TIMEOUT_S} ./run_sort "$algo" "$infile")
      status=$?
      if [ $status -eq 124 ]; then
        echo "${algo};${n};${r};${seed};timeout reached;timeout reached;0" >> "$OUT"
        echo "TIMEOUT: algo=$algo n=$n rep=$r excedeu ${TIMEOUT_S}s" >&2
      else
        echo "${line};${r};${seed}" | awk -F';' '{print $1";"$2";"$6";"$7";"$3";"$4";"$5}' >> "$OUT"
      fi
    done
    rm -f "$infile"
  done
  echo "tamanho $n concluido" >&2
done

echo "benchmarks concluidos -> $OUT" >&2
