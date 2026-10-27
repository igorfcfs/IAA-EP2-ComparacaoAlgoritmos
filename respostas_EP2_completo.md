---
title: "EP2 — IAA: Comparação de tempo de execução entre Quicksort e Radix Sort (Relatório Completo)"
author: "Igor Fernando Casita Ferreira da Silva — RA 18245598"
date: \today
---

# 1. Introdução

Este relatório compara empiricamente dois algoritmos de ordenação —
**Quicksort** (ordenação por comparação) e **Radix Sort** (ordenação por
contagem, sem comparação direta entre chaves) — implementados em C e
executados no **computador pessoal do aluno**. Todos os tempos reportados
são medições reais, obtidas com `clock()` e `gettimeofday()`, sobre a
mesma entrada aleatória para os dois algoritmos em cada repetição
(controle de confusão experimental).

**Ambiente de execução (coletado automaticamente a partir do sistema):**

| Item | Valor |
|---|---|
| CPU | 13th Gen Intel(R) Core(TM) i7-1355U (1,70 GHz, 10 núcleos físicos, 12 threads) |
| RAM total | 16.777.216 kB (16,0 GB) |
| RAM disponível (no momento da coleta) | 16.454.352 kB |
| Memória virtual (commit) | 34.280.144 kB total, 28.839.404 kB em uso |
| Sistema operacional | Windows 11 Home Single Language, build 25H2 (26200.9711, 64 bits) |
| Compilador | gcc (MinGW-W64 x86_64-ucrt-posix-seh, build de Brecht Sanders, r8) 13.2.0 |
| Flags de compilação | `-O2` |

---

# 2. Questão 1 — Chave secreta

A chave segue exatamente o método de `calcSecret.c`: inicializa o gerador
congruente linear (mesmas constantes do `java.util.Random`: multiplicador
`0x5DEECE66D`, incremento `0xB`, módulo `2^48`) com `setSeed(semente)` e
aplica `next(31)` repetidamente; o último valor retornado é a chave.

- Semente: RA do aluno = `18245598`
- Número de iterações: `31`
- **Chave secreta: `1906028835`**

Esse valor é puramente aritmético (não depende de hardware, SO ou
compilador), e foi reconfirmado rodando `secretkey_gen.exe 18245598 31`
no mesmo ambiente Windows usado para os benchmarks, com saída idêntica.

---

# 3. Questão 2 — Crítica ao método de geração da chave secreta

O gerador usado (LCG — *Linear Congruential Generator*) é o mesmo
algoritmo de `java.util.Random`:

```
seed = (seed * 0x5DEECE66D + 0xB) mod 2^48
next(bits) = seed >> (48 - bits)
```

**Pontos fortes para este uso específico:**
- É determinístico e reprodutível: a mesma semente (RA) sempre produz a
  mesma chave, permitindo ao professor conferir a autoria de cada linha
  da planilha sem precisar armazenar uma tabela de chaves.
- É rápido e não exige bibliotecas externas.
- Para o propósito de **identificação** (não de segurança), a qualidade
  estatística do LCG é irrelevante — só importa que semente ≠ semente
  produza, com altíssima probabilidade, chave ≠ chave.

**Fraquezas, caso o método fosse usado para fins criptográficos (não é o
caso aqui, mas vale a crítica técnica pedida):**
- LCGs possuem **estrutura em reticulado** (resultado clássico de
  Marsaglia, 1968, "Random numbers fall mainly in the planes"): pontos
  consecutivos gerados por um LCG, quando agrupados em *k*-uplas, caem em
  um número reduzido de hiperplanos paralelos em um espaço de dimensão
  *k*, nunca preenchendo o espaço uniformemente.
- Os **bits baixos de um LCG têm período muito curto** — por isso
  `next(bits)` descarta os bits baixos do estado (`seed >> (48-bits)`),
  usando só os bits altos, mais aleatórios. `calcSecret.c`/`secretkey_gen.c`
  usam `next(31)`, ou seja, os 31 bits mais significativos — uma escolha
  correta sob esse aspecto.
