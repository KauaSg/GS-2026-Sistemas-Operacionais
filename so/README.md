# TransitoClaro — Sistemas Operacionais (Global Solution 2026.2)

**FIAP | Engenharia de Software | CitizenTech | Operating Systems**

> **Ambiente-alvo:** máquina virtual com **Ubuntu Server/Desktop 24.04 LTS**, acesso à internet, `sudo`, arquitetura compatível com o pacote `dotnet-sdk-10.0`. O projeto foi preparado para esse ambiente; a execução real na VM deve ser realizada pelo grupo antes da entrega.

## 1. Equipe

| Integrante | RM |
|---|---|
| Pietro Vitor Pezzente | 557283 |
| Eric Darakjian | 557082 |
| Kauã Soares Guimarães | 559044 |
| Enzo Mikael Sanches | 558887 |

## 2. Contexto CitizenTech

O **TransitoClaro** apoia passageiros que dependem de metrô, trem e BRT em São Paulo. O problema é a incerteza diante de atrasos, superlotação e falhas nas linhas. A API C# do grupo registra relatos colaborativos, consulta linhas/estações e apresenta um status resumido para orientar decisões de deslocamento.

**Público-alvo:** usuários de transporte público, especialmente estudantes e trabalhadores.

**ODS 11 — Cidades e Comunidades Sustentáveis:** o protótipo promove acesso mais transparente a informações sobre transporte urbano. O impacto esperado deve ser medido, não presumido.

**Integração entre disciplinas:** este módulo **SO** prepara o Linux, instala a API C# existente, monitora o ambiente, audita sua operação e demonstra tolerância a falhas. Ele **não substitui** o backend desenvolvido em C# e não cria um projeto CitizenTech paralelo.

