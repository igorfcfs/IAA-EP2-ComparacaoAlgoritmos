# Guia Rápido de Comandos - EP2 (IAA)

Todos os comandos abaixo devem ser executados no terminal PowerShell dentro da pasta `src/`.

---

## 1. Compilação dos Programas

Crie a pasta de saída (se ainda não existir) e compile os executáveis:

```powershell
# Cria a pasta output
if (-not (Test-Path output)) { New-Item -ItemType Directory output }

# 1. Gerador de entradas
gcc -O2 rng.c utilarray.c gen_input.c -o output\gen_input.exe

# 2. Executor e medidor dos algoritmos (Quicksort e Radix Sort)
gcc -O2 rng.c utilarray.c elapsedRunningTime.c quicksort.c radixsort.c run_sort.c -o output\run_sort.exe

# 3. Gerador da chave secreta
gcc -O2 rng.c secretkey_gen.c -o output\secretkey_gen.exe

# 4. Testes rápidos embutidos (standalone)
gcc -O2 -D TEST_RADIXSORT rng.c utilarray.c radixsort.c -o output\test_radix.exe
gcc -O2 -D TEST_QUICKSORT rng.c utilarray.c quicksort.c -o output\test_qs.exe
```

---

## 2. Gerar a Chave Secreta (Questão 1)

Gera a chave usando seu RA (`18245598`) e `31` repetições:

```powershell
.\output\secretkey_gen.exe 18245598 31
```
> **Saída esperada:** `1906028835`

---

## 3. Testes Rápidos Individuais (1.000.000 de elementos)

Testa diretamente se os algoritmos estão ordenando sem erros:

```powershell
# Testa Radix Sort
.\output\test_radix.exe

# Testa Quicksort
.\output\test_qs.exe
```
> **Saída esperada:** `ordenado corretamente: SIM (crescente() retornou 1000000, length=1000000)`

---

## 4. Teste Manual com Medição de Tempo

Fluxo completo para testar e comparar qualquer tamanho:

### Passo A: Gerar arquivo de entrada
```powershell
# Sintaxe: .\output\gen_input.exe <n> <semente> <arquivo>
# Exemplo com 10 milhões (10000000) e semente 42:
.\output\gen_input.exe 10000000 42 entrada.bin
```

### Passo B: Medir o Radix Sort
```powershell
.\output\run_sort.exe radix entrada.bin
```

### Passo C: Medir o Quicksort (na mesma entrada)
```powershell
.\output\run_sort.exe qs entrada.bin
```

### Passo D: Apagar arquivo temporário
```powershell
Remove-Item entrada.bin
```

> **Formato da saída:** `algoritmo;n;tempo_clock_s;tempo_wall_s;ok_ordenado`  
> Exemplo: `radix;10000000;0.082000;0.081540;1` (`1` no final = ordenação correta).

---

## 5. Tabela de Tamanhos Oficiais do EP2

| Notação | Valor numérico de `n` | Tempo aprox. Radix | Tempo aprox. Quicksort |
| :--- | :--- | :--- | :--- |
| **100 mil** | `100000` | ~0.0006s | ~0.005s |
| **1 milhão** | `1000000` | ~0.008s | ~0.06s |
| **10 milhões** | `10000000` | ~0.08s | ~0.8s |
| **100 milhões** | `100000000` | ~2.5s | ~12.0s |
| **200 milhões** | `200000000` | ~5.5s | ~27.0s |

> ⚠️ **Atenção aos zeros:**  
> * 100 milhões = `100000000` (8 zeros).  
> * Não use 100 bilhões (`100000000000`), pois exigiria 400 GB de RAM!

---

## 6. Rodar Todos os Testes Automaticamente (Script)

Para rodar todas as repetições e gerar a planilha `raw_results.csv`:

```powershell
# Teste rápido (tamanhos de 1 mil a 1 milhão, ~5 segundos):
.\bench.ps1 -Quick

# Bateria completa oficial do EP (todos os tamanhos até 200 milhões):
.\bench.ps1
```

---

## 7. Gerar Tabela Oficial da Planilha com `clock()`

Para rodar exatamente os parâmetros da planilha do professor:
`T(10E9)`, `T(8E9)`, `T(6E9)`, `T(2E9)`, `T(1E9)`, `T(5E8)`, `T(2E8)`, `T(1E8)`, `T(5E7)`, `T(2E7)`, `T(1E7)`, `T(5E6)`, `T(2E6)`, `T(1E6)`

```powershell
# Compila o medidor em memória:
gcc -O2 rng.c utilarray.c quicksort.c radixsort.c benchmark_clock.c -o output\benchmark_clock.exe

# Executa e gera 'tempos_planilha_clock.csv':
.\output\benchmark_clock.exe 18245598
```
> O arquivo [tempos_planilha_clock.csv](file:///g:/Meu%20Drive/Academico/02.%20USP%20-%20Sistemas%20de%20Informa%C3%A7%C3%A3o/2%C2%BA%20Semestre/Introdu%C3%A7%C3%A3o%20e%20An%C3%A1lise%20de%20Algoritmos/EP/EP2/src/tempos_planilha_clock.csv) é gerado com as linhas prontas para copiar e colar na planilha compartilhada do professor.

---

## 8. Gerar Tabela Oficial da Planilha com `gettimeofday()`

Para rodar exatamente os parâmetros da planilha medindo tempo de relógio de parede (*wall time*) com `gettimeofday()`:

```powershell
# Compila o medidor:
gcc -O2 rng.c utilarray.c quicksort.c radixsort.c benchmark_gettimeofday.c -o output\benchmark_gettimeofday.exe

# Executa e gera 'tempos_planilha_gettimeofday.csv':
.\output\benchmark_gettimeofday.exe 18245598
```
> O arquivo [tempos_planilha_gettimeofday.csv](file:///g:/Meu%20Drive/Academico/02.%20USP%20-%20Sistemas%20de%20Informa%C3%A7%C3%A3o/2%C2%BA%20Semestre/Introdu%C3%A7%C3%A3o%20e%20An%C3%A1lise%20de%20Algoritmos/EP/EP2/src/tempos_planilha_gettimeofday.csv) é gerado automaticamente com os tempos de `gettimeofday()`.


