/* benchmark_gettimeofday.c - Mede o tempo de execução com gettimeofday()
 * para os parâmetros da planilha:
 * T(10E9), T(8E9), T(6E9), T(2E9), T(1E9), T(5E8), T(2E8), T(1E8),
 * T(5E7), T(2E7), T(1E7), T(5E6), T(2E6), T(1E6)
 *
 * Salva a saída formatada em tempos_planilha_gettimeofday.csv
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/time.h>
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

static double diff_timeval(struct timeval *t0, struct timeval *t1) {
  long seconds = t1->tv_sec - t0->tv_sec;
  long microseconds = t1->tv_usec - t0->tv_usec;
  return (double)seconds + (double)microseconds * 1.0e-6;
}

static void salvar_csv(double *wall_qs, double *wall_radix, int *status_qs, int *status_radix) {
  FILE *f = fopen("tempos_planilha_gettimeofday.csv", "w");
  if (f == NULL) return;

  fprintf(f, "Algoritmo");
  for (int i = NUM_PARAMS - 1; i >= 0; i--) {
    fprintf(f, ";%s", params[i].label);
  }
  fprintf(f, "\nQuicksort");
  for (int i = NUM_PARAMS - 1; i >= 0; i--) {
    if (status_qs[i] == 1) {
      fprintf(f, ";%0.6f", wall_qs[i]);
    } else if (status_qs[i] == 0) {
      fprintf(f, ";Falha");
    } else {
      fprintf(f, ";Sem memoria");
    }
  }
  fprintf(f, "\nRadix Sort");
  for (int i = NUM_PARAMS - 1; i >= 0; i--) {
    if (status_radix[i] == 1) {
      fprintf(f, ";%0.6f", wall_radix[i]);
    } else if (status_radix[i] == 0) {
      fprintf(f, ";Falha");
    } else {
      fprintf(f, ";Sem memoria");
    }
  }
  fprintf(f, "\n");
  fclose(f);
}

int main(int argc, char **argv) {
  long long seed_val = 18245598LL; // RA do aluno por padrão
  if (argc > 1) {
    seed_val = atoll(argv[1]);
  }

  // Limite máximo de teste (padrão: 2 bilhoes)
  long long max_n = 2000000000LL;
  if (argc > 2) {
    max_n = atoll(argv[2]);
  }

  printf("======================================================================\n");
  printf("  Benchmark de Ordenacao com gettimeofday() - Quicksort vs Radix Sort\n");
  printf("  Semente base: %lld | Limite max_n: %lld\n", seed_val, max_n);
  printf("======================================================================\n\n");

  double wall_qs[NUM_PARAMS];
  double wall_radix[NUM_PARAMS];
  int status_qs[NUM_PARAMS];    // 1 = ok, 0 = falha/timeout, -1 = sem memoria
  int status_radix[NUM_PARAMS]; // 1 = ok, 0 = falha/timeout, -1 = sem memoria

  for (int i = 0; i < NUM_PARAMS; i++) {
    wall_qs[i] = -1.0;
    wall_radix[i] = -1.0;
    status_qs[i] = -1;
    status_radix[i] = -1;
  }

  for (int i = 0; i < NUM_PARAMS; i++) {
    long long n = params[i].n;
    printf("[%2d/%d] Testando %s (n = %lld elementos)...\n", i + 1, NUM_PARAMS,
           params[i].label, n);

    if (n > max_n) {
      printf("  -> Pulado (acima do limite configurado de %lld)\n\n", max_n);
      continue;
    }

    // No Windows, long int e 32 bits (max 2.14 bilhoes).
    // Alem disso, 6E9 exige 24 GB / 48 GB de RAM (mais que os 16 GB do computador).
    if (n > 2147483647LL) {
      printf("  -> Sem memoria: n=%lld excede o limite fisico da maquina (16GB RAM) e 32-bit\n\n", n);
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
      status_qs[i] = -1;
    } else {
      printf(" OK. Preenchendo array...");
      fflush(stdout);
      setSeed(seed_val + n);
      randArray(a_qs);

      printf(" Ordenando...");
      fflush(stdout);
      struct timeval t0, t1;
      gettimeofday(&t0, NULL);
      quicksort(a_qs);
      gettimeofday(&t1, NULL);
      wall_qs[i] = diff_timeval(&t0, &t1);

      long int r = crescente(a_qs);
      status_qs[i] = (r == a_qs.length) ? 1 : 0;
      printf(" Concluido em %0.6f s (gettimeofday)\n", wall_qs[i]);

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
      status_radix[i] = -1;
    } else {
      printf(" OK. Preenchendo array com os MESMOS dados...");
      fflush(stdout);
      setSeed(seed_val + n);
      randArray(a_radix);

      printf(" Ordenando...");
      fflush(stdout);
      struct timeval t0, t1;
      gettimeofday(&t0, NULL);
      radixsort(a_radix);
      gettimeofday(&t1, NULL);
      wall_radix[i] = diff_timeval(&t0, &t1);

      long int r = crescente(a_radix);
      status_radix[i] = (r == a_radix.length) ? 1 : 0;
      printf(" Concluido em %0.6f s (gettimeofday)\n\n", wall_radix[i]);

      free(a_radix.A);
      a_radix.A = NULL;
    }

    // Salva o CSV incrementalmente a cada tamanho concluído
    salvar_csv(wall_qs, wall_radix, status_qs, status_radix);
  }

  // --- TABELA RESUMO FINAL NA TELA ---
  printf("\n======================================================================\n");
  printf("  TABELA FINAL - TEMPOS MEDIDOS COM gettimeofday() (em segundos)\n");
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
      printf("%0.6f\t", wall_qs[i]);
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
      printf("%0.6f\t", wall_radix[i]);
    } else if (status_radix[i] == -1) {
      printf("Sem Mem\t");
    } else {
      printf("Falha\t");
    }
  }
  printf("\n\n");

  salvar_csv(wall_qs, wall_radix, status_qs, status_radix);
  printf("Resultados gravados com sucesso em: tempos_planilha_gettimeofday.csv\n");

  return 0;
}
