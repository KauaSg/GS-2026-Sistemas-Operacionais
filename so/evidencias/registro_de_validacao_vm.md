# Registro de validação na VM — transcrição fornecida pelo integrante

**Origem:** saída de terminal compartilhada no chat pelo integrante Kauã em 19/11/2026, 22h24–22h28 (America/Sao_Paulo). **Não é captura de tela nem execução feita pela IA.** Dados de execução foram relatados e exibidos pelo operador da VM; os arquivos TXT originais obtidos por `07_coletar_evidencias.sh` devem ser publicados adicionalmente.

## Provisionamento do Ubuntu VirtualBox

- Hostname: `transitoclaro-vm`
- IPv4 da VM: `10.0.2.15/24` (DHCP), gateway `10.0.2.2`
- DNS configurado: `1.1.1.1` e `8.8.8.8` (global; interface usa `192.168.10.1`)
- SDK .NET 10: `10.0.115`
- Build: `TransitoClaro.Api net10.0 êxito(s) com 1 aviso(s)`
- API publicada sob `/opt/transitoclaro/releases/...` e servida na porta 5000
- Serviço `transitoclaro-api.service`: `active (running)`; inicial PID `5003`
- Serviço `transitoclaro-monitor.service`: `active (running)`; inicial PID `5343`
- `GET http://127.0.0.1:5000/api/linhas`: HTTP 200, listou 6 linhas
- Banco SQLite: `/var/lib/transitoclaro/transitoclaro.db`

## Teste 1 — falha da API (real)

```
2026-11-19T22:28:19-03:00 | INÍCIO | serviço ativo; PID=5003
2026-11-19T22:28:19-03:00 | FALHA SIMULADA | processo 5003 encerrado com SIGKILL
2026-11-19T22:28:26-03:00 | RECUPERAÇÃO OK | novo PID=6043; HTTP 200 no endpoint
2026-11-19T22:28:26-03:00 [INFO] [05_testar_falha.sh] Teste concluído: PID 5003 -> 6043; reinício automático comprovado.
```

## Teste 2 — falha do monitor (real)

```
2026-11-19T22:28:29-03:00 | INÍCIO: monitor ativo; PID=5343; Restart=always
2026-11-19T22:28:29-03:00 | FALHA SIMULADA: encerrando somente o processo principal do monitor com SIGKILL.
2026-11-19T22:28:35-03:00 | RECUPERAÇÃO OK: novo PID=6133; o monitor voltou a gerar logs.
2026-11-19T22:28:35-03:00 [INFO] [08_testar_falha_monitor.sh] Teste de falha do monitor concluído: PID 5343 -> 6133.
```

## Teste 3 — alertas controlados (real)

```
2026-11-19T22:28:38-03:00 [INFO] [monitor] CPU=52% RAM=56% DISCO=31% | limites CPU=0 RAM=0 DISCO=0
2026-11-19T22:28:38-03:00 [ALERTA] [monitor] Uso de CPU acima do limite: 52% (limite 0%)
2026-11-19T22:28:38-03:00 [ALERTA] [monitor] Uso de memória acima do limite: 56% (limite 0%)
2026-11-19T22:28:38-03:00 [ALERTA] [monitor] Uso de disco acima do limite: 31% (limite 0%)
2026-11-19T22:28:38-03:00 [INFO] [monitor] ESTADO=API_ATIVA_HEALTH_OK
```

**Nota:** os limiares 0% foram intencionalmente usados para disparar os alertas de demonstração. Não indicam consumo excessivo real do servidor.

## Coleta automatizada

```
2026-11-19T22:28:44-03:00 [INFO] [07_coletar_evidencias.sh] Evidências coletadas em /home/kaua/Downloads/so/evidencias/execucao.
01_rede.txt
02_aplicacao.txt
03_systemd.txt
04_logs.txt
05_journal.txt

$ systemctl is-active transitoclaro-api transitoclaro-monitor
active
active
```

**Pendente:** anexar os cinco arquivos TXT originais e capturas da VM para permitir auditoria direta dos registros.
