# bench.ps1 - Executa os benchmarks de quicksort e radix sort para vários tamanhos de entrada
# Gera raw_results.csv com os dados de tempo e ordenação.

param(
    [switch]$Quick,                 # Roda apenas tamanhos menores (até 1.000.000) para verificação rápida
    [int]$TimeoutSeconds = 3600     # Tempo limite por algoritmo/execução (padrão: 1h)
)

$ErrorActionPreference = "Stop"

$genInput = Join-Path $PSScriptRoot "output\gen_input.exe"
$runSort  = Join-Path $PSScriptRoot "output\run_sort.exe"

# Garante que os binários existem e estão compilados
if (-not (Test-Path $genInput) -or -not (Test-Path $runSort)) {
    Write-Host "Binários não encontrados em output\. Compilando..." -ForegroundColor Yellow
    if (-not (Test-Path (Join-Path $PSScriptRoot "output"))) {
        New-Item -ItemType Directory -Path (Join-Path $PSScriptRoot "output") | Out-Null
    }
    & "C:\Strawberry\c\bin\gcc.EXE" -Wall -Wextra -O2 rng.c utilarray.c gen_input.c -o "$genInput"
    & "C:\Strawberry\c\bin\gcc.EXE" -Wall -Wextra -O2 rng.c utilarray.c elapsedRunningTime.c quicksort.c radixsort.c run_sort.c -o "$runSort"
}

$outFile = Join-Path $PSScriptRoot "raw_results.csv"

# Se o arquivo não existir, escreve o cabeçalho
if (-not (Test-Path $outFile)) {
    "algoritmo;n;repeticao;seed;tempo_clock_s;tempo_wall_s;ok_ordenado" | Out-File -FilePath $outFile -Encoding utf8
}

# Função para obter número de repetições por tamanho
function Get-Reps([long]$num) {
    switch ($num) {
        1000      { return 7 }
        10000     { return 7 }
        100000    { return 5 }
        500000    { return 5 }
        1000000   { return 3 }
        5000000   { return 3 }
        10000000  { return 3 }
        50000000  { return 2 }
        100000000 { return 2 }
        200000000 { return 1 }
        default   { return 1 }
    }
}

$allSizes = @(1000, 10000, 100000, 500000, 1000000, 5000000, 10000000, 50000000, 100000000, 200000000)

if ($Quick) {
    Write-Host "=== Modo Rápido (-Quick): testando n de 1.000 até 1.000.000 ===" -ForegroundColor Cyan
    $sizes = @(1000, 10000, 100000, 500000, 1000000)
} else {
    $sizes = $allSizes
}

Write-Host "Iniciando benchmarks... Resultados serão gravados em: $outFile" -ForegroundColor Green

foreach ($n in $sizes) {
    $reps = Get-Reps $n
    if ($Quick -and $reps -gt 2) { $reps = 2 }

    Write-Host "`n========================================================" -ForegroundColor DarkGray
    Write-Host ">>> Tamanho n = $n ($reps repeticoes)" -ForegroundColor Cyan
    Write-Host "========================================================" -ForegroundColor DarkGray

    for ($r = 1; $r -le $reps; $r++) {
        [long]$seed = ([long]$n * 1000003L) + ([long]$r * 7919L) + 12345L
        
        # Armazena temporariamente no disco local (TEMP) para não sincronizar com Google Drive
        $tempFile = [System.IO.Path]::Combine($env:TEMP, "arr_${n}_${r}.bin")
        $stdOutFile = [System.IO.Path]::Combine($env:TEMP, "run_sort_out_${n}_${r}.txt")

        Write-Host "  [Rep $r/$reps] Gerando entrada aleatória (seed=$seed)..." -NoNewline
        & $genInput $n $seed $tempFile
        Write-Host " Pronto" -ForegroundColor Green

        foreach ($algo in @("qs", "radix")) {
            $algoNome = if ($algo -eq "qs") { "Quicksort" } else { "Radix Sort" }
            Write-Host "    -> $algoNome ($algo)... " -NoNewline

            $proc = Start-Process -FilePath $runSort -ArgumentList @($algo, $tempFile) -NoNewWindow -PassThru -RedirectStandardOutput $stdOutFile
            $finished = $proc.WaitForExit($TimeoutSeconds * 1000)

            if (-not $finished) {
                $proc.Kill()
                Write-Host "TIMEOUT!" -ForegroundColor Red
                "$algo;$n;$r;$seed;timeout reached;timeout reached;0" | Out-File -FilePath $outFile -Append -Encoding utf8
            } else {
                $line = (Get-Content $stdOutFile -Raw).Trim()
                if ($line) {
                    # Formato de run_sort: algoritmo;n;tempo_clock_s;tempo_wall_s;ok_ordenado
                    $p = $line -split ";"
                    if ($p.Length -ge 5) {
                        # CSV final: algoritmo;n;repeticao;seed;tempo_clock_s;tempo_wall_s;ok_ordenado
                        $csvLine = "$($p[0]);$($p[1]);$r;$seed;$($p[2]);$($p[3]);$($p[4])"
                        $csvLine | Out-File -FilePath $outFile -Append -Encoding utf8
                        Write-Host "OK em $($p[3])s (cpu: $($p[2])s, ordenado=$($p[4]))" -ForegroundColor Green
                    } else {
                        Write-Host "Saída inesperada: $line" -ForegroundColor Red
                    }
                } else {
                    Write-Host "Sem saída retornada" -ForegroundColor Red
                }
            }
            Remove-Item $stdOutFile -Force -ErrorAction SilentlyContinue
        }

        Remove-Item $tempFile -Force -ErrorAction SilentlyContinue
    }
}

Write-Host "`n=== Concluído! Resultados disponíveis em: ===" -ForegroundColor Green
Write-Host "$outFile`n" -ForegroundColor White