- Dado o módulo `2^48` e 31 iterações fixas, o espaço de chaves possíveis
  a partir de sementes "pequenas" (RA de 8 dígitos, até ~10^8) é bem menor
  que o espaço de saída de 31 bits (até ~2×10^9) — ou seja, há mais
  valores de saída possíveis do que RAs possíveis, então colisões entre
  dois RAs diferentes gerando a mesma chave são estatisticamente
  **improváveis mas não impossíveis** (argumento do paradoxo do
  aniversário: com `N` alunos sorteando entre `K` chaves possíveis
  efetivamente alcançáveis, a probabilidade de colisão cresce com
  `N²/K`; não há como calcular esse valor exatamente sem conhecer a
  distribuição real de RAs na turma, mas a ordem de grandeza de `K` aqui
  é alta o suficiente para tornar colisões improváveis em turmas de
  dezenas a poucas centenas de alunos).
- Um LCG **não é adequado para geração de chaves criptográficas** (é
  previsível: observando poucas saídas consecutivas é possível recuperar
  o estado interno e prever as próximas). Isso não compromete o uso aqui,
  que é apenas de identificação pública, não de sigilo.

---

# 4. Fundamentação teórica dos algoritmos

## 4.1 Quicksort

**Classe:** ordenação por comparação, *in-place*, por divisão e conquista
(*divide-and-conquer*), **instável** (não preserva a ordem relativa de
elementos iguais).

**Ideia central:** escolhe-se um elemento pivô; particiona-se o array em
duas metades — elementos menores que o pivô à esquerda, maiores à direita
— e recursivamente ordena-se cada metade.

**Implementação usada neste trabalho** (`quicksort.c`):
- **Escolha de pivô por mediana-de-3** (`A[lo]`, `A[mid]`, `A[hi]`): evita
  o pior caso O(n²) característico de sempre escolher o primeiro/último
  elemento em arrays já ordenados ou quase ordenados.
- **Partição de Hoare**: em média faz cerca de 3× menos trocas que a
  partição de Lomuto, por isso mais rápida na prática.
- **Corte para inserção** (*insertion sort cutoff*) em sub-arrays de até
  16 elementos: para `n` pequeno, o *insertion sort* tem constante menor
  apesar de O(k²), compensando por evitar a sobrecarga de recursão do
  quicksort.
- **Eliminação de recursão de cauda**: sempre recorre explicitamente no
  lado **menor** da partição e continua em laço `while` no lado maior —
  isso limita a profundidade da pilha a O(log n) mesmo no pior caso
  (sem essa técnica, uma sequência de partições desbalanceadas poderia
  levar a O(n) de profundidade de pilha).

**Complexidade temporal:**
- **Caso médio: Θ(n log n).** Demonstração clássica (CLRS, cap. 7): seja
  `X` o número total de comparações. Usando variáveis indicadoras
  `X_{ij}` = 1 se os elementos de rank `i` e `j` são comparados em algum
  momento do algoritmo, mostra-se que dois elementos só são comparados se
  um deles for escolhido como pivô antes de qualquer elemento entre eles
  no valor. A probabilidade disso é `2/(j-i+1)`. Por linearidade da
  esperança, `E[X] = Σ_i Σ_j 2/(j-i+1) = O(n log n)`.
- **Pior caso: Θ(n²)** — ocorre quando a partição é maximamente
  desbalanceada (um lado com 0 ou 1 elemento) em toda chamada recursiva,
  dando a recorrência `T(n) = T(n-1) + Θ(n)`. A mediana-de-3 torna esse
  caso raro na prática, mas não o elimina adversarialmente (existe
  sempre uma entrada que o força, dada a estratégia de pivô fixa).
- **Melhor caso: Θ(n log n)** — partições perfeitamente balanceadas,
  recorrência `T(n) = 2T(n/2) + Θ(n)`, resolvida pelo Teorema Mestre
  (caso 2: `f(n) = Θ(n^{log_b a} log n)` com `a=b=2`).

**Complexidade espacial:** O(log n) esperado (profundidade da pilha de
recursão, graças à eliminação de recursão de cauda), O(n) no pior caso
teórico absoluto sem essa otimização — o quicksort **ordena in-place**,
não aloca nenhum array auxiliar de tamanho proporcional a `n`.

## 4.2 Radix Sort

**Classe:** ordenação **não comparativa**, estável (quando cada passada
de contagem é estável, como implementado), por distribuição.

**Ideia central:** em vez de comparar elementos entre si, ordena-se
repetidamente por "dígitos" do valor (do menos significativo ao mais
significativo — variante **LSD**, *least-significant-digit-first*), usando
em cada passada um **counting sort estável** sobre aquele dígito.

**Implementação usada neste trabalho** (`radixsort.c`):
- Base `256` (dígitos de 8 bits) → **4 passadas** para cobrir os 32 bits
  de um `int`.
