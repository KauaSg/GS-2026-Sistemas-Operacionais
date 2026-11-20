#!/usr/bin/env bash
set -Eeuo pipefail
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/comum.sh"
exigir_root
carregar_configuracao
DESTINO="${1:-$SO_DIR/evidencias/execucao}"
mkdir -p "$DESTINO"
registrar INFO "Coleta de evidências operacionais iniciada em $DESTINO"

# Cada evidência técnica é coletada diretamente da VM e deve ser revisada antes de publicação.
{
  echo '=== Data/Hora ==='; date --iso-8601=seconds
  echo '=== Distribuição ==='; cat /etc/os-release
  echo '=== Hostname ==='; hostnamectl
  echo '=== IPv4 ==='; ip -4 addr show
  echo '=== Rotas ==='; ip -4 route
  echo '=== DNS ==='; resolvectl status 2>&1 || true
} > "$DESTINO/01_rede.txt"

{
  echo '=== SDK ==='; dotnet --list-sdks
  echo '=== Releases publicados ==='; ls -la "$APP_BASE_DIR"
  echo '=== Banco SQLite ==='; ls -lh "$APP_DATA_DIR/transitoclaro.db"
  echo '=== Endpoint HTTP ==='; curl -i -fsS --max-time 8 "$URL_SAUDE"
} > "$DESTINO/02_aplicacao.txt" 2>&1

{
  echo '=== API ==='; systemctl --no-pager --full status transitoclaro-api.service || true
  echo '=== Monitor ==='; systemctl --no-pager --full status transitoclaro-monitor.service || true
  echo '=== Políticas de restart ==='
  systemctl show transitoclaro-api.service -p Restart -p NRestarts
  systemctl show transitoclaro-monitor.service -p Restart -p NRestarts
} > "$DESTINO/03_systemd.txt" 2>&1

{
  echo '=== Últimos logs de provisionamento ==='; tail -n 70 "$LOG_DIR/provisionamento.log" || true
  echo '=== Últimos logs de monitoramento ==='; tail -n 70 "$LOG_DIR/monitoramento.log" || true
  echo '=== Alertas ==='; tail -n 70 "$LOG_DIR/alertas.log" || true
  echo '=== Teste de falha - API ==='; tail -n 70 "$LOG_DIR/teste_falha.log" || true
  echo '=== Teste de falha - MONITOR ==='; tail -n 70 "$LOG_DIR/teste_falha_monitor.log" || true
} > "$DESTINO/04_logs.txt" 2>&1

{
  echo '=== journal da API ==='; journalctl -u transitoclaro-api --no-pager -n 70 || true
  echo '=== journal do monitor ==='; journalctl -u transitoclaro-monitor --no-pager -n 70 || true
} > "$DESTINO/05_journal.txt" 2>&1

registrar INFO "Evidências coletadas em $DESTINO. Revise conteúdo antes de subir ao GitHub."
printf 'Arquivos coletados:\n'
find "$DESTINO" -maxdepth 1 -type f -printf '%f\n' | sort
