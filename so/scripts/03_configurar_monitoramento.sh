#!/usr/bin/env bash
set -Eeuo pipefail
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/comum.sh"
exigir_root
carregar_configuracao
validar_variaveis_monitor
trap 'registrar ERRO "Falha no serviço de monitoramento (linha $LINENO)"' ERR

install -d -o root -g root -m 0755 "$APP_BASE_DIR/so"
cp -a "$SO_DIR/." "$APP_BASE_DIR/so/"
chown -R root:root "$APP_BASE_DIR/so"
find "$APP_BASE_DIR/so/scripts" -type f -name '*.sh' -exec chmod 0755 {} +
install -d -m 0750 "$LOG_DIR"
install -m 0644 "$SO_DIR/config/transitoclaro-monitor.service" /etc/systemd/system/transitoclaro-monitor.service
install -m 0644 "$SO_DIR/config/90-transitoclaro" /etc/logrotate.d/90-transitoclaro

systemctl daemon-reload
systemctl enable transitoclaro-monitor.service
systemctl restart transitoclaro-monitor.service
sleep 2
if ! systemctl is-active --quiet transitoclaro-monitor.service; then
  registrar ERRO 'Monitoramento não iniciado; use journalctl -u transitoclaro-monitor -n 50.'
  exit 1
fi
registrar INFO 'Monitoramento ativo no systemd, configurado com Restart=always.'