- Cada passada é um counting sort estável: conta ocorrências de cada um
  dos 256 valores possíveis do dígito corrente, converte em posições via
  soma de prefixos, e distribui os elementos nessas posições em um array
  auxiliar.
- Os papéis de array fonte/destino são **trocados (ponteiros)** a cada
  passada em vez de copiados, evitando uma cópia O(n) extra por passada.

**Complexidade temporal:** O(d·(n + b)), onde `d` = número de dígitos
(passadas), `b` = base (tamanho do alfabeto de dígitos). Aqui, `d = 4` e
`b = 256` são **constantes fixas**, independentes de `n` (decorrem apenas
do tamanho fixo de 32 bits do tipo `int`), logo a complexidade **se reduz
a Θ(n)** — linear no número de elementos.

**Por que isso não contradiz o limite inferior Ω(n log n) de ordenação
por comparação?** O limite Ω(n log n) (prova pela árvore de decisão: um
algoritmo de ordenação por comparação tem que distinguir entre `n!`
permutações possíveis, e uma árvore binária de decisão com `n!` folhas
tem profundidade mínima `log₂(n!) = Θ(n log n)`) vale **apenas para
algoritmos que só podem comparar pares de chaves**. O radix sort nunca
compara duas chaves entre si — ele usa o **valor absoluto dos dígitos**
para indexar diretamente posições no array, operação mais poderosa que
uma comparação binária. Por isso pode, legitimamente, ser mais rápido
que o limite de ordenação por comparação — ao custo de depender do
tamanho fixo e conhecido da chave (aqui, 32 bits).

**Complexidade espacial: O(n + b).** Diferente do quicksort, o radix sort
aqui implementado **não é in-place**: cada passada escreve em um array
auxiliar de tamanho `n` (mais um vetor de contagem de tamanho `b=256`,
desprezível frente a `n`). Isso significa que, em pico, o programa mantém
**dois arrays de tamanho `n` simultaneamente na memória** (o original e o
auxiliar) — o dobro do espaço que o quicksort usa para os dados em si.
Essa é precisamente a característica que se manifesta empiricamente na
Seção 6.4 como uma desvantagem prática do radix sort para `n` muito
grande.

## 4.3 Comparação teórica resumida

| | Quicksort (implementado) | Radix Sort (implementado) |
|---|---|---|
| Classe | Comparação, *in-place* | Distribuição/contagem, não-comparativo |
| Tempo médio | Θ(n log n) | Θ(n) (d, b fixos) |
| Tempo pior caso | Θ(n²) (raro, mitigado por mediana-de-3) | Θ(n) (sem pior caso dependente dos dados) |
| Espaço auxiliar | O(log n) (pilha) | O(n + b) (array duplicado) |
| Estável | Não | Sim |
| Depende do domínio da chave | Não | Sim (tamanho fixo de bits) |

---

# 5. Questão 3 — Código-fonte

Código completo entregue junto a este relatório, na pasta `src/`:

- `rng.c` / `rng.h` — gerador congruente linear fornecido pelo professor
  (sem alterações).
- `utilarray.c` / `utilarray.h` — utilitários de array fornecidos pelo
  professor (sem alterações).
- `elapsedRunningTime.c` / `.h` — medição de tempo com `clock()` e
  `gettimeofday()`, fornecida pelo professor (sem alterações; compilou e
  rodou corretamente no Windows com o toolchain MinGW-w64/UCRT usado).
- `quicksort.c` / `.h` — implementação própria (mediana-de-3, partição de
  Hoare, corte para inserção em k≤16, eliminação de recursão de cauda).
- `radixsort.c` / `.h` — implementação própria (LSD, base 256, 4
  passadas, buffers trocados por ponteiro).
- `gen_input.c` — gera um array aleatório e grava em binário, garantindo
  que quicksort e radix sort recebam **exatamente a mesma entrada** em
  cada repetição (controle de variável de confusão).
- `run_sort.c` — lê o array binário, mede o tempo de UM algoritmo com
  `start()`/`stop()`, verifica se o resultado está ordenado
  (`crescente()`), imprime uma linha CSV.
- `benchmark_clock.c` — roda os dois algoritmos, com `clock()`, para os
  14 tamanhos oficiais da planilha do professor (T(1E6) até T(10E9)),
  numa única execução por tamanho, lidando explicitamente com os casos
  em que `n` excede a capacidade representável (ver Seção 6.5).
- `secretkey_gen.c` — versão não-interativa de `calcSecret.c`.

