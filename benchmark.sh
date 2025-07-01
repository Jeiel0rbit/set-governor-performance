#!/bin/bash
# CPU Governor Benchmark Script
# Compara performance entre schedutil e performance governors

set -euo pipefail

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Função para log colorido
log() {
    local level=$1
    shift
    local message="$*"
    local timestamp=$(date '+%H:%M:%S')
    
    case $level in
        "INFO")  echo -e "${BLUE}[INFO]${NC} [$timestamp] $message" ;;
        "WARN")  echo -e "${YELLOW}[WARN]${NC} [$timestamp] $message" ;;
        "ERROR") echo -e "${RED}[ERROR]${NC} [$timestamp] $message" ;;
        "SUCCESS") echo -e "${GREEN}[SUCCESS]${NC} [$timestamp] $message" ;;
    esac
}

# Verificar dependências
check_dependencies() {
    log "INFO" "Verificando dependências..."
    
    local deps=("cpupower" "stress-ng" "sysbench" "bc")
    local missing=()
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing+=("$dep")
        fi
    done
    
    if [ ${#missing[@]} -gt 0 ]; then
        log "ERROR" "Dependências ausentes: ${missing[*]}"
        log "INFO" "Ubuntu/Debian: sudo apt install linux-tools-common linux-tools-\$(uname -r) stress-ng sysbench bc"
        log "INFO" "CentOS/RHEL/Fedora: sudo dnf install kernel-tools stress-ng sysbench bc"
        exit 1
    fi
    
    log "SUCCESS" "Todas as dependências estão disponíveis"
}

# Verificar governors disponíveis
check_governors() {
    log "INFO" "Verificando governors disponíveis..."
    
    local available_governors
    available_governors=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_governors 2>/dev/null || echo "")
    
    if [[ -z "$available_governors" ]]; then
        log "ERROR" "CPUfreq não está disponível neste sistema"
        exit 1
    fi
    
    log "INFO" "Governors disponíveis: $available_governors"
    
    if [[ ! "$available_governors" =~ "schedutil" ]]; then
        log "ERROR" "Governor 'schedutil' não está disponível"
        exit 1
    fi
    
    if [[ ! "$available_governors" =~ "performance" ]]; then
        log "ERROR" "Governor 'performance' não está disponível"
        exit 1
    fi
    
    log "SUCCESS" "Governors schedutil e performance estão disponíveis"
}

# Mudar governor
set_governor() {
    local governor=$1
    log "INFO" "Mudando para governor: $governor"
    
    if sudo cpupower frequency-set -g "$governor" &>/dev/null; then
        sleep 2
        log "SUCCESS" "Governor alterado para: $governor"
    else
        log "ERROR" "Falha ao alterar governor para: $governor"
        exit 1
    fi
}

# Mostrar informações da CPU
show_cpu_info() {
    local governor=$1
    echo ""
    echo "=== Informações da CPU - Governor: $governor ==="
    
    # Governor atual
    echo "Governor atual: $(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor)"
    
    # Frequências
    echo "Frequência mín/máx: $(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq | awk '{printf "%.2f", $1/1000000}') GHz / $(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq | awk '{printf "%.2f", $1/1000000}') GHz"
    
    # Frequência atual de algumas CPUs
    echo "Frequências atuais:"
    for cpu in {0..3}; do
        if [ -f "/sys/devices/system/cpu/cpu$cpu/cpufreq/scaling_cur_freq" ]; then
            freq=$(cat "/sys/devices/system/cpu/cpu$cpu/cpufreq/scaling_cur_freq")
            echo "  CPU$cpu: $(echo "$freq" | awk '{printf "%.2f", $1/1000000}') GHz"
        fi
    done
    echo ""
}

# Benchmark com sysbench
benchmark_sysbench() {
    local governor=$1
    log "INFO" "Executando benchmark sysbench com governor: $governor"
    
    set_governor "$governor"
    show_cpu_info "$governor"
    
    echo "--- Benchmark sysbench CPU ---"
    local result_file="/tmp/sysbench_${governor}.txt"
    
    sysbench cpu \
        --cpu-max-prime=20000 \
        --threads=$(nproc) \
        --time=30 \
        run > "$result_file" 2>&1
    
    # Extrair resultados importantes
    echo "Resultados:"
    grep -E "(events per second|total time|min:|avg:|max:)" "$result_file" || cat "$result_file"
    echo ""
}

# Benchmark com stress-ng
benchmark_stress() {
    local governor=$1
    log "INFO" "Executando benchmark stress-ng com governor: $governor"
    
    set_governor "$governor"
    
    echo "--- Benchmark stress-ng ---"
    
    # Monitor frequência em background
    (
        echo "Monitoramento de frequência (primeiros 10 segundos):"
        for i in {1..10}; do
            if [ -f "/proc/cpuinfo" ]; then
                freq_line=$(grep 'MHz' /proc/cpuinfo | head -1)
                echo "  $i: $freq_line"
            fi
            sleep 1
        done
    ) &
    monitor_pid=$!
    
    # Executar stress test
    stress-ng --cpu $(nproc) --timeout 30s --metrics-brief
    
    # Parar monitor se ainda estiver rodando
    kill $monitor_pid 2>/dev/null || true
    wait $monitor_pid 2>/dev/null || true
    echo ""
}

# Teste de responsividade
benchmark_responsiveness() {
    local governor=$1
    log "INFO" "Testando responsividade com governor: $governor"
    
    set_governor "$governor"
    
    echo "--- Teste de Responsividade ---"
    
    local total_time=0
    local iterations=10
    
    echo "Executando $iterations testes de tempo de resposta..."
    
    for i in $(seq 1 $iterations); do
        local start_time
        local end_time
        local duration
        
        start_time=$(date +%s.%N)
        ls /usr/bin > /dev/null 2>&1
        end_time=$(date +%s.%N)
        
        duration=$(echo "$end_time - $start_time" | bc -l)
        total_time=$(echo "$total_time + $duration" | bc -l)
        
        printf "  Teste %2d: %0.6f segundos\n" "$i" "$duration"
    done
    
    local avg_time
    avg_time=$(echo "$total_time / $iterations" | bc -l)
    printf "Tempo médio de resposta: %0.6f segundos\n" "$avg_time"
    echo ""
}

# Teste de rajadas interativas
benchmark_interactive() {
    local governor=$1
    log "INFO" "Testando cargas interativas com governor: $governor"
    
    set_governor "$governor"
    
    echo "--- Teste de Cargas Interativas ---"
    echo "Simulando rajadas de CPU (típico de aplicações interativas)..."
    
    for burst in {1..3}; do
        echo "Rajada $burst:"
        
        # Frequência antes da carga
        local freq_before
        if [ -f "/proc/cpuinfo" ]; then
            freq_before=$(grep 'MHz' /proc/cpuinfo | head -1 | awk '{print $4}')
        else
            freq_before="N/A"
        fi
        
        # Iniciar carga súbita
        stress-ng --cpu $(nproc) --timeout 3s --quiet &
        local stress_pid=$!
        
        # Esperar um pouco e medir frequência durante a carga
        sleep 1
        local freq_during
        if [ -f "/proc/cpuinfo" ]; then
            freq_during=$(grep 'MHz' /proc/cpuinfo | head -1 | awk '{print $4}')
        else
            freq_during="N/A"
        fi
        
        # Esperar carga terminar
        wait $stress_pid
        
        # Frequência após a carga
        sleep 1
        local freq_after
        if [ -f "/proc/cpuinfo" ]; then
            freq_after=$(grep 'MHz' /proc/cpuinfo | head -1 | awk '{print $4}')
        else
            freq_after="N/A"
        fi
        
        printf "  Antes: %s MHz | Durante: %s MHz | Depois: %s MHz\n" \
               "$freq_before" "$freq_during" "$freq_after"
        
        sleep 2
    done
    echo ""
}

# Monitoramento contínuo
monitor_continuous() {
    local governor=$1
    local duration=${2:-60}
    
    log "INFO" "Monitoramento contínuo com governor: $governor por ${duration}s"
    
    set_governor "$governor"
    
    local log_file="/tmp/cpu_monitor_${governor}_$(date +%s).csv"
    
    echo "--- Monitoramento Contínuo ---"
    echo "Salvando dados em: $log_file"
    
    # Cabeçalho do CSV
    echo "timestamp,freq_mhz,cpu_usage_percent,load_1min,temp_celsius" > "$log_file"
    
    # Monitor em background
    (
        for ((i=1; i<=duration; i++)); do
            local timestamp
            local freq
            local cpu_usage
            local load_1min
            local temp
            
            timestamp=$(date '+%H:%M:%S')
            
            # Frequência
            if [ -f "/proc/cpuinfo" ]; then
                freq=$(grep 'MHz' /proc/cpuinfo | head -1 | awk '{print $4}')
            else
                freq="0"
            fi
            
            # Uso de CPU
            cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1 | tr -d ' ')
            [ -z "$cpu_usage" ] && cpu_usage="0"
            
            # Load average
            load_1min=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | tr -d ', ')
            [ -z "$load_1min" ] && load_1min="0"
            
            # Temperatura (se disponível)
            if [ -f /sys/class/thermal/thermal_zone0/temp ]; then
                local temp_raw
                temp_raw=$(cat /sys/class/thermal/thermal_zone0/temp)
                temp=$((temp_raw / 1000))
            else
                temp="N/A"
            fi
            
            echo "$timestamp,$freq,$cpu_usage,$load_1min,$temp" >> "$log_file"
            
            # Mostrar progresso
            if (( i % 10 == 0 )); then
                printf "  Progresso: %d/%d segundos (Freq: %s MHz, CPU: %s%%, Load: %s)\n" \
                       "$i" "$duration" "$freq" "$cpu_usage" "$load_1min"
            fi
            
            sleep 1
        done
    ) &
    
    local monitor_pid=$!
    
    # Executar cargas variáveis durante o monitoramento
    echo "Aplicando cargas variáveis..."
    
    # Carga leve inicial
    sleep 5
    
    # Carga média
    echo "  Aplicando carga média..."
    stress-ng --cpu $(($(nproc) / 2)) --timeout 15s --quiet &
    sleep 20
    
    # Carga alta
    echo "  Aplicando carga alta..."
    stress-ng --cpu $(nproc) --timeout 10s --quiet &
    sleep 15
    
    # Carga baixa
    echo "  Aplicando carga baixa..."
    stress-ng --cpu 1 --timeout 15s --quiet &
    sleep 20
    
    # Esperar monitor terminar
    wait $monitor_pid
    
    # Mostrar estatísticas
    echo "Estatísticas do monitoramento:"
    awk -F',' 'NR>1 && $2 != "N/A" {
        freq_sum += $2; freq_count++;
        usage_sum += $3; usage_count++;
        load_sum += $4; load_count++;
    } END {
        if (freq_count > 0) printf "  Frequência média: %.2f MHz\n", freq_sum/freq_count;
        if (usage_count > 0) printf "  Uso médio de CPU: %.2f%%\n", usage_sum/usage_count;
        if (load_count > 0) printf "  Load average médio: %.2f\n", load_sum/load_count;
    }' "$log_file"
    
    echo "Dados completos salvos em: $log_file"
    echo ""
}

