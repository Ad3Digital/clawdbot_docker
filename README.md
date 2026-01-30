# Clawdbot Docker - Guia Completo de Instalação e Uso

## 📋 Sumário
- [O que é?](#o-que-é)
- [Pré-requisitos](#pré-requisitos)
- [Instalação](#instalação)
- [Primeira Execução](#primeira-execução)
- [Uso Diário](#uso-diário)
- [Solução de Problemas](#solução-de-problemas)
- [Estrutura do Projeto](#estrutura-do-projeto)

---

## 🤖 O que é?

O **Clawdbot** é um assistente de código alimentado por IA (Gemini, Claude, GPT, etc.) que roda localmente em um container Docker. Ele fornece uma interface web para interagir com modelos de linguagem, executar código, e muito mais.

**Componentes:**
- **Clawdbot (Docker)**: O assistente principal que roda em container
- **CLIProxyAPI**: Proxy local que permite acesso aos modelos de IA (Gemini CLI, Claude Code, etc.)

---

## ✅ Pré-requisitos

Antes de começar, você precisa ter instalado:

- **Docker Desktop** (Windows/Mac) ou Docker Engine (Linux)
- **Git** (para clonar o repositório)
- **Windows PowerShell** ou **CMD** (Windows) ou **Bash** (Linux/Mac)

---

## 📥 Instalação

### 1. Clone o repositório

```bash
git clone https://github.com/Ad3Digital/clawdbot_docker
cd clawdbot_docker
```

### 2. Verifique a estrutura

O projeto já vem com:
- ✅ `docker-compose.yml` - Configuração do container
- ✅ `.env.example` - Template de variáveis de ambiente
- ✅ `.gitignore` - Protege dados sensíveis
- ✅ `data/` - Persistência local (não versionado)

Você vai baixar o CLIProxyAPI separadamente e extrair em `CLIProxyAPI/` (não versionado).

### 3. Configure o arquivo `.env`

Copie o template e edite:

**Windows (PowerShell/CMD):**
```cmd
copy .env.example .env
```

**Linux/Mac (Bash):**
```bash
cp .env.example .env
```

No `.env`, defina:
- `CLAWDBOT_GATEWAY_TOKEN` (obrigatório)
- `CLAWDBOT_TELEGRAM_TOKEN` (opcional, se for usar Telegram)

> **Importante:** não versionamos o `.env`. Ele fica só na sua máquina.

---

## 🚀 Primeira Execução

### Passo 1: Baixar e configurar o CLIProxyAPI

1. Baixe a versão do CLIProxyAPI para o seu sistema:
   https://github.com/router-for-me/CLIProxyAPI/releases
2. Extraia o conteúdo para a pasta `clawdbot_docker/CLIProxyAPI/`
3. Crie o arquivo `CLIProxyAPI/config.yaml` com:

```yaml
host: ""
port: 8317
remote-management:
  allow-remote: false
  secret-key: ""
auth-dir: "~/.cli-proxy-api"
debug: false
```

> `host: ""` é importante para permitir acesso do container via `host.docker.internal`.

### Passo 2: Fazer Login no Gemini CLI (obrigatório apenas na primeira vez)

O CLIProxyAPI precisa de autenticação para acessar os modelos de IA.

**No Windows (PowerShell):**
```powershell
cd CLIProxyAPI
.\cli-proxy-api.exe --login
```

**No Linux/Mac (Bash):**
```bash
cd CLIProxyAPI
./cli-proxy-api --login
```

**O que vai acontecer:**
1. O navegador vai abrir automaticamente
2. Faça login com sua conta Google
3. Escolha os projetos do Google Cloud que deseja usar (digite `ALL` para usar todos)
4. A autenticação será salva em `CLIProxyAPI/.cli-proxy-api/`

> **💡 Dica:** Você pode fazer login em múltiplos providers:
> - Gemini: `--login`
> - Claude: `--claude-login`
> - Codex: `--codex-login`
> - Qwen: `--qwen-login`

---

### Passo 3: Iniciar o Ambiente

**Opção A: Usando o script automatizado (recomendado)**

No Windows, execute:
```cmd
iniciar-clawdbot.bat
```

Escolha a opção **[5] Apenas iniciar servidor** (se já fez login antes).

**Opção B: Manual**

1. **Inicie o CLIProxyAPI** (deixe rodando em um terminal):
   ```powershell
   cd CLIProxyAPI
   .\cli-proxy-api.exe
   ```

2. **Inicie o Docker** (em outro terminal):
   ```bash
   docker compose up -d
   ```

---

### Passo 4: Aprovar o Dispositivo (apenas na primeira vez)

Quando você acessar a interface web pela primeira vez, verá um erro de **"pairing required"**. Isso é normal!

**Para aprovar seu navegador:**

1. Acesse a URL (vai dar erro, mas é esperado):
   ```
   http://localhost:18789
   ```

2. No terminal, execute:
   ```bash
   docker exec clawdbot_sandbox clawdbot devices list
   ```

3. Você verá algo assim:
   ```
   Pending (1)
   ┌──────────────────────────────────────┬────────────────────────────────────┐
   │ Request                              │ Device                             │
   ├──────────────────────────────────────┼────────────────────────────────────┤
   │ 53ae482a-2669-48d0-9fce-5384282dfc15 │ 18cc78db159...                     │
   └──────────────────────────────────────┴────────────────────────────────────┘
   ```

4. Copie o **Request ID** (primeira coluna) e aprove:
   ```bash
   docker exec clawdbot_sandbox clawdbot devices approve 53ae482a-2669-48d0-9fce-5384282dfc15
   ```
   *(substitua pelo seu Request ID)*

5. **Recarregue a página** no navegador (Ctrl+Shift+R)

Agora a interface deve estar **verde** (conectada)! ✅

---

### Passo 5: Configurar canais (opcional)

#### Telegram

1. Crie um bot no BotFather e copie o token.
2. Defina `CLAWDBOT_TELEGRAM_TOKEN` no `.env`.
3. Adicione o canal:
```bash
docker exec clawdbot_sandbox clawdbot channels add --channel telegram --token "SEU_TOKEN_TELEGRAM"
```

#### WhatsApp

1. Adicione o canal:
```bash
docker exec clawdbot_sandbox clawdbot channels add --channel whatsapp
```
2. Faça login e escaneie o QR Code:
```bash
docker exec clawdbot_sandbox clawdbot channels login --channel whatsapp
```

#### Permitir DMs de qualquer pessoa (opcional)

Edite `data/clawdbot/clawdbot.json` e defina `dmPolicy: "open"` e `allowFrom: ["*"]` dentro do canal desejado (telegram/whatsapp).

---

## 💬 Uso Diário

### Para usar o Clawdbot depois da primeira configuração:

1. **Inicie o CLIProxyAPI:**
   ```powershell
   cd CLIProxyAPI
   .\cli-proxy-api.exe
   ```
   *(Deixe esta janela aberta)*

2. **Inicie o Docker** (se não estiver rodando):
   ```bash
   docker compose up -d
   ```

3. **Acesse a interface:**
   ```
   http://localhost:18789/?token=SEU_TOKEN_DO_ENV
   ```

> Se você remover `CLAWDBOT_GATEWAY_TOKEN`, o acesso é sem token.

4. **Comece a usar!** 🎉

---

## 🛠️ Solução de Problemas

### ❌ Erro: "disconnected (1008): pairing required"

**Causa:** Seu navegador ainda não foi aprovado.

**Solução:**
```bash
docker exec clawdbot_sandbox clawdbot devices list
docker exec clawdbot_sandbox clawdbot devices approve <REQUEST_ID>
```

---

### ❌ Erro: "Health Offline" (bolinha vermelha no canto)

**Causa:** O CLIProxyAPI não está rodando ou não consegue se conectar.

**Solução:**
1. Verifique se o CLIProxyAPI está rodando:
   ```bash
   curl http://localhost:8317/v1/models
   ```
2. Se não retornar nada, inicie o CLIProxyAPI:
   ```powershell
   cd CLIProxyAPI
   .\cli-proxy-api.exe
   ```

---

### ❌ Container não inicia ou fica crashando

**Solução:**
```bash
# Ver logs
docker logs clawdbot_sandbox

# Reiniciar tudo
docker compose down
docker compose up -d
```

---

### ❌ Erro: "connect failed" ou "code=4008"

**Causa:** O CLIProxyAPI parou ou perdeu autenticação.

**Solução:**
1. Reinicie o CLIProxyAPI
2. Se necessário, faça login novamente:
   ```powershell
   .\cli-proxy-api.exe --login
   ```

---

## 📁 Estrutura do Projeto

```
clawdbot_docker/
├── docker-compose.yml          # Configuração do Docker
├── Dockerfile                   # Imagem do container
├── .env.example                 # Template de variáveis de ambiente
├── .env                         # Local (não versionado)
├── .gitignore                   # Arquivos ignorados pelo Git
├── iniciar-clawdbot.bat        # Script de inicialização (Windows)
├── README.md                    # Este arquivo
├── CLIProxyAPI/                # Download local do proxy (não versionado)
│   ├── cli-proxy-api.exe       # Executável do proxy
│   └── config.yaml             # Configuração do proxy
└── data/                       # Dados persistentes (não versionados)
    ├── clawdbot/               # Configuração do Clawdbot
    │   └── clawdbot.json       # Config principal
    ├── gemini/                 # Credenciais do Gemini CLI
    └── workspace/              # Workspace do Clawdbot
        ├── boot.md             # Instruções de sistema
        └── canvas/             # Interface HTML customizada
```

---

## 🔒 Segurança e Privacidade

### Dados Sensíveis (não versionados no Git)

O `.gitignore` está configurado para **NÃO** versionar:
- `data/` - Todos os dados persistentes
- `CLIProxyAPI/` - Download local do proxy e credenciais
- `.env` - Variáveis de ambiente sensíveis

### Token de Autenticação

O token padrão está em `.env`:
```env
CLAWDBOT_GATEWAY_TOKEN=seu-token-seguro-aqui
```

**⚠️ IMPORTANTE:** Se você for expor o gateway para internet, **gere um novo token**:
```bash
# Linux/Mac
openssl rand -hex 24

# Windows PowerShell
-join ((1..24) | ForEach-Object { '{0:x2}' -f (Get-Random -Maximum 256) })
```

---

## 🔄 Persistência de Dados

Todos os dados são salvos localmente em `data/`:
- **Configurações do Clawdbot**: `data/clawdbot/`
- **Credenciais do Gemini**: `data/gemini/`
- **Workspace**: `data/workspace/`

Mesmo se você **deletar o container**, os dados permanecem!

```bash
# Para resetar TUDO (cuidado!)
docker compose down
rm -rf data/
docker compose up -d
# (e refaça o pareamento)
```

---

## 🌐 Modelos Disponíveis

O CLIProxyAPI suporta múltiplos modelos:

- **Gemini** (via Gemini CLI)
  - `gemini-3-pro-preview`
  - `gemini-3-flash-preview`
  - `gemini-2.5-pro`
  - `gemini-2.5-flash`

- **Claude** (via Claude Code)
  - `claude-sonnet-4-5-20250929`
  - `claude-opus-4-5-20251101`
  - `claude-haiku-4-5-20251001`

- **OpenAI/Codex** (via Codex CLI)
  - `gpt-5-codex`
  - `gpt-5.2`

- **Qwen** (via Qwen CLI)
  - (modelos Qwen disponíveis)

---

## 📞 Suporte

Se você encontrar problemas:

1. **Verifique os logs:**
   ```bash
   docker logs clawdbot_sandbox --tail 50
   ```

2. **Verifique o status do gateway:**
   ```bash
   docker exec clawdbot_sandbox clawdbot gateway status
   ```

3. **Teste o CLIProxyAPI:**
   ```bash
   curl http://localhost:8317/v1/models
   ```

4. **Abra uma issue no GitHub:**
   https://github.com/Ad3Digital/clawdbot_docker/issues

---

## 📝 Licença

Este projeto é fornecido como está, sem garantias. Use por sua conta e risco.

---

## 🙏 Créditos

- **Clawdbot**: https://clawd.bot
- **CLIProxyAPI**: https://github.com/router-for-me/CLIProxyAPI

---

**Feito com ❤️ por Ad3Digital**
