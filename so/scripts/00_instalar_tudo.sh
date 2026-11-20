#!/usr/bin/env bash
set -Eeuo pipefail
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/comum.sh"
exigir_root
mkdir -p /etc/transitoclaro
if [[ ! -f /etc/transitoclaro/so.env ]]; then
  install -m 0600 "$SO_DIR/config/so.env.example" /etc/transitoclaro/so.env
  echo "Configuração criada em /etc/transitoclaro/so.env (revise as variáveis antes de uso real)."
fi
carregar_configuracao
registrar INFO 'Início do provisionamento completo (Ubuntu VM).'
"$SCRIPT_DIR/01_provisionar_infra.sh"
"$SCRIPT_DIR/02_provisionar_aplicacao.sh"
"$SCRIPT_DIR/03_configurar_monitoramento.sh"
"$SCRIPT_DIR/04_verificar_ambiente.sh"
registrar INFO 'Provisionamento completo concluído. Execute 05_testar_falha.sh para evidenciar recuperação.'
