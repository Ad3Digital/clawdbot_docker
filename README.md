# Clawdbot Docker - Assistente IA com Multi-Modelos

## 🤖 O que é?

O **Clawdbot Docker** é um assistente de IA completo que roda em container Docker, integrando múltiplos modelos de linguagem (Claude, Gemini, GPT/Codex) através do CLIProxyAPI.

**Stack:**
- 🐳 **Docker** - Container isolado com ambiente completo
- 🔌 **CLIProxyAPI** - Proxy OAuth para Claude Code, Gemini, Codex
- 🏛️ **Clawdbot Gateway** - Interface web e gerenciamento de conversas
- 🔄 **Watchdog Interno** - Processamento automático de restarts e ops

---

## ✅ Pré-requisitos

- **Docker Desktop** (Windows/Mac) ou Docker Engine (Linux)
- **Git** para clonar o repositório
- Contas nos provedores de IA que deseja usar (Claude, Gemini, OpenAI)

---

## 📥 Instalação

### 1. Clone o repositório

```bash
git clone <url-do-repositorio>
cd clawdbot_docker
```

### 2. Configure as variáveis de ambiente

Copie o arquivo de exemplo:

```bash
# Windows
copy .env.example .env

# Linux/Mac
cp .env.example .env
```

Edite o `.env` e configure:

```env
CLAWDBOT_GATEWAY_TOKEN=seu-token-aqui
CLAWDBOT_TELEGRAM_TOKEN=seu-token-telegram  # Opcional
```

### 3. Autentique os CLIs OAuth (Windows)

Para usar Claude, Gemini ou Codex, você precisa fazer login **uma única vez** no Windows:

**Claude Code:**
```powershell
irm https://claude.ai/install.ps1 | iex
claude auth login
```

**Gemini:**
```powershell
npm install -g @google/gemini-cli
gemini auth login
```

**OpenAI/Codex:**
```powershell
npm install -g openai
openai login
```

Os tokens serão salvos automaticamente em `~/.cli-proxy-api/` e sincronizados com o Docker via volumes.

### 4. Build e start

```bash
# Build da imagem (primeira vez ou após mudanças)
docker compose build

# Iniciar o container
docker compose up -d
```

### 5. Acesse a interface

Abra no navegador:
```
http://localhost:18789
```

---

## 🚀 Uso Diário

### Iniciar

```bash
cd clawdbot_docker
docker compose up -d
```

### Parar

```bash
docker compose down
```

### Ver logs

```bash
docker logs clawdbot_sandbox -f
```

### Reiniciar

```bash
docker compose restart
```

---

## 🔧 Configuração Avançada

### Modelos Disponíveis

O setup atual suporta:

**Claude (via CLIProxyAPI OAuth):**
- `cliproxy/claude-sonnet-4-5-20250929` (padrão)
- `cliproxy/claude-opus-4-5-20251101`
- `cliproxy/claude-haiku-4-5-20251001`

**Gemini (via CLIProxyAPI OAuth):**
- `cliproxy/gemini-3-flash-preview`
- `cliproxy/gemini-3-pro-preview`
- `cliproxy/gemini-2.5-pro`

**OpenAI/Codex (via CLIProxyAPI OAuth):**
- `cliproxy/gpt-5.2`
- `cliproxy/gpt-5.1`
- `cliproxy/gpt-5-codex`

### Configurar Telegram

