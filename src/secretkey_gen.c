/* secretkey_gen.c - versão não-interativa de calcSecret.c (EP2), usada para
 * documentar de forma reprodutível a chave secreta utilizada neste
 * trabalho. O método é EXATAMENTE o mesmo de calcSecret.c: inicializa o
 * gerador congruente linear (mesmas constantes do java.util.Random) com
 * setSeed(seed) e aplica next(31) `vezes` vezes; o último valor
 * retornado é a chave secreta.
 * uso: ./secretkey_gen <seed> <vezes>
 */
#include "rng.h"
int main(int argc, char **argv) {
  if (argc != 3) {
    fprintf(stderr, "uso: %s <seed> <vezes>\n", argv[0]);
    return 1;
  }
  long long seed = atoll(argv[1]);
  int vezes = atoi(argv[2]);
  setSeed(seed);
  int chave = 0;
  for (int i = 0; i < vezes; i++) {
    chave = next(31);
  }
  printf("%d\n", chave);
  return 0;
}
