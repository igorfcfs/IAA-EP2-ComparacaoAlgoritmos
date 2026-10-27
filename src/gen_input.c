/* gen_input.c - gera um array de inteiros pseudoaleatórios (usando o gerador
 * de rng.c/rng.h, o mesmo fornecido pelo professor) e grava em um arquivo
 * binário: primeiro um `long int` com o comprimento, depois os `int`s.
 *
 * Gerar o array UMA vez por tamanho e reutilizá-lo para todos os algoritmos
 * testados garante que cada algoritmo seja medido sobre exatamente a mesma
 * entrada, eliminando a variação aleatória da entrada como variável de
 * confusão na comparação dos tempos.
 *
 * uso: ./gen_input <n> <seed> <arquivo_saida>
 * compilação: gcc -O2 rng.c utilarray.c gen_input.c -o gen_input
 */
#include "utilarray.h"
#include <stdlib.h>

int main(int argc, char **argv) {
  if (argc != 4) {
    fprintf(stderr, "uso: %s <n> <seed> <arquivo_saida>\n", argv[0]);
    return 1;
  }
  long int n = atol(argv[1]);
  long long seed = atoll(argv[2]);
  const char *outpath = argv[3];

  Array a = alocaArray(n);
  if (a.A == NULL) {
    fprintf(stderr, "gen_input: falha ao alocar %ld inteiros\n", n);
    return 1;
  }
  setSeed(seed);
  randArray(a);

  FILE *f = fopen(outpath, "wb");
  if (f == NULL) {
    fprintf(stderr, "gen_input: falha ao abrir %s para escrita\n", outpath);
    return 1;
  }
  fwrite(&a.length, sizeof(long int), 1, f);
  fwrite(a.A, sizeof(int), a.length, f);
  fclose(f);

  dealocaArray(a);
  return 0;
}
