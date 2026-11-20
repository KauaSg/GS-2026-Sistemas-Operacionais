#!/usr/bin/env bash
# Teste controlado da tolerância a falhas do MONITOR (systemd).
# O processo é encerrado inesperadamente, nunca via systemctl stop,
# porque uma parada administrativa deliberada não dispara Restart=always.
set -Eeuo pipefail
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/comum.sh"
exigir_root
carregar_configuracao
validar_variaveis_monitor
install -d -m 0750 "$LOG_DIR"
ARQ_TESTE="$LOG_DIR/teste_falha_monitor.log"
SERVICO=transitoclaro-monitor.service

salvar() {
  local linha
  linha="$(date --iso-8601=seconds) | $*"
  printf '%s\n' "$linha" | tee -a "$ARQ_TESTE"
  command -v logger >/dev/null 2>&1 && logger -t transitoclaro-teste-monitor -- "$linha" || true
}

if ! systemctl is-enabled --quiet "$SERVICO"; then
  salvar 'ERRO: monitor não habilitado para iniciar com o sistema.'
  exit 1
fi
if ! systemctl is-active --quiet "$SERVICO"; then
  salvar 'ERRO: monitor inativo; instale e inicie os serviços antes do teste.'
  exit 1
fi

PID_ANTERIOR="$(systemctl show "$SERVICO" -p MainPID --value)"
[[ "$PID_ANTERIOR" =~ ^[0-9]+$ ]] && (( PID_ANTERIOR > 0 )) || {
  salvar 'ERRO: PID principal inválido; teste cancelado.'; exit 1;
}

ARQ_MONITOR="$LOG_DIR/monitoramento.log"
LINHAS_ANTES=0
if [[ -f "$ARQ_MONITOR" ]]; then LINHAS_ANTES="$(wc -l < "$ARQ_MONITOR")"; fi
salvar "INÍCIO: monitor ativo; PID=$PID_ANTERIOR; Restart=$(systemctl show "$SERVICO" -p Restart --value)"
salvar 'FALHA SIMULADA: encerrando somente o processo principal do monitor com SIGKILL.'
kill -KILL "$PID_ANTERIOR"

RECUPERADO=nao
for (( tentativa=1; tentativa<=30; tentativa++ )); do
  sleep 2
  PID_NOVO="$(systemctl show "$SERVICO" -p MainPID --value)"
  if [[ "$PID_NOVO" =~ ^[0-9]+$ ]] && (( PID_NOVO > 0 )) &&
     [[ "$PID_NOVO" != "$PID_ANTERIOR" ]] && systemctl is-active --quiet "$SERVICO" &&
     [[ -f "$ARQ_MONITOR" ]] &&
     (( $(wc -l < "$ARQ_MONITOR") > LINHAS_ANTES )); then
    RECUPERADO=sim
    salvar "RECUPERAÇÃO OK: novo PID=$PID_NOVO; o monitor voltou a gerar logs."
    break
  fi
done

{
  printf '\n=== JOURNALCTL DO MONITOR (ÚLTIMOS 3 MIN) ===\n'
  journalctl -u "$SERVICO" --since '-3 minutes' --no-pager -n 40 || true
  printf '\n'
} >> "$ARQ_TESTE"

if [[ "$RECUPERADO" != sim ]]; then
  salvar 'ERRO: monitor não se recuperou automaticamente e voltou a registrar medições em até 60 segundos.'
  exit 1
fi
registrar INFO "Teste de falha do monitor concluído: PID $PID_ANTERIOR -> $PID_NOVO."