# Comparar resultados
compare_results() {
    echo ""
    echo "================================="
    echo "     RESUMO DA COMPARAÇÃO"
    echo "================================="
    
    log "INFO" "Para análise detalhada, verifique:"
    echo "  - Logs em /tmp/cpu_monitor_*.csv"
    echo "  - Resultados sysbench em /tmp/sysbench_*.txt"
    echo ""
    
    log "INFO" "Interpretação dos resultados:"
    echo "  - PERFORMANCE: Frequência máxima constante, maior consumo, melhor para cargas sustentadas"
    echo "  - SCHEDUTIL: Frequência dinâmica, menor consumo, boa responsividade para cargas variáveis"
    echo ""
    
    log "INFO" "Considere usar:"
    echo "  - PERFORMANCE: Servidores, workstations, gaming, renderização"
    echo "  - SCHEDUTIL: Laptops, uso geral, eficiência energética"
}

# Função principal
main() {
    echo "========================================"
    echo "  CPU Governor Benchmark Tool"
    echo "  Comparação: schedutil vs performance"
    echo "========================================"
    echo ""
    
    # Verificações iniciais
    check_dependencies
    check_governors
    
    local governors=("schedutil" "performance")
    
    # Executar todos os benchmarks
    for governor in "${governors[@]}"; do
        echo ""
        echo "######################################"
        echo "   TESTANDO GOVERNOR: $governor"
        echo "######################################"
        
        benchmark_sysbench "$governor"
        benchmark_stress "$governor"
        benchmark_responsiveness "$governor"
        benchmark_interactive "$governor"
        monitor_continuous "$governor" 30
    done
    
    # Comparar resultados
    compare_results
    
    log "SUCCESS" "Benchmark concluído! Verifique os arquivos em /tmp/ para análise detalhada."
}

# Verificar se está sendo executado como script principal
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi