/* benchmark_clock.c - Mede o tempo de execução com clock() para os parâmetros
 * solicitados na planilha do professor:
 * T(10E9), T(8E9), T(6E9), T(2E9), T(1E9), T(5E8), T(2E8), T(1E8),
 * T(5E7), T(2E7), T(1E7), T(5E6), T(2E6), T(1E6)
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include "quicksort.h"
#include "radixsort.h"
#include "rng.h"
#include "utilarray.h"

typedef struct {
  const char *label;
  long long n;
} TestParam;

static TestParam params[] = {
    {"T(1E6)", 1000000LL},
    {"T(2E6)", 2000000LL},
    {"T(5E6)", 5000000LL},
    {"T(1E7)", 10000000LL},
    {"T(2E7)", 20000000LL},
    {"T(5E7)", 50000000LL},
    {"T(1E8)", 100000000LL},
    {"T(2E8)", 200000000LL},
    {"T(5E8)", 500000000LL},
    {"T(1E9)", 1000000000LL},
    {"T(2E9)", 2000000000LL},
    {"T(6E9)", 6000000000LL},
    {"T(8E9)", 8000000000LL},
    {"T(10E9)", 10000000000LL},
};

#define NUM_PARAMS (int)(sizeof(params) / sizeof(params[0]))

int main(int argc, char **argv) {
  long long seed_val = 18245598LL; // RA do aluno por padrão
  if (argc > 1) {
    seed_val = atoll(argv[1]);
  }

  // Limite máximo de teste para modo rápido (opcional via argumento)
  long long max_n = 10000000000LL;
  if (argc > 2) {
    max_n = atoll(argv[2]);
  }

  printf("======================================================================\n");
  printf("  Benchmark de Ordenacao com clock() - Quicksort vs Radix Sort\n");
  printf("  Semente base: %lld\n", seed_val);
  printf("======================================================================\n\n");

  double clock_qs[NUM_PARAMS];
  double clock_radix[NUM_PARAMS];
  int status_qs[NUM_PARAMS];    // 1 = ok, 0 = falha/timeout, -1 = sem memoria
  int status_radix[NUM_PARAMS]; // 1 = ok, 0 = falha/timeout, -1 = sem memoria

  for (int i = 0; i < NUM_PARAMS; i++) {
    long long n = params[i].n;
    printf("[%2d/%d] Testando %s (n = %lld elementos)...\n", i + 1, NUM_PARAMS,
           params[i].label, n);

    // Se ultrapassar o limite pedido no argumento
    if (n > max_n) {
      printf("  -> Pulado (acima do limite configurado de %lld)\n\n", max_n);
      clock_qs[i] = -1;
      clock_radix[i] = -1;
      status_qs[i] = -1;
      status_radix[i] = -1;
      continue;
    }

    // No Windows de 64 bits, long int e 32 bits (max ~2.14 bilhoes).
    // Alem disso, 6E9 inteiros = 24 GB de RAM (mais que os 16 GB do PC).
    if (n > 2147483647LL) {
      printf("  -> Sem memoria: n=%lld excede o limite de 32-bit/16GB RAM\n\n", n);
      clock_qs[i] = -1;
      clock_radix[i] = -1;
      status_qs[i] = -1;
      status_radix[i] = -1;
      continue;
    }

    // --- TESTE 1: QUICKSORT ---
    printf("  [Quicksort] Alocando %0.2f MB de RAM...", (double)(n * sizeof(int)) / (1024.0 * 1024.0));
    fflush(stdout);
    Array a_qs;
    a_qs.length = (long int)n;
    a_qs.A = (int *)malloc((size_t)n * sizeof(int));
    if (a_qs.A == NULL) {
      printf(" FALHA na alocacao (sem memoria suficiente)!\n");
      clock_qs[i] = -1;
      status_qs[i] = -1;
    } else {
      printf(" OK. Preenchendo array...");
      fflush(stdout);
      setSeed(seed_val + n);
      randArray(a_qs);

      printf(" Ordenando...");
      fflush(stdout);
      clock_t t0 = clock();
      quicksort(a_qs);
      clock_t t1 = clock();
      clock_qs[i] = (double)(t1 - t0) / CLOCKS_PER_SEC;

      long int r = crescente(a_qs);
      status_qs[i] = (r == a_qs.length) ? 1 : 0;
      printf(" Concluido em %0.6f s (clock)\n", clock_qs[i]);

      free(a_qs.A);
      a_qs.A = NULL;
    }

    // --- TESTE 2: RADIX SORT ---
    printf("  [Radix Sort] Alocando array...");
    fflush(stdout);
    Array a_radix;
    a_radix.length = (long int)n;
    a_radix.A = (int *)malloc((size_t)n * sizeof(int));
    if (a_radix.A == NULL) {
      printf(" FALHA na alocacao (sem memoria suficiente)!\n\n");
      clock_radix[i] = -1;
      status_radix[i] = -1;
    } else {
      printf(" OK. Preenchendo array com os MESMOS dados...");
      fflush(stdout);
      setSeed(seed_val + n);
      randArray(a_radix);

      printf(" Ordenando...");
      fflush(stdout);
      clock_t t0 = clock();
      radixsort(a_radix);
      clock_t t1 = clock();
      clock_radix[i] = (double)(t1 - t0) / CLOCKS_PER_SEC;

      long int r = crescente(a_radix);
      status_radix[i] = (r == a_radix.length) ? 1 : 0;
      printf(" Concluido em %0.6f s (clock)\n\n", clock_radix[i]);

      free(a_radix.A);
      a_radix.A = NULL;
    }
  }

  // --- TABELA RESUMO PARA A PLANILHA ---
  printf("\n======================================================================\n");
  printf("  TABELA FINAL - TEMPOS MEDIDOS COM clock() (em segundos)\n");
  printf("======================================================================\n\n");

  printf("Algoritmo\t");
  for (int i = NUM_PARAMS - 1; i >= 0; i--) {
    printf("%s\t", params[i].label);
  }
  printf("\n");

  // Linha do Quicksort
  printf("Quicksort\t");
  for (int i = NUM_PARAMS - 1; i >= 0; i--) {
    if (status_qs[i] == 1) {
      printf("%0.6f\t", clock_qs[i]);
    } else if (status_qs[i] == -1) {
      printf("Sem Mem\t");
    } else {
      printf("Falha\t");
    }
  }
  printf("\n");

  // Linha do Radix Sort
  printf("Radix Sort\t");
  for (int i = NUM_PARAMS - 1; i >= 0; i--) {
    if (status_radix[i] == 1) {
      printf("%0.6f\t", clock_radix[i]);
    } else if (status_radix[i] == -1) {
      printf("Sem Mem\t");
    } else {
      printf("Falha\t");
    }
  }
  printf("\n\n");

  // Salva em formato CSV formatado para colar na planilha
  FILE *f = fopen("tempos_planilha_clock.csv", "w");
  if (f != NULL) {
    fprintf(f, "Algoritmo");
    for (int i = NUM_PARAMS - 1; i >= 0; i--) {
      fprintf(f, ";%s", params[i].label);
    }
    fprintf(f, "\nQuicksort");
    for (int i = NUM_PARAMS - 1; i >= 0; i--) {
      if (status_qs[i] == 1) {
        fprintf(f, ";%0.6f", clock_qs[i]);
      } else {
        fprintf(f, ";Sem memoria");
      }
    }
    fprintf(f, "\nRadix Sort");
    for (int i = NUM_PARAMS - 1; i >= 0; i--) {
      if (status_radix[i] == 1) {
        fprintf(f, ";%0.6f", clock_radix[i]);
      } else {
        fprintf(f, ";Sem memoria");
      }
    }
    fprintf(f, "\n");
    fclose(f);
    printf("Resultados exportados para: tempos_planilha_clock.csv\n");
  }

  return 0;
}
