#ifndef _UTILARRAY_H_
#define _UTILARRAY_H_
#include <stdio.h>
#include <stdlib.h>
#include "rng.h"

typedef struct {
  int *A;
  long int length;
} Array;

Array alocaArray (long int length);
void printArray (Array a);
Array dealocaArray (Array a);
long int crescente (Array a);
void randArray (Array a);
Array testaAlocar (char verboso);

#endif
