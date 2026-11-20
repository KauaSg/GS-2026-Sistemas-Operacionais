# Roteiro de demonstração — Sistemas Operacionais | TransitoClaro

**Tempo máximo exigido no enunciado: 7 minutos.** Grave a tela da VM Ubuntu 24.04 LTS e narre os resultados **reais**. Não simule prints nem afirme que funcionou antes de executar.

## 0:00–0:40 | Contexto

> "Somos a equipe do TransitoClaro, uma CitizenTech que informa passageiros sobre ocorrências no metrô, trem e BRT. Em Sistemas Operacionais, construímos uma infraestrutura Linux automatizada para disponibilizar e monitorar a API C# do nosso projeto."

Mostre a estrutura `so/` e o README.

## 0:40–1:45 | Provisionamento de infraestrutura (2 pontos)

Mostre trechos de `01_provisionar_infra.sh`, além da execução ou logs reais. Comandos:

```bash
hostnamectl --static
ip -4 addr show
ip -4 route
resolvectl status
sudo tail -n 15 /var/log/transitoclaro/provisionamento.log
```

Explique DNS persistente e o IP atual obtido por DHCP. Mostre que há opção documentada de IP fixo, mas não altere a rede apenas para gravar.

## 1:45–3:00 | Provisionamento da aplicação (2 pontos)

Mostre `02_provisionar_aplicacao.sh`, `dotnet --list-sdks`, `systemctl status transitoclaro-api.service`, a resposta de `/api/linhas` e o banco SQLite. O script instala dependências, publica a API, configura variáveis e cria a unidade `systemd`.

```bash
dotnet --list-sdks
curl -i http://127.0.0.1:5000/api/linhas
sudo systemctl status transitoclaro-api.service
sudo ls -lh /var/lib/transitoclaro/transitoclaro.db
```

## 3:00–4:20 | Monitoramento e alertas (3 pontos)

Mostre a unidade `transitoclaro-monitor.service`, `Restart=always`, CPU, RAM, disco e logs.

```bash
sudo systemctl status transitoclaro-monitor.service
sudo ./so/scripts/06_monitorar.sh --once
sudo ./so/scripts/06_monitorar.sh --simular-alerta
sudo tail -n 20 /var/log/transitoclaro/alertas.log
```

Explique que `--simular-alerta` testa a regra de limite com 0% sem sobrecarregar a máquina.

## 4:20–5:15 | Logs de auditoria (1 ponto)

```bash
sudo tail -n 20 /var/log/transitoclaro/provisionamento.log
sudo tail -n 20 /var/log/transitoclaro/monitoramento.log
sudo journalctl -u transitoclaro-api -n 20 --no-pager
```

Destaque timestamps, eventos INFO/ALERTA/ERRO e logs de serviço.

## 5:15–6:30 | Teste de falha e recuperação (2 pontos)

**Somente na VM de testes:**

```bash
sudo ./so/scripts/05_testar_falha.sh
sudo cat /var/log/transitoclaro/teste_falha.log
```

Mostre que o processo da API foi encerrado, o systemd iniciou um **novo PID** e o endpoint voltou a responder. Se der erro, corrija antes de gravar.

## 6:30–6:50 | Encerramento

> "Demonstramos provisionamento automatizado, serviço da aplicação, auditoria, monitoramento de recursos, alertas e recuperação após falha. Essa infraestrutura sustenta o TransitoClaro e integra Sistemas Operacionais à CitizenTech da equipe."

**Antes de publicar:** inclua o link real do vídeo no README. Confira duração, legibilidade do terminal, áudio, ausência de dados sensíveis e que o link possa ser aberto pelo professor.


## Complemento: falha do serviço de monitoramento (demonstração real)

Execute `sudo ./so/scripts/08_testar_falha_monitor.sh` e mostre os registros
`/var/log/transitoclaro/teste_falha_monitor.log`. Mostre que o PID mudou
e o monitor voltou a gravar. Não substitua por uma parada administrativa.