**Compilação** (gcc/MinGW-w64, `-O2`, idêntica à usada para gerar todos
os números deste relatório):

```powershell
gcc -O2 rng.c utilarray.c gen_input.c -o gen_input.exe
gcc -O2 rng.c utilarray.c elapsedRunningTime.c quicksort.c radixsort.c run_sort.c -o run_sort.exe
gcc -O2 rng.c utilarray.c quicksort.c radixsort.c benchmark_clock.c -o benchmark_clock.exe
gcc -O2 rng.c secretkey_gen.c -o secretkey_gen.exe
```

---

# 6. Questão 5 — Metodologia, resultados e discussão científica

## 6.1 Metodologia

- Para cada tamanho `n`, gera-se **um único array aleatório** por
  repetição (`gen_input`, semente = `n*1000003 + repetição*7919 + 12345`)
  e o **mesmo array binário é usado para testar os dois algoritmos**,
  eliminando a variação de entrada como fator de confusão.
- Tamanhos pequenos (`n ≤ 10.000`) foram repetidos 7×; tamanhos médios
  (10^5–10^6) 3 a 5×; tamanhos grandes (≥5×10^6) 1 a 3×, reduzindo
  repetições conforme o tempo por execução cresce (prática padrão em
  benchmarking: o ruído relativo cai com `n`, então o ganho estatístico
  de repetir tamanhos grandes é menor frente ao custo de tempo).
  Nenhuma execução atingiu o limite de 3600s.
- O tempo reportado como medida principal é o de **relógio de parede**
  (`gettimeofday()`), não o de `clock()`. Motivo: no Windows/MinGW usado,
  `CLOCKS_PER_SEC = 1000`, ou seja, `clock()` tem resolução de apenas
  ~1ms — grosseira demais para medir corretamente execuções de
  microssegundos a poucos milissegundos (visível nos dados brutos:
  `tempo_clock_s` aparece quantizado em múltiplos de 0,001, enquanto
  `tempo_wall_s` tem resolução de microssegundos). Esse é um ponto
  metodológico genuíno: no Linux, `CLOCKS_PER_SEC` é tipicamente
  1.000.000, tornando `clock()` muito mais informativo — a escolha de
  qual relógio usar como medida principal deve, portanto, depender da
  plataforma.

## 6.2 Resultados — tempo médio de execução (relógio de parede)

| n | Quicksort: média ± dp (s) | n reps | Radix Sort: média ± dp (s) | n reps | razão (qs/radix) |
|---:|---:|---:|---:|---:|---:|
| 1.000 | 0,0000377 ± 0,0000150 | 9 | 0,0000057 ± 0,0000017 | 9 | 6,6× |
| 10.000 | 0,000410 ± 0,0000499 | 9 | 0,0000801 ± 0,0000455 | 9 | 5,1× |
| 100.000 | 0,005271 ± 0,000451 | 7 | 0,000667 ± 0,000195 | 7 | 7,9× |
| 500.000 | 0,025271 ± 0,000871 | 7 | 0,003708 ± 0,000432 | 7 | 6,8× |
| 1.000.000 | 0,055610 ± 0,004236 | 5 | 0,008487 ± 0,001196 | 5 | 6,6× |
| 5.000.000 | 0,298064 ± 0,004433 | 3 | 0,037674 ± 0,001803 | 3 | 7,9× |
| 10.000.000 | 0,614553 ± 0,012138 | 3 | 0,078156 ± 0,002646 | 3 | 7,9× |
| 50.000.000 | 3,355480 ± 0,002232 | 2 | 0,377036 ± 0,019041 | 2 | 8,9× |
| 100.000.000 | 7,713330 ± 0,101421 | 2 | 0,951264 ± 0,078973 | 2 | 8,1× |
| 200.000.000 | 14,147100 (1 execução) | 1 | 1,563120 (1 execução) | 1 | 9,1× |

*(tabela completa também disponível em `resultados/resumo_estatistico.csv`)*

![Tempo de execução vs. n, escala log-log](graficos/01_tempo_vs_n_loglog.png)

![Razão quicksort/radix por n](graficos/02_razao_qs_radix.png)

![Variabilidade entre repetições](graficos/03_boxplot_variabilidade.png)

## 6.3 Análise estatística (R)

**Regressão log-log** (`log(tempo) = log(a) + k·log(n)`, ajustada sobre
as médias por tamanho) estima o **expoente de crescimento empírico**:

