#!/usr/bin/env bash
set -Eeuo pipefail
SO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
echo 'Testando a sintaxe Bash dos scripts entregues...'
for arq in "$SO_ROOT"/scripts/*.sh "$SO_ROOT"/lib/*.sh; do
  bash -n "$arq"
  printf 'OK  %s\n' "${arq#"$SO_ROOT"/}"
done
[[ -f "$SO_ROOT/config/transitoclaro-api.service" ]]
[[ -f "$SO_ROOT/config/transitoclaro-monitor.service" ]]
[[ -f "$SO_ROOT/config/so.env.example" ]]
[[ -f "$SO_ROOT/README.md" ]]
echo 'Arquivos principais presentes. Não substitui execução real na VM Ubuntu.'
