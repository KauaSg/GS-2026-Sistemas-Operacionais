#!/usr/bin/env bash
set -Eeuo pipefail
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/comum.sh"
exigir_root
carregar_configuracao
registrar INFO 'Iniciando verificação operacional de rede, .NET, banco e serviços.'

printf '\n=== HOSTNAME / IP / ROTA ===\n'
hostnamectl --static
ip -o -4 addr show scope global
ip -4 route show default

printf '\n=== DNS ===\n'
if command -v resolvectl >/dev/null 2>&1; then resolvectl status | head -n 35 || true; fi
getent hosts github.com || registrar ALERTA 'Resolução externa de github.com indisponível.'

printf '\n=== SDK DOTNET ===\n'
dotnet --list-sdks

printf '\n=== SERVIÇOS SYSTEMD ===\n'
systemctl --no-pager --full status transitoclaro-api.service transitoclaro-monitor.service || true

printf '\n=== HTTP REAL (ENDPOINT C#) ===\n'
if curl -fsS --max-time 8 "$URL_SAUDE"; then
  printf '\n'
  registrar INFO "API respondeu corretamente em $URL_SAUDE"
else
  registrar ERRO "API não respondeu em $URL_SAUDE"
  exit 1
fi

printf '\n=== BANCO DE DADOS ===\n'
if [[ -s "$APP_DATA_DIR/transitoclaro.db" ]]; then
  stat --format='Arquivo: %n | tamanho: %s bytes | proprietário: %U' "$APP_DATA_DIR/transitoclaro.db"
  registrar INFO 'Banco SQLite encontrado e não vazio.'
else
  registrar ERRO 'Banco SQLite ainda não existe ou está vazio.'
  exit 1
fi

printf '\n=== ÚLTIMOS LOGS DE AUDITORIA ===\n'
tail -n 8 "$LOG_DIR/provisionamento.log"
if [[ -s "$LOG_DIR/monitoramento.log" ]]; then tail -n 8 "$LOG_DIR/monitoramento.log"; fi
registrar INFO 'Validação do ambiente concluída.'
