# Conferência dos critérios — situação em 19/11/2026

## Confirmado por execução na VM do integrante
- `00_instalar_tudo.sh` provisionou rede, hostname, DNS, .NET 10, API C#, banco SQLite e serviços.
- `GET /api/linhas` respondeu HTTP 200 com 6 linhas do TransitoClaro.
- Os serviços `transitoclaro-api` e `transitoclaro-monitor` constaram como ativos e habilitados no systemd.
- `06_monitorar.sh` registrou CPU, RAM, disco e API; o modo de limiares reduzidos gerou alertas.
- `05_testar_falha.sh` comprovou recuperação automática da API, PID 5003 → 6043.
- `08_testar_falha_monitor.sh` comprovou recuperação automática do monitor, PID 5343 → 6133.
- `07_coletar_evidencias.sh` gerou cinco arquivos TXT dentro da VM.
- Transcrição da saída reportada em `evidencias/registro_de_validacao_vm.md`.

## Pendente ou ainda não comprovado
- Anexar ao GitHub os cinco arquivos TXT originais gerados na VM e capturas da tela.
- Testar persistência após reboot da VM, caso deseje demonstrar autostart no vídeo.
- Gravar e publicar o vídeo de até 7 minutos com cenas reais de execução, sem simular saídas.

**Atenção:** existe aviso de segurança NU1903 sobre pacote SQLite transitivo; planejar atualização após a entrega, sem alterar o estado validado da VM durante a demonstração.
