#!/usr/bin/env bash
# Biblioteca de apoio aos scripts de Sistemas Operacionais.

SO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
ARQ_CONFIG="${TC_CONFIG_FILE:-/etc/transitoclaro/so.env}"

carregar_configuracao() {
  if [[ -r "$ARQ_CONFIG" ]]; then
    # Arquivo de configuração criado pelo próprio administrador da VM.
    # shellcheck disable=SC1090
    source "$ARQ_CONFIG"
  elif [[ -r "$SO_DIR/config/so.env.example" ]]; then
    # shellcheck disable=SC1091
    source "$SO_DIR/config/so.env.example"
  else
    echo "Não foi possível localizar a configuração de SO" >&2
    return 1
  fi

  : "${VM_HOSTNAME:=transitoclaro-vm}"
  : "${DNS_SERVERS:=1.1.1.1 8.8.8.8}"
  : "${USAR_IP_FIXO:=nao}"
  : "${APP_REPO_URL:=https://github.com/PietroVP0777/PietroVP0777-Gs_2026_Cs.git}"
  : "${APP_REF:=main}"
  : "${APP_SOURCE_DIR:=}"
  : "${APP_PORT:=5000}"
  : "${APP_BIND_IP:=127.0.0.1}"
  : "${LIMITE_CPU:=80}"
  : "${LIMITE_RAM:=80}"
  : "${LIMITE_DISCO:=85}"
  : "${INTERVALO_MONITORAMENTO:=15}"

  LOG_DIR="${TC_LOG_DIR:-/var/log/transitoclaro}"
  APP_USER="transitoclaro"
  APP_DATA_DIR="/var/lib/transitoclaro"
  APP_BASE_DIR="/opt/transitoclaro"
  APP_RELEASES_DIR="$APP_BASE_DIR/releases"
  APP_CURRENT="$APP_BASE_DIR/current"
  URL_SAUDE="http://127.0.0.1:${APP_PORT}/api/linhas"
}

exigir_root() {
  if (( EUID != 0 )); then
    echo "Execute como root usando sudo." >&2
    exit 1
  fi
}

registrar() {
  local nivel="$1"; shift
  local mensagem="$*" linha
  linha="$(date --iso-8601=seconds) [$nivel] [$(_nome_script)] $mensagem"
  mkdir -p "$LOG_DIR"
  printf '%s\n' "$linha" | tee -a "$LOG_DIR/provisionamento.log"
  if command -v logger >/dev/null 2>&1; then
    logger -t "transitoclaro-so" -- "$linha" || true
  fi
}

_nome_script() { basename -- "${0}"; }

validar_porta() {
  [[ "$APP_PORT" =~ ^[0-9]+$ ]] && (( APP_PORT >= 1024 && APP_PORT <= 65535 )) || {
    echo "APP_PORT deve estar entre 1024 e 65535" >&2; return 1;
  }
}

validar_percentual() {
  local n="$1"
  [[ "$n" =~ ^[0-9]+$ ]] && (( n >= 0 && n <= 100 ))
}

validar_variaveis_monitor() {
  validar_percentual "$LIMITE_CPU" && validar_percentual "$LIMITE_RAM" &&
  validar_percentual "$LIMITE_DISCO" && [[ "$INTERVALO_MONITORAMENTO" =~ ^[0-9]+$ ]] &&
  (( INTERVALO_MONITORAMENTO >= 3 && INTERVALO_MONITORAMENTO <= 3600 )) || {
    echo "Configuração de monitoramento inválida" >&2; return 1;
  }
}
