#!/usr/bin/env bash
set -Eeuo pipefail
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/comum.sh"
exigir_root
carregar_configuracao
mkdir -p "$LOG_DIR"
ARQ_TESTE="$LOG_DIR/teste_falha.log"
registrar INFO 'Teste de falha controlada iniciado. Execute apenas na VM da GS.'

if ! systemctl is-active --quiet transitoclaro-api.service; then
  registrar ERRO 'A API já está inativa. Execute a instalação antes do teste de falha.'
  exit 1
fi

PID_ANTERIOR="$(systemctl show transitoclaro-api.service -p MainPID --value)"
[[ "$PID_ANTERIOR" =~ ^[0-9]+$ ]] && (( PID_ANTERIOR > 0 )) || {
  registrar ERRO 'Não foi possível obter o PID da API.'; exit 1;
}
printf '%s | INÍCIO | serviço ativo; PID=%s\n' "$(date --iso-8601=seconds)" "$PID_ANTERIOR" | tee -a "$ARQ_TESTE"

# Simula encerramento inesperado do processo principal para demonstrar Restart=always.
kill -KILL "$PID_ANTERIOR"
printf '%s | FALHA SIMULADA | processo %s encerrado com SIGKILL\n' "$(date --iso-8601=seconds)" "$PID_ANTERIOR" | tee -a "$ARQ_TESTE"

RECUPERADO=nao
for _ in $(seq 1 30); do
  sleep 2
  PID_ATUAL="$(systemctl show transitoclaro-api.service -p MainPID --value)"
  if [[ "$PID_ATUAL" =~ ^[0-9]+$ ]] && (( PID_ATUAL > 0 )) && [[ "$PID_ATUAL" != "$PID_ANTERIOR" ]] &&
     systemctl is-active --quiet transitoclaro-api.service && curl -fsS --max-time 3 "$URL_SAUDE" >/dev/null; then
    RECUPERADO=sim
    printf '%s | RECUPERAÇÃO OK | novo PID=%s; HTTP 200 no endpoint\n' "$(date --iso-8601=seconds)" "$PID_ATUAL" | tee -a "$ARQ_TESTE"
    break
  fi
done

{
  printf '\n=== JOURNALCTL DA API (ÚLTIMAS 3 MIN) ===\n'
  journalctl -u transitoclaro-api.service --since '-3 minutes' --no-pager -n 40 || true
  printf '\n'
} >> "$ARQ_TESTE"

if [[ "$RECUPERADO" != "sim" ]]; then
  registrar ERRO 'Falha: API não recuperada automaticamente em até 60 segundos.'
  exit 1
fi
registrar INFO "Teste concluído: PID $PID_ANTERIOR -> $PID_ATUAL; reinício automático comprovado."
