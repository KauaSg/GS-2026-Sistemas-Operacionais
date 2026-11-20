#!/usr/bin/env bash
set -Eeuo pipefail
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/comum.sh"
carregar_configuracao
validar_porta
validar_variaveis_monitor

MODO="${1:---once}"
case "$MODO" in
  --once|--loop|--simular-alerta) ;;
  *) echo 'Uso: 06_monitorar.sh [--once|--loop|--simular-alerta]' >&2; exit 2 ;;
esac

if [[ "$MODO" == "--simular-alerta" ]]; then
  # Reduz os limites apenas nesta execução, sem consumir recursos da VM.
  LIMITE_CPU=0
  LIMITE_RAM=0
  LIMITE_DISCO=0
fi

monitor_log() {
  local nivel="$1"; shift
  local linha
  linha="$(date --iso-8601=seconds) [$nivel] [monitor] $*"
  mkdir -p "$LOG_DIR"
  printf '%s\n' "$linha" | tee -a "$LOG_DIR/monitoramento.log"
  if [[ "$nivel" == "ALERTA" ]]; then
    printf '%s\n' "$linha" >> "$LOG_DIR/alertas.log"
  fi
  command -v logger >/dev/null 2>&1 && logger -t transitoclaro-monitor -- "$linha" || true
}

# CPU total via duas leituras de /proc/stat (sem dependência de pacotes adicionais).
ler_cpu() {
  local a_idle a_total b_idle b_total delta_total delta_idle
  read -r a_idle a_total < <(awk '/^cpu / {idle=$5+$6; total=0; for(i=2;i<=9;i++) total+=$i; print idle, total; exit}' /proc/stat)
  sleep 1
  read -r b_idle b_total < <(awk '/^cpu / {idle=$5+$6; total=0; for(i=2;i<=9;i++) total+=$i; print idle, total; exit}' /proc/stat)
  delta_total=$(( b_total - a_total ))
  delta_idle=$(( b_idle - a_idle ))
  if (( delta_total > 0 )); then echo $(( 100 * (delta_total - delta_idle) / delta_total )); else echo 0; fi
}

ler_ram() {
  awk '/^MemTotal:/ {total=$2} /^MemAvailable:/ {livre=$2} END {if(total>0) printf "%.0f", 100*(total-livre)/total; else print 0}' /proc/meminfo
}

ler_disco() { df -P / | awk 'NR==2 {gsub(/%/,"",$5); print $5}'; }

executar_medicao() {
  local cpu ram disco estado
  cpu="$(ler_cpu)"
  ram="$(ler_ram)"
  disco="$(ler_disco)"
  monitor_log INFO "CPU=${cpu}% RAM=${ram}% DISCO=${disco}% | limites CPU=${LIMITE_CPU} RAM=${LIMITE_RAM} DISCO=${LIMITE_DISCO}"

  (( cpu >= LIMITE_CPU )) && monitor_log ALERTA "Uso de CPU acima do limite: ${cpu}% (limite ${LIMITE_CPU}%)"
  (( ram >= LIMITE_RAM )) && monitor_log ALERTA "Uso de memória acima do limite: ${ram}% (limite ${LIMITE_RAM}%)"
  (( disco >= LIMITE_DISCO )) && monitor_log ALERTA "Uso de disco acima do limite: ${disco}% (limite ${LIMITE_DISCO}%)"

  if systemctl is-active --quiet transitoclaro-api.service; then
    if curl -fsS --max-time 4 "$URL_SAUDE" >/dev/null; then
      estado="API_ATIVA_HEALTH_OK"
    else
      estado="API_ATIVA_SEM_RESPOSTA"
      monitor_log ALERTA "API sem resposta HTTP em $URL_SAUDE"
    fi
  else
    estado="API_INATIVA"
    monitor_log ALERTA 'Serviço transitoclaro-api.service não está ativo'
  fi
  monitor_log INFO "ESTADO=$estado"
}

if [[ "$MODO" == "--loop" ]]; then
  monitor_log INFO "Serviço de monitoramento iniciado, intervalo ${INTERVALO_MONITORAMENTO}s"
  while true; do
    # Uma falha temporária de leitura não deve finalizar o serviço de monitoramento.
    executar_medicao || monitor_log ALERTA 'Falha na execução de uma medição'
    sleep "$INTERVALO_MONITORAMENTO"
  done
else
  executar_medicao
fi