1. Crie um bot no [@BotFather](https://t.me/BotFather)
2. Adicione o token no `.env`:
   ```env
   CLAWDBOT_TELEGRAM_TOKEN=123456789:ABCdefGHIjklMNOpqrsTUVwxyz
   ```
3. Reinicie o container:
   ```bash
   docker compose restart
   ```

### Habilitar Restart Automático

O restart já está habilitado por padrão. O bot pode reiniciar sozinho quando solicitado via interface ou skills.

---

## 🛠️ Solução de Problemas

### ❌ Mensagens ficam carregando infinito

**Causa:** Arquivos de sessão travados (lock files)

**Solução:**
```bash
docker exec clawdbot_sandbox sh -c "rm -f /root/.clawdbot/agents/main/sessions/*.lock"
docker compose restart
```

### ❌ Erro 401 Unauthorized

**Causa:** Tokens OAuth expirados

**Solução:**
1. Faça login novamente no Windows (veja seção "Autentique os CLIs OAuth")
2. Reinicie o container:
   ```bash
   docker compose restart
   ```

### ❌ CLIProxyAPI não detecta tokens

**Causa:** Tokens não foram copiados para a pasta correta

**Solução:**
```bash
# Verificar se tokens existem no Windows
ls C:\Users\seu-usuario\.cli-proxy-api\

# Copiar manualmente se necessário
cp C:\Users\seu-usuario\.cli-proxy-api\*.json ./data/cli-proxy-api/
docker compose restart
```

### ❌ Docker trava ao subir container

**Causa:** Problema temporário do Docker Desktop no Windows

**Solução:**
1. Reinicie o computador
2. Teste se Docker funciona: `docker run --rm hello-world`
3. Suba o container: `docker compose up -d`

---

## 📁 Estrutura do Projeto

```
clawdbot_docker/
├── docker-compose.yml          # Configuração do container
├── Dockerfile                  # Imagem Docker personalizada
├── entrypoint.sh              # Script de inicialização
├── watchdog.sh                # Watchdog interno para ops-requests
├── .env                       # Variáveis de ambiente (não versionado)
├── .env.example               # Template de variáveis
├── CLIProxyAPI/               # Configuração do proxy
│   └── config.yaml            # Config do CLIProxyAPI
└── data/                      # Dados persistentes (não versionados)
    ├── clawdbot/              # Configuração do Clawdbot
    │   └── clawdbot.json      # Config principal do gateway
    ├── cli-proxy-api/         # Tokens OAuth sincronizados
    │   ├── claude-*.json      # Tokens do Claude
    │   ├── gemini-*.json      # Tokens do Gemini
    │   └── codex-*.json       # Tokens do Codex
    ├── gemini/                # Credenciais extras do Gemini
    └── workspace/             # Workspace do bot
        ├── boot.md            # Instruções de sistema
        ├── skills/            # Skills personalizadas
        └── ops-requests/      # Fila de operações (restart, etc.)
```

---

## 🔒 Segurança

### Arquivos não versionados (`.gitignore`)

- `data/` - Todos os dados sensíveis
- `.env` - Variáveis de ambiente com tokens

### Token de Gateway

Altere o token padrão em `.env` se for expor publicamente:

```bash
# Gerar token seguro (Windows PowerShell)
-join ((1..32) | ForEach-Object { '{0:x2}' -f (Get-Random -Maximum 256) })
```

---

## 🌐 Portas Expostas

- **18789** - Clawdbot Gateway (interface web)
- **8317** - CLIProxyAPI (proxy OAuth interno)

---

## 🔄 Watchdog Interno

O container possui um watchdog interno que:
- ✅ Processa requisições em `ops-requests/` (restart, set_model, set_timezone)
- ✅ Monitora arquivo `restart.flag` para restarts automáticos
- ✅ Move requisições processadas para `ops-requests/done/` ou `ops-requests/error/`

---

## 📞 Suporte

**Ver logs:**
```bash
docker logs clawdbot_sandbox --tail 50
```

**Ver logs do watchdog:**
```bash
docker exec clawdbot_sandbox cat /tmp/watchdog.log
```

**Ver logs do CLIProxyAPI:**
```bash
docker exec clawdbot_sandbox cat /tmp/cliproxy.log
```

---

## 🙏 Créditos

- **Clawdbot**: https://clawd.bot
- **CLIProxyAPI**: https://github.com/router-for-me/CLIProxyAPI
- **Claude Code**: https://claude.ai
- **Gemini CLI**: https://geminicli.com

---

**Desenvolvido com ❤️ para automação inteligente**
