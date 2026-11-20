#!/usr/bin/env bash
set -Eeuo pipefail
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/comum.sh"
exigir_root
carregar_configuracao
trap 'registrar ERRO "Falha no provisionamento de rede (linha $LINENO)"' ERR

if [[ ! -r /etc/os-release ]]; then
  registrar ERRO 'Distribuição Linux não identificada.'
  exit 1
fi
# shellcheck disable=SC1091
source /etc/os-release
if [[ "${ID:-}" != "ubuntu" || "${VERSION_ID:-}" != "24.04" ]]; then
  registrar ERRO "Esta entrega foi validada para Ubuntu 24.04 LTS. Detectado: ${PRETTY_NAME:-desconhecido}."
  exit 1
fi
if [[ ! "$VM_HOSTNAME" =~ ^[a-zA-Z][a-zA-Z0-9.-]*$ ]]; then
  registrar ERRO 'VM_HOSTNAME inválido.'
  exit 1
fi

registrar INFO 'Instalando pacotes de rede e auditoria.'
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y -qq ca-certificates curl git iproute2 dnsutils net-tools logrotate

registrar INFO "Configurando hostname como $VM_HOSTNAME."
hostnamectl set-hostname "$VM_HOSTNAME"
if ! grep -Eq "^[[:space:]]*127\.0\.1\.1[[:space:]].*\b${VM_HOSTNAME}\b" /etc/hosts; then
  printf '127.0.1.1\t%s\n' "$VM_HOSTNAME" >> /etc/hosts
fi

if systemctl list-unit-files systemd-resolved.service --no-legend 2>/dev/null | grep -q 'systemd-resolved.service'; then
  registrar INFO "Configurando DNS persistente: $DNS_SERVERS"
  mkdir -p /etc/systemd/resolved.conf.d
  cat > /etc/systemd/resolved.conf.d/90-transitoclaro.conf <<DNS
[Resolve]
DNS=$DNS_SERVERS
FallbackDNS=$DNS_SERVERS
DNS
  systemctl restart systemd-resolved
else
  registrar ALERTA 'systemd-resolved não está disponível; DNS existente foi preservado.'
fi

# Nunca troca IP da VM por padrão para não interromper a conexão do usuário.
if [[ "$USAR_IP_FIXO" == "sim" ]]; then
  if [[ -z "${INTERFACE_REDE:-}" || ! "$INTERFACE_REDE" =~ ^[a-zA-Z0-9_.:-]+$ ||
        ! "${IP_FIXO_CIDR:-}" =~ ^[0-9.]+/[0-9]+$ || ! "${GATEWAY_IPV4:-}" =~ ^[0-9.]+$ ]]; then
    registrar ERRO 'Para IP fixo, informe INTERFACE_REDE, IP_FIXO_CIDR e GATEWAY_IPV4 válidos no arquivo de configuração.'
    exit 1
  fi
  registrar ALERTA "Aplicando IP FIXO em $INTERFACE_REDE; faça isso no console da VM, pois a sessão pode cair."
  mkdir -p /etc/netplan /var/backups/transitoclaro
  tar -czf "/var/backups/transitoclaro/netplan-$(date +%Y%m%d-%H%M%S).tar.gz" -C /etc netplan
  cat > /etc/netplan/99-transitoclaro.yaml <<YAML
network:
  version: 2
  renderer: networkd
  ethernets:
    $INTERFACE_REDE:
      dhcp4: false
      addresses:
        - $IP_FIXO_CIDR
      routes:
        - to: default
          via: $GATEWAY_IPV4
      nameservers:
        addresses: [$(echo "$DNS_SERVERS" | tr ' ' ',')]
YAML
  chmod 600 /etc/netplan/99-transitoclaro.yaml
  netplan generate
  netplan apply
else
  registrar INFO 'Endereço IPv4 mantido via DHCP (configuração padrão da VM).'
fi

registrar INFO "Interfaces e IPs: $(ip -o -4 addr show scope global | awk '{print $2"="$4}' | tr '\n' ' ')"
registrar INFO "Gateway/rota padrão: $(ip -4 route show default | head -n 1)"
registrar INFO "Hostname atual: $(hostnamectl --static)"
registrar INFO 'Provisionamento de rede finalizado.'