**Backend esperado:** [`PietroVP0777/PietroVP0777-Gs_2026_Cs`](https://github.com/PietroVP0777/PietroVP0777-Gs_2026_Cs), pasta `src/TransitoClaro.Api`, com `.NET 10` e endpoint `GET /api/linhas`. Se o repositório estiver privado ou tiver mudado de nome, use a opção de código-fonte local descrita adiante.

## 3. Arquitetura da infraestrutura

```text
[VM Ubuntu 24.04 LTS]
     |
     +-- hostname, IPv4 (DHCP por padrão), DNS e roteamento
     |
     +-- /etc/transitoclaro/so.env         # configuração
     |
     +-- /opt/transitoclaro/current        # versão publicada da API
     |      +-- TransitoClaro.Api.dll
     |
     +-- systemd: transitoclaro-api.service
     |      +-- .NET 10 / ASP.NET Core (127.0.0.1:5000)
     |      +-- reinício automático em caso de falha
     |      +-- SQLite: /var/lib/transitoclaro/transitoclaro.db
     |
     +-- systemd: transitoclaro-monitor.service
     |      +-- CPU, memória e disco (/proc e df)
     |      +-- disponibilidade da API (GET /api/linhas)
     |      +-- alertas e logs a cada 15 segundos
     |
     +-- /var/log/transitoclaro/
            +-- provisionamento.log
            +-- monitoramento.log
            +-- alertas.log
            +-- teste_falha.log
```

**Segurança:** a API fica acessível somente dentro da própria VM (`127.0.0.1`) por padrão, pois o protótipo possui operações de escrita sem autenticação. Não exponha a API à internet. O serviço executa com usuário próprio (`transitoclaro`) e permissão de escrita apenas na pasta do banco de dados. Esse isolamento é básico e não substitui autenticação nem revisão de segurança.

## 4. Arquivos da entrega

| Arquivo | Função |
|---|---|
| `scripts/00_instalar_tudo.sh` | Orquestra o provisionamento completo |
| `scripts/01_provisionar_infra.sh` | Configura hostname, DNS, IP e registra estado da rede |
| `scripts/02_provisionar_aplicacao.sh` | Instala .NET 10, obtém o backend, publica, cria serviço e valida HTTP |
| `scripts/03_configurar_monitoramento.sh` | Instala o monitor e ativa no `systemd` |
| `scripts/04_verificar_ambiente.sh` | Confere rede, DNS, SDK, API, banco e serviços |
| `scripts/05_testar_falha.sh` | Mata controladamente o processo da API e testa reinício automático |
| `scripts/06_monitorar.sh` | Lê CPU/RAM/disco e gera alertas; monitora API |
| `scripts/07_coletar_evidencias.sh` | Salva saídas reais de rede, API, serviços e logs em TXT |
| `scripts/08_testar_falha_monitor.sh` | Simula falha no processo do monitor e comprova recuperação automática pelo systemd |
| `lib/comum.sh` | Funções de auditoria, validação e configuração |
| `config/so.env.example` | Variáveis de rede, instalação e limites de alerta |
| `config/*.service` | Unidades do `systemd` com `Restart=always` |
| `config/90-transitoclaro` | Política de rotação de logs |
| `testes/testes_estaticos.sh` | Verifica sintaxe Bash e presença dos arquivos |
| `ROTEIRO_VIDEO.md` | Passo a passo para o vídeo de até 7 minutos |
| `prompts.md` | Registro transparente da assistência de IA |

## 5. Pré-requisitos

- Máquina virtual **Ubuntu 24.04 LTS** com `systemd` (não execute em WSL sem `systemd`, contêiner comum ou Linux sem `apt`).
- Acesso como usuário com `sudo` e internet para `apt` e pacotes .NET.
- Código C# do **TransitoClaro** acessível pelo GitHub **ou** em uma pasta local da VM.
- Recomenda-se ao menos 2 vCPU, 4 GB de RAM e espaço livre para pacotes e build.
- Execute **somente em uma VM de testes**: os scripts alteram hostname e DNS e, se solicitado, podem alterar o IP.

## 6. Instalação passo a passo

### Passo 1 — colocar esta pasta no projeto

Copie a pasta `so/` deste pacote para a **raiz do repositório da equipe**, ao lado de `src/`, `tests/` e do README do C#. Na VM, abra um terminal na pasta-raiz do repositório.

### Passo 2 — criar e revisar configuração

```bash
sudo mkdir -p /etc/transitoclaro
sudo install -m 0600 so/config/so.env.example /etc/transitoclaro/so.env
sudo nano /etc/transitoclaro/so.env
```

**Opção A: GitHub acessível.** Deixe `APP_SOURCE_DIR=""` e ajuste `APP_REPO_URL` e `APP_REF` se a equipe renomeou o repositório.

**Opção B: código-fonte local (quando GitHub está privado/404).** Copie o projeto C# para, por exemplo, `/home/aluno/Gs_2026_Cs`, e altere:

```bash
APP_SOURCE_DIR="/home/aluno/Gs_2026_Cs"
```

A pasta definida precisa conter `src/TransitoClaro.Api/TransitoClaro.Api.csproj`. O script publica o backend a partir desse caminho. Se usar `APP_SOURCE_DIR`, não depende de clonar o GitHub.

### Passo 3 — provisionar tudo automaticamente

```bash
chmod +x so/scripts/*.sh so/testes/*.sh
sudo ./so/scripts/00_instalar_tudo.sh
```

Esse comando executa as etapas de rede, instalação de dependências, build/publish do backend, ativação dos serviços e verificação da API.

O SDK **.NET 10** é instalado via `sudo apt-get install dotnet-sdk-10.0`, utilizando os pacotes do Ubuntu 24.04, em linha com a documentação oficial da Microsoft.

### Passo 4 — verificar API e Swagger

Na própria VM, abra:

- API: `http://127.0.0.1:5000/api/linhas`
- Swagger: `http://127.0.0.1:5000/swagger`

No terminal:

```bash
curl -i http://127.0.0.1:5000/api/linhas
sudo systemctl status transitoclaro-api.service
sudo systemctl status transitoclaro-monitor.service
sudo ./so/scripts/04_verificar_ambiente.sh
```

Se a interface gráfica estiver somente no computador host, use a console da VM para `curl`, ou configure um túnel SSH para `127.0.0.1:5000`; não habilite exposição pública para a demonstração.

## 7. Infraestrutura de rede: IPv4, DNS e hostname

**Por padrão, o IPv4 permanece obtido por DHCP**, preservando a configuração existente da máquina virtual. O script registra o endereço, interface e rota utilizados. O hostname `transitoclaro-vm` é configurado de forma persistente, e o DNS é configurado com um drop-in do `systemd-resolved` em `/etc/systemd/resolved.conf.d/90-transitoclaro.conf`.

Comandos para demonstrar ao professor:

```bash
hostnamectl
ip -4 addr show
ip -4 route
resolvectl status
getent hosts github.com
```

### Alternativa: endereço IP fixo (opcional)

O script também suporta IP fixo, **somente se você estiver no console da VM**. Em `/etc/transitoclaro/so.env`:

```bash
USAR_IP_FIXO="sim"
INTERFACE_REDE="enp0s3"         # ajuste ao nome que aparece em ip -4 addr
IP_FIXO_CIDR="192.168.56.30/24" # EXEMPLO, não copie sem avaliar sua rede
GATEWAY_IPV4="192.168.56.1"     # EXEMPLO
```

Rode `sudo ./so/scripts/01_provisionar_infra.sh`. O script salva backup de `/etc/netplan/`, gera `/etc/netplan/99-transitoclaro.yaml` e aplica o IP. **Atenção: configuração de IP incorreta pode derrubar a conexão da VM.** Para a GS, o modo DHCP padrão é suficiente para mostrar provisionamento e registrar endereço/rotas, mas a configuração estática permite demonstrar a alternativa.

## 8. Monitoramento contínuo com alertas

O monitor calcula porcentagens de CPU a partir de duas leituras de `/proc/stat`, uso de RAM usando `MemAvailable` em `/proc/meminfo` e espaço em disco pelo `df`. Além disso, verifica o serviço e faz uma requisição HTTP à API.

Limites padrão em `/etc/transitoclaro/so.env`:

```bash
LIMITE_CPU="80"
LIMITE_RAM="80"
LIMITE_DISCO="85"
INTERVALO_MONITORAMENTO="15"
```

Para executar **uma medição manual**:

```bash
sudo ./so/scripts/06_monitorar.sh --once
```

Para demonstrar alertas **sem sobrecarregar a VM**, use:

```bash
sudo ./so/scripts/06_monitorar.sh --simular-alerta
sudo tail -n 20 /var/log/transitoclaro/alertas.log
```

Esse modo aplica limites de 0% somente à medição atual, evidenciando o mecanismo de alertas com segurança.

O serviço monitor continua executando mesmo que a API pare, e reinicia automaticamente se o processo do próprio monitor falhar:

```bash
systemctl is-enabled transitoclaro-monitor.service
systemctl show transitoclaro-monitor.service -p Restart
sudo journalctl -u transitoclaro-monitor -n 30 --no-pager
```

## 9. Teste de falha e recuperação

Na VM, após ter a API funcionando:

```bash
sudo ./so/scripts/05_testar_falha.sh
```

O teste faz o seguinte:

1. Verifica que a API está ativa e captura o PID original.
2. Encerra **somente** o processo da API, simulando uma falha (`SIGKILL`).
3. Aguarda o `systemd` iniciar um novo processo (`Restart=always`).
4. Confirma um **PID diferente** e HTTP bem-sucedido em `/api/linhas`.
5. Grava evidência em `/var/log/transitoclaro/teste_falha.log`.

Evidências adicionais:

```bash
sudo cat /var/log/transitoclaro/teste_falha.log
sudo journalctl -u transitoclaro-api -n 50 --no-pager
systemctl show transitoclaro-api.service -p Restart -p NRestarts
```

**Importante:** esse teste causa uma indisponibilidade proposital e deve ser executado somente na VM acadêmica.

### Teste complementar obrigatório para demonstrar a tolerância a falhas do monitor

O script `05_testar_falha.sh` testa a **API**. O professor também pede evidenciar
a recuperação do próprio **serviço de monitoramento**. Execute:

```bash
sudo ./so/scripts/08_testar_falha_monitor.sh
sudo cat /var/log/transitoclaro/teste_falha_monitor.log
sudo journalctl -u transitoclaro-monitor --no-pager -n 30
```

Este script envia `SIGKILL` apenas ao processo principal do monitor e verifica
se o `systemd` iniciou um novo PID e se novos logs foram gravados.
**Não use `systemctl stop transitoclaro-monitor` para testar autorecuperação:**
a parada administrativa voluntária é intencionalmente respeitada pelo `systemd`.

Para demonstrar recuperação após **reinício da VM**, use `sudo reboot`, entre
novamente e execute:

```bash
systemctl is-enabled transitoclaro-api transitoclaro-monitor
systemctl is-active transitoclaro-api transitoclaro-monitor
curl -i http://127.0.0.1:5000/api/linhas
```

Registre capturas das saídas reais e coloque-as em `so/evidencias/`.

## 10. Logs de auditoria e acompanhamento

```bash
sudo tail -n 40 /var/log/transitoclaro/provisionamento.log
sudo tail -n 40 /var/log/transitoclaro/monitoramento.log
sudo tail -n 40 /var/log/transitoclaro/alertas.log
sudo tail -n 40 /var/log/transitoclaro/teste_falha.log
sudo journalctl -u transitoclaro-api -n 40 --no-pager
sudo journalctl -u transitoclaro-monitor -n 40 --no-pager
```

Os logs são datados, classificados por nível (INFO/ALERTA/ERRO), gravados em arquivos e enviados ao journal/syslog quando disponível. A rotação dos arquivos é configurada com `logrotate`.

## 11. Rubrica de 10 pontos da disciplina

| Critério do PDF (p. 37) | Pontos | Evidência prevista |
|---|---:|---|
| Script de rede, DNS e IP | 2,0 | `01_provisionar_infra.sh`, `hostnamectl`, `ip addr`, `resolvectl` |
| Script de aplicação | 2,0 | `02_provisionar_aplicacao.sh`, `dotnet publish`, `systemctl`, `curl` |
| Alertas CPU/RAM/disco | 2,0 | `06_monitorar.sh`, `monitoramento.log`, `alertas.log` |
| Monitor como serviço tolerante a falhas | 1,0 | `transitoclaro-monitor.service` com `Restart=always` |
| Auditoria e logs | 1,0 | `/var/log/transitoclaro/*.log` e `journalctl` |
| Funcionamento completo | 2,0 | API respondendo, banco SQLite existente, teste de falha recuperado |

**Atenção:** esta tabela indica como demonstrar os requisitos, **não garante a nota**. É necessário executar tudo na VM, registrar prints reais e gravar o vídeo.

## 12. Evidências reais e vídeo (obrigatórios)

Depois de instalar, monitorar e testar falha, execute na raiz do repositório:

```bash
sudo ./so/scripts/07_coletar_evidencias.sh
```

Isso preenche `so/evidencias/execucao/` com relatórios **gerados na sua própria VM** (TXT). Revise os arquivos antes de publicar: mesmo relatórios de rede podem revelar endereços internos. Os prints e o vídeo ainda precisam ser feitos pelo grupo.


Salve **prints reais** em `so/evidencias/`, sem inventar saídas. Sugestões:

- `01_rede.png`: `hostnamectl`, `ip -4 addr`, `resolvectl status`.
- `02_dotnet.png`: `dotnet --list-sdks` e saída do `dotnet publish`.
- `03_api.png`: Swagger ou `/api/linhas` respondendo.
- `04_servicos.png`: ambos os serviços ativos no `systemctl`.
- `05_monitoramento.png`: indicadores e alertas.
- `06_teste_falha.png`: PID anterior e novo PID, logs e `journalctl`.

O professor exige **vídeo demonstrativo de até 7 minutos**. Veja `ROTEIRO_VIDEO.md`. Suba o vídeo em local acessível e inclua o link aqui após gravar:

**Vídeo:** `ADICIONAR_LINK_REAL_DO_VIDEO`

**Repositório final com SO:** `ADICIONAR_LINK_REAL_DO_REPOSITORIO`

## 13. Diagnóstico de problemas

- **`git clone` falha / 404:** atualize `APP_REPO_URL` ou configure `APP_SOURCE_DIR` apontando para uma cópia local real da raiz do C#.
- **`dotnet-sdk-10.0` não encontrado:** confirme Ubuntu 24.04, conexão e repositórios `apt` ativados; não force a instalação em outra versão sem validar.
- **`dotnet publish` falha:** veja a saída do terminal, os pacotes NuGet e a versão do projeto C#. O script não corrige erros do backend automaticamente.
- **API não inicia:** `sudo journalctl -u transitoclaro-api -n 80 --no-pager`.
- **Porta 5000 ocupada:** altere `APP_PORT` no `so.env`, reprovisione o app e reinstale o monitor. A configuração não é aplicada apenas reiniciando.
- **Banco não é criado:** verifique o `app.env`, permissões de `/var/lib/transitoclaro` e exceptions da aplicação no journal.
- **Monitor não inicia:** `sudo journalctl -u transitoclaro-monitor -n 80 --no-pager`.
- **Alterações em scripts depois da instalação:** rode novamente `sudo ./so/scripts/03_configurar_monitoramento.sh` para copiar a versão nova ao diretório usado pelo serviço.

## 14. Teste de sintaxe antes de subir

```bash
bash so/testes/testes_estaticos.sh
```

A verificação de sintaxe **não substitui** a prova prática de provisionamento, serviços, banco e recuperação na VM.

## 15. Fontes e referências

- Enunciado FIAP Global Solution CitizenTech 2026.2, pp. 35–37, Operating Systems.
- Microsoft Learn: [Instalar .NET no Ubuntu](https://learn.microsoft.com/pt-br/dotnet/core/install/linux-ubuntu-install).
- Documentação `systemd`: `man systemd.service`, `man systemd.unit`, `man journalctl` (na própria VM).
- Backend da equipe: https://github.com/PietroVP0777/PietroVP0777-Gs_2026_Cs (confirmar acessibilidade).

## Registro da validação de 19/11/2026

O integrante executou os scripts no Ubuntu VirtualBox: API HTTP 200 e dois serviços ativos. Os testes SIGKILL registraram recuperação da API (PID 5003 → 6043) e do monitor (PID 5343 → 6133). Os alertas foram testados com limites artificialmente reduzidos. Consulte [evidencias/registro_de_validacao_vm.md](evidencias/registro_de_validacao_vm.md). Arquivos TXT originais e capturas reais ainda devem ser anexados pelo grupo.
