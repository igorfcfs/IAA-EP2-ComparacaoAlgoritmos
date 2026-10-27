/* run_sort.c - lê um array binário gerado por gen_input.c, ordena com o
 * algoritmo escolhido medindo o tempo de execução SOMENTE da ordenação
 * (clock() e gettimeofday(), via elapsedRunningTime.c, igual ao fornecido
 * pelo professor em testSort.c), confere se o resultado ficou em ordem
 * crescente e imprime uma linha CSV com o resultado.
 *
 * uso: ./run_sort <qs|radix> <arquivo_entrada>
 * saida (stdout), CSV separado por ';':
 *   algoritmo;n;tempo_clock_s;tempo_wall_s;ok_ordenado(1/0)
 */
#include "utilarray.h"
#include "elapsedRunningTime.h"
#include "quicksort.h"
#include "radixsort.h"
#include <string.h>
#include <time.h>

extern clock_t begin, end;
extern struct timeval wbegin, wend;

int main(int argc, char **argv) {
  if (argc != 3) {
    fprintf(stderr, "uso: %s <qs|radix> <arquivo_entrada>\n", argv[0]);
    return 1;
  }
  const char *algo = argv[1];
  const char *inpath = argv[2];

  FILE *f = fopen(inpath, "rb");
  if (f == NULL) {
    fprintf(stderr, "run_sort: falha ao abrir %s\n", inpath);
    return 1;
  }
  Array a;
  fread(&a.length, sizeof(long int), 1, f);
  a.A = (int *)malloc(a.length * sizeof(int));
  if (a.A == NULL) {
    fprintf(stderr, "run_sort: falha ao alocar %ld inteiros\n", a.length);
    return 1;
  }
  fread(a.A, sizeof(int), a.length, f);
  fclose(f);

  start();
  if (strcmp(algo, "qs") == 0) {
    quicksort(a);
  } else if (strcmp(algo, "radix") == 0) {
    radixsort(a);
  } else {
    fprintf(stderr, "run_sort: algoritmo desconhecido '%s'\n", algo);
    return 1;
  }
  stop();

  long int r = crescente(a);
  int ok = (r == a.length) ? 1 : 0;

  double clockElapsed = (double)(end - begin) / CLOCKS_PER_SEC;
  long seconds = wend.tv_sec - wbegin.tv_sec;
  long microseconds = wend.tv_usec - wbegin.tv_usec;
  double wallElapsed = seconds + microseconds * 1.0e-6;

  printf("%s;%ld;%0.6f;%0.6f;%d\n", algo, a.length, clockElapsed,
         wallElapsed, ok);

  dealocaArray(a);
  return 0;
}