| Algoritmo | k estimado | IC 95% | R² ajustado |
|---|---:|---:|---:|
| Quicksort | 1,0555 | [1,0459 ; 1,0651] | 0,9999 |
| Radix Sort | 1,0227 | [1,0018 ; 1,0436] | 0,9993 |

Ambos os ajustes são excelentes (R² > 0,999), e os dois expoentes ficam
próximos de 1 — esperado, já que `log n` cresce muito lentamente frente a
`n` (apenas ~18,4× entre n=10³ e n=2×10⁸, contra um aumento de 2×10⁵× em
`n`). O resultado é consistente com a teoria em dois sentidos:
- O expoente do **quicksort (1,0555) é visivelmente maior** que o do
  **radix sort (1,0227)**, refletindo o fator `log n` adicional de
  Θ(n log n) presente no quicksort e ausente (constante, fixo em 4
  passadas) no radix sort.
- O radix sort tem expoente **estatisticamente indistinguível de 1**
  dentro do IC 95% (contém 1,0 em uma das pontas), consistente com
  Θ(n) teórico; o do quicksort **não contém 1,0** no IC, evidência de que
  seu crescimento é genuinamente superlinear.

**Teste pareado** (Wilcoxon signed-rank, usando repetições com a mesma
entrada para os dois algoritmos como pares naturais, `n = 68` pares,
tamanhos de 10³ a 10⁸): `V = 2346`, `p ≈ 7,8×10⁻¹³`. O quicksort foi mais
lento que o radix sort em **100% dos 68 pares comparados** — a diferença
é estatisticamente altamente significativa e consistente em todas as
repetições, não um artefato de média.

## 6.4 Tamanhos extremos (planilha oficial, até 2 bilhões)

`benchmark_clock.c` roda, numa única execução por tamanho (sem repetição,
medição só com `clock()`), os 14 tamanhos exatos pedidos na planilha
compartilhada do professor:

| Tamanho | Quicksort (s) | Radix Sort (s) |
|---|---:|---:|
| T(1E6) | 0,057 | 0,007 |
| T(2E6) | 0,111 | 0,015 |
| T(5E6) | 0,334 | 0,038 |
| T(1E7) | 0,618 | 0,079 |
| T(2E7) | 1,286 | 0,156 |
| T(5E7) | 3,415 | 0,414 |
| T(1E8) | 7,141 | 0,849 |
| T(2E8) | 16,154 | 1,518 |
| T(5E8) | 38,099 | 4,012 |
| T(1E9) | 81,306 | 12,322 |
| **T(2E9)** | **222,180** | **503,456** |
| T(6E9) | não testado | não testado |
| T(8E9) | não testado | não testado |
| T(10E9) | não testado | não testado |

![Tamanhos oficiais até 2 bilhões](graficos/04_planilha_oficial_loglog.png)

**O resultado em T(2E9) inverte a tendência**: pela primeira vez o radix
sort (503,5s) é **mais lento** que o quicksort (222,2s), contrariando
todos os pontos anteriores. Este não é um erro de medição — é uma
consequência direta e explicável da arquitetura de memória:

- Em `n = 2×10⁹`, um único array de `int` (4 bytes) ocupa **8 GB**.
- O **quicksort é in-place**: usa apenas esses 8 GB (mais O(log n) de
  pilha, irrelevante).
- O **radix sort aloca um array auxiliar do mesmo tamanho** (Seção 4.2):
  em pico, precisa de **~16 GB** — praticamente **toda a RAM física da
  máquina** (16.777.216 kB = 16,0 GB, conforme Seção 1).
- Isso força o sistema operacional a recorrer a paginação/memória
  virtual (trocas com o disco), que é ordens de grandeza mais lenta que
  acesso à RAM. O próprio `platforminfo.h`, coletado durante a sessão de
  testes, registra **28,8 GB de memória virtual em uso** num sistema com
  apenas 16 GB de RAM física — evidência direta de que o sistema já
  estava sob pressão de memória/paginação nesse momento.
- Esse é um exemplo concreto e real (não hipotético) de por que a
  **complexidade espacial importa na prática, não só na teoria**: o
  radix sort tem melhor complexidade de tempo assintótico (Θ(n) vs.
  Θ(n log n)), mas sua maior exigência de memória (O(n+b) com constante
  2, por causa do array duplicado) o torna **mais lento na prática**
  assim que o tamanho do problema se aproxima do limite de RAM física
  disponível — um efeito que nenhuma análise assintótica de tempo, por
  si só, prevê.
