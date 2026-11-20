# TransitoClaro — Global Solution 2026.2 | Sistemas Operacionais

**FIAP · Engenharia de Software · CitizenTech**

## Integrantes
- Pietro Vitor Pezzente — RM 557283
- Eric Darakjian — RM 557082
- Kauã Soares Guimarães — RM 559044
- Enzo Mikael Sanches — RM 558887

## Proposta
Infraestrutura Linux automatizada para hospedar a API C# do TransitoClaro, solução cidadã voltada à mobilidade urbana (ODS 11).

O projeto contempla configuração de hostname, IPv4/DHCP, DNS, instalação do .NET 10, publicação da API, serviço `systemd`, monitoramento de CPU/RAM/disco, logs de auditoria e testes de falha com recuperação automática.

**Documentação detalhada:** [so/README.md](so/README.md).

**Backend C#:** https://github.com/PietroVP0777/PietroVP0777-Gs_2026_Cs

## Execução no Ubuntu 24.04
```bash
chmod +x so/scripts/*.sh so/testes/*.sh
sudo ./so/scripts/00_instalar_tudo.sh
sudo ./so/scripts/05_testar_falha.sh
sudo ./so/scripts/08_testar_falha_monitor.sh
sudo ./so/scripts/06_monitorar.sh --simular-alerta
sudo ./so/scripts/07_coletar_evidencias.sh
```

## Validação real na VM — 19/11/2026
O integrante executou o provisionamento no Ubuntu VirtualBox e apresentou logs mostrando API C# com HTTP 200, banco SQLite, os dois serviços `systemd` ativos, alarmes de CPU/RAM/disco e recuperação automática da API (PID 5003 → 6043) e do monitor (PID 5343 → 6133). Os relatórios TXT de auditoria devem ser anexados conforme `so/evidencias/README.md`.

**Vídeo de demonstração:** incluir link antes da entrega no Teams. Os resultados de execução referem-se à VM do grupo, não a este repositório.
