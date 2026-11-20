#!/usr/bin/env bash
set -Eeuo pipefail
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/comum.sh"
exigir_root
carregar_configuracao
validar_porta
trap 'registrar ERRO "Falha na instalação da API (linha $LINENO). Verifique $LOG_DIR/provisionamento.log"' ERR

if [[ "${ID:-}" != "ubuntu" ]]; then
  # ID é definido pelo /etc/os-release somente nesta função.
  source /etc/os-release
fi
[[ "${ID:-}" == "ubuntu" && "${VERSION_ID:-}" == "24.04" ]] || {
  registrar ERRO 'Use Ubuntu 24.04 LTS.'; exit 1;
}

registrar INFO 'Instalando Git e SDK .NET 10 pelos repositórios oficiais do Ubuntu.'
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y -qq git ca-certificates curl dotnet-sdk-10.0
registrar INFO "SDK instalado: $(dotnet --version)"

if ! id "$APP_USER" >/dev/null 2>&1; then
  useradd --system --home-dir "$APP_DATA_DIR" --shell /usr/sbin/nologin "$APP_USER"
fi
install -d -o "$APP_USER" -g "$APP_USER" -m 0750 "$APP_DATA_DIR"
install -d -o root -g root -m 0755 "$APP_RELEASES_DIR"

TEMP_DIR="$(mktemp -d /tmp/transitoclaro-src-XXXXXXXX)"
trap 'rm -rf -- "$TEMP_DIR"' EXIT
if [[ -n "$APP_SOURCE_DIR" ]]; then
  [[ -d "$APP_SOURCE_DIR" ]] || { registrar ERRO "APP_SOURCE_DIR não encontrado: $APP_SOURCE_DIR"; exit 1; }
  registrar INFO "Copiando código da pasta local $APP_SOURCE_DIR"
  cp -a "$APP_SOURCE_DIR/." "$TEMP_DIR/"
else
  registrar INFO "Clonando repositório $APP_REPO_URL ($APP_REF)"
  if ! git clone --depth 1 --branch "$APP_REF" "$APP_REPO_URL" "$TEMP_DIR/repo"; then
    registrar ERRO 'Não foi possível clonar o repositório. Se ele estiver privado, copie o projeto C# para a VM e defina APP_SOURCE_DIR.'
    exit 1
  fi
  # Move apenas o conteúdo usado no build; o diretório .git não é necessário.
  cp -a "$TEMP_DIR/repo/." "$TEMP_DIR/"
fi

ARQ_PROJETO="$TEMP_DIR/src/TransitoClaro.Api/TransitoClaro.Api.csproj"
[[ -f "$ARQ_PROJETO" ]] || {
  registrar ERRO "Projeto C# não encontrado em src/TransitoClaro.Api/TransitoClaro.Api.csproj"; exit 1;
}

RELEASE="$APP_RELEASES_DIR/$(date +%Y%m%d-%H%M%S)-$$"
install -d -m 0755 "$RELEASE"
registrar INFO 'Restaurando dependências e publicando a API CitizenTech.'
DOTNET_CLI_TELEMETRY_OPTOUT=1 dotnet restore "$ARQ_PROJETO"
DOTNET_CLI_TELEMETRY_OPTOUT=1 dotnet publish "$ARQ_PROJETO" -c Release --no-restore -o "$RELEASE"
[[ -s "$RELEASE/TransitoClaro.Api.dll" ]] || { registrar ERRO 'DLL não gerada no publish.'; exit 1; }
chown -R root:root "$RELEASE"
chmod -R a+rX "$RELEASE"

APP_ENV="/etc/transitoclaro/app.env"
mkdir -p /etc/transitoclaro
cat > "$APP_ENV" <<ENV
ASPNETCORE_ENVIRONMENT=Production
ASPNETCORE_URLS=http://$APP_BIND_IP:$APP_PORT
ConnectionStrings__Padrao="Data Source=$APP_DATA_DIR/transitoclaro.db"
DOTNET_NOLOGO=true
ENV
chmod 0640 "$APP_ENV"
chown root:"$APP_USER" "$APP_ENV"

install -m 0644 "$SO_DIR/config/transitoclaro-api.service" /etc/systemd/system/transitoclaro-api.service
ANTERIOR="$(readlink -f "$APP_CURRENT" || true)"
ln -sfn "$RELEASE" "$APP_BASE_DIR/current.novo"
mv -Tf "$APP_BASE_DIR/current.novo" "$APP_CURRENT"
systemctl daemon-reload
systemctl enable transitoclaro-api.service
systemctl restart transitoclaro-api.service

OK=nao
for _ in $(seq 1 30); do
  if systemctl is-active --quiet transitoclaro-api.service && curl -fsS --max-time 2 "$URL_SAUDE" >/dev/null; then
    OK=sim; break
  fi
  sleep 2
done

if [[ "$OK" != "sim" ]]; then
  registrar ERRO 'A API não respondeu dentro do prazo. Verifique journalctl -u transitoclaro-api -n 80.'
  if [[ -n "$ANTERIOR" && -d "$ANTERIOR" ]]; then
    ln -sfn "$ANTERIOR" "$APP_BASE_DIR/current.anterior"
    mv -Tf "$APP_BASE_DIR/current.anterior" "$APP_CURRENT"
    systemctl restart transitoclaro-api.service || true
    registrar ALERTA 'Release anterior restaurado.'
  fi
  exit 1
fi

registrar INFO "API publicada em $RELEASE, saudável em $URL_SAUDE"