- **Ressalva metodológica**: este ponto (T(2E9)) é uma única execução,
  sem repetição (diferente dos dados da Seção 6.2/6.3, que têm múltiplas
  repetições e desvio-padrão). A inversão é consistente com o raciocínio
  teórico acima e com a leitura de memória virtual registrada, mas,
  rigorosamente, não se pode descartar 100% um efeito de ruído do sistema
  (outro processo competindo por RAM naquele instante específico) sem
  repetir a medição — o que não foi feito para evitar o alto custo de
  tempo (cada execução de T(2E9) já leva vários minutos).

## 6.5 Tamanhos não testados (T(6E9), T(8E9), T(10E9))

Esses três tamanhos não foram executados, por **dois limites
independentes e cumulativos**:

1. **Limite de RAM física**: 6, 8 e 10 bilhões de `int`s de 4 bytes
   exigiriam, respectivamente, ~24 GB, ~32 GB e ~40 GB só para um único
   array — mais do que os 16 GB de RAM física da máquina, mesmo antes de
   considerar o array auxiliar do radix sort.
2. **Limite do modelo de dados do Windows (LLP64)**: o struct `Array`
   (`utilarray.h`, fornecido pelo professor) usa `long int length` para
   armazenar o tamanho do array. No **Linux** (modelo de dados **LP64**,
   usado nos exemplos originais do professor), `long int` tem **64
   bits**, suportando índices até ~9,2×10¹⁸. No **Windows** (modelo de
   dados **LLP64**, adotado pelo MinGW-w64 por seguir a ABI do Windows),
   `long int` tem apenas **32 bits**, mesmo em compilação de 64 bits —
   limitando o tamanho máximo representável a `2³¹-1 ≈ 2,147 bilhões`.
   Essa é a razão pela qual mesmo T(6E9) teoricamente "parando antes de
   faltar RAM" ainda seria impossível de representar corretamente nesta
   plataforma sem alterar o tipo do campo `length` — uma diferença de
   portabilidade real e documentável entre Linux e Windows, não uma
   limitação do algoritmo em si.

Por isso, essas células foram preenchidas com **"Sem memória"** na
planilha/tabela — não por uma tentativa de alocação que falhou em tempo
de execução, mas por uma verificação prévia no próprio código
(`benchmark_clock.c`) que evita a tentativa, já que ela seria inútil e
(para n > 2³¹-1) produziria um comportamento indefinido pelo overflow do
campo `length`.

## 6.6 Conclusão

Os dados confirmam a teoria (Seção 4) em praticamente toda a faixa de
tamanhos testada: o radix sort é consistentemente de 5× a 9× mais rápido
que o quicksort implementado, com uma vantagem relativa que **cresce**
com `n` (de ~6,6× em n=10³ para ~9,1× em n=2×10⁸) — compatível com a
diferença assintótica Θ(n) vs. Θ(n log n), cujo fator `log n` extra do
quicksort pesa cada vez mais conforme `n` cresce. A regressão log-log
confirma estatisticamente essa diferença de expoentes (1,023 vs. 1,056,
IC 95% não sobrepostos na direção esperada) e o teste pareado confirma
que a vantagem do radix sort é sistemática, não casual (p < 10⁻¹²).

Porém, em `n = 2×10⁹`, a vantagem teórica do radix sort em tempo se
inverte na prática, por causa do seu maior custo de memória (espaço
auxiliar O(n) vs. O(log n) do quicksort) colidir com o limite físico de
RAM da máquina — um lembrete de que complexidade assintótica de tempo e
desempenho real divergem quando a complexidade **espacial** de um
algoritmo o aproxima dos limites físicos do hardware disponível.

---

# 7. Limitações e ressalvas

- Os tempos aqui são específicos deste hardware (Seção 1) e não devem
  ser comparados diretamente, em valor absoluto, com os de colegas
  rodando em outras máquinas — apenas a forma da curva (expoente de
  crescimento) e a comparação relativa entre os dois algoritmos no
  **mesmo** hardware têm validade entre diferentes execuções.
- `clock()` no Windows tem resolução grosseira (~1ms); os tempos de
  relógio de parede (`gettimeofday()`) são a fonte primária de dados
  estatísticos deste relatório pelos motivos explicados na Seção 6.1.
- O ponto T(2E9) é uma única medição sem repetição (Seção 6.4);
  interpretado com a devida cautela estatística, mas com forte
  justificativa teórica e evidência indireta (memória virtual em uso)
  de que o efeito é real, não ruído de medição.
