# Clawdbot Docker Sandbox

Roda o [Clawdbot](https://docs.molt.bot/) dentro de um container Docker isolado, usando o [CLIProxyAPI](https://github.com/router-for-me/CLIProxyAPI) para transformar suas assinaturas (Claude Max/Pro, Gemini, Qwen, OpenAI Codex) em uma API local compativel com OpenAI -- sem precisar pagar API separada.

## Como funciona

```
┌──────────────────────────────────────────────────────┐
│  CLIProxyAPI  (roda no seu Windows, porta 8317)      │
│                                                      │
│  Faz login na sua conta (Claude, Gemini, Qwen...)    │
│  e expoe uma API local compativel com OpenAI.        │
│  Voce NAO precisa de chave de API paga.              │
└──────────────────┬───────────────────────────────────┘
                   │  http://localhost:8317/v1
                   v
┌──────────────────────────────────────────────────────┐
│  Docker Container  (clawdbot_sandbox)                │
│                                                      │
│  Clawdbot Gateway rodando na porta 18789.            │
│  Conecta no CLIProxyAPI via host.docker.internal.    │
│  Isolado do resto do sistema.                        │
└──────────────────┬───────────────────────────────────┘
                   │  http://localhost:18789/?token=...
                   v
              Seu navegador
```

**Resumo:** O CLIProxyAPI e o coracao do sistema. Ele transforma sua assinatura em uma API REST local. O Clawdbot (dentro do Docker) consome essa API como se fosse a API da OpenAI.

---

## Pre-requisitos

- Windows 10/11
- [Docker Desktop](https://www.docker.com/products/docker-desktop/) instalado e rodando
- Pelo menos UMA assinatura ativa: Claude Max/Pro, Gemini, Qwen, ou OpenAI/Codex

---

## Passo a passo completo

### 1. Instalar o CLIProxyAPI

O CLIProxyAPI e um executavel que roda no seu Windows. Ele faz a ponte entre sua subscription e o Clawdbot.

**Opcao A -- Download manual:**

1. Acesse: https://github.com/router-for-me/CLIProxyAPI/releases
2. Baixe `CLIProxyAPI_x.x.x_windows_amd64.zip`
3. Extraia para `C:\Users\SEU_USUARIO\CLIProxyAPI\`

**Opcao B -- Via PowerShell:**

```powershell
mkdir $env:USERPROFILE\CLIProxyAPI
cd $env:USERPROFILE\CLIProxyAPI
curl -L -o cliproxyapi.zip "https://github.com/router-for-me/CLIProxyAPI/releases/latest/download/CLIProxyAPI_windows_amd64.zip"
Expand-Archive -Path cliproxyapi.zip -DestinationPath . -Force
```

### 2. Criar a configuracao do CLIProxyAPI

Crie o arquivo `C:\Users\SEU_USUARIO\config.yaml` com o conteudo:

```yaml
port: 8317
remote-management:
  allow-remote: false
  secret-key: ""
auth-dir: "~/.cli-proxy-api"
auth:
  providers: []
debug: false
```

> `allow-remote: false` garante que o proxy so aceita conexoes locais (seguranca).

### 3. Fazer login nos providers

Cada provider precisa de um login separado. Faca login em **todos os que voce tem assinatura**. O navegador vai abrir automaticamente para autenticar.

```powershell
# ─── Claude Max / Claude Pro ───
C:\Users\SEU_USUARIO\CLIProxyAPI\cli-proxy-api.exe --claude-login

# ─── Google Gemini ───
C:\Users\SEU_USUARIO\CLIProxyAPI\cli-proxy-api.exe --login

# ─── Qwen (Alibaba) ───
C:\Users\SEU_USUARIO\CLIProxyAPI\cli-proxy-api.exe --qwen-login

# ─── OpenAI Codex / ChatGPT ───
C:\Users\SEU_USUARIO\CLIProxyAPI\cli-proxy-api.exe --codex-login
```

| Provider | Comando de login | O que precisa |
|----------|-----------------|---------------|
| Claude | `--claude-login` | Assinatura Claude Max ou Pro |
| Gemini | `--login` | Conta Google com Gemini |
| Qwen | `--qwen-login` | Conta Qwen/Alibaba Cloud |
| Codex/OpenAI | `--codex-login` | Assinatura OpenAI/ChatGPT |

> Voce pode fazer login em varios providers ao mesmo tempo. Todos ficam disponiveis na mesma porta 8317.

### 4. Testar o CLIProxyAPI

Inicie o proxy:

```powershell
C:\Users\SEU_USUARIO\CLIProxyAPI\cli-proxy-api.exe
```

**IMPORTANTE: Mantenha essa janela aberta!** O proxy precisa estar rodando o tempo todo.

Em outro terminal, teste se esta funcionando:

```powershell
curl http://localhost:8317/v1/models
```

Deve retornar uma lista JSON com os modelos disponiveis dos providers em que voce fez login.

### 5. Clonar este repositorio

```powershell
git clone <URL_DO_REPO> clawdbot_docker
cd clawdbot_docker
```

### 6. Configurar o .env

```powershell
copy .env.example .env
```

Edite o `.env` e gere um token seguro para o gateway:

```powershell
# Gerar token seguro (PowerShell)
-join ((1..24) | ForEach-Object { '{0:x2}' -f (Get-Random -Maximum 256) })

# Ou com openssl
openssl rand -hex 24
```

Cole o token gerado em `CLAWDBOT_GATEWAY_TOKEN` no `.env`:

```env
OPENAI_BASE_URL=http://host.docker.internal:8317/v1
OPENAI_API_KEY=dummy
CLAWDBOT_DEFAULT_MODEL=claude-sonnet-4-5-20250929
CLAWDBOT_GATEWAY_TOKEN=cole-seu-token-gerado-aqui
```

> `OPENAI_API_KEY=dummy` e intencional -- a autenticacao real e feita pelo CLIProxyAPI via login OAuth.

### 7. Configurar o clawdbot.json

Edite `C:\Users\SEU_USUARIO\.clawdbot\clawdbot.json` e adicione os modelos dos providers que voce tem:

```json
"models": {
  "mode": "merge",
  "providers": {
    "cliproxy": {
      "baseUrl": "http://host.docker.internal:8317/v1",
      "apiKey": "dummy",
      "api": "openai-completions",
      "models": [
        { "id": "claude-sonnet-4-5-20250929", "name": "Claude Sonnet 4.5" },
        { "id": "claude-opus-4-5-20251101", "name": "Claude Opus 4.5" },
        { "id": "claude-sonnet-4-20250514", "name": "Claude Sonnet 4" },
        { "id": "claude-haiku-4-5-20251001", "name": "Claude Haiku 4.5" },
        { "id": "gemini-2.5-pro", "name": "Gemini 2.5 Pro" },
        { "id": "gemini-2.5-flash", "name": "Gemini 2.5 Flash" }
      ]
    }
  }
}
```

Configure fallbacks para trocar automaticamente se um modelo falhar:

```json
"agents": {
  "defaults": {
    "model": {
      "primary": "cliproxy/claude-sonnet-4-5-20250929",
      "fallbacks": [
        "cliproxy/gemini-2.5-pro",
        "cliproxy/claude-haiku-4-5-20251001"
      ]
    }
  }
}
```

### 8. Subir o Clawdbot

**Opcao A -- Script automatico (recomendado):**

```powershell
.\iniciar-clawdbot.bat
```

O script faz tudo sozinho: verifica Docker, inicia o CLIProxyAPI, testa a conexao, e sobe o container.

**Opcao B -- Manual:**

```powershell
# Terminal 1: manter o proxy rodando
C:\Users\SEU_USUARIO\CLIProxyAPI\cli-proxy-api.exe

# Terminal 2: subir o container
docker-compose up -d
```

### 9. Acessar o painel

Abra no navegador:

```
http://localhost:18789/?token=SEU_TOKEN_DO_ENV
```

Substitua `SEU_TOKEN_DO_ENV` pelo valor de `CLAWDBOT_GATEWAY_TOKEN` que voce colocou no `.env`.

> Na primeira vez pode pedir pareamento. Aguarde alguns segundos e recarregue a pagina.

---

## Estrutura do projeto

```
clawdbot_docker/
├── Dockerfile              # Imagem Docker (Node 22 + clawdbot)
├── docker-compose.yml      # Orquestracao do container
├── .env.example            # Template de variaveis de ambiente
├── .env                    # Suas variaveis (NAO vai pro git)
├── .gitignore              # Protege secrets do repositorio
├── iniciar-clawdbot.bat    # Script Windows para iniciar tudo
├── INSTRUCOES.md           # Guia de uso complementar
├── TUTORIAL_YOUTUBE.md     # Tutorial passo a passo detalhado
└── workspace/              # Pasta de trabalho do bot
    ├── boot.md             # System prompt (personalidade do bot)
    └── canvas/
        └── index.html      # Interface de teste interativa
```

---

## Personalizacao do bot

Edite `workspace/boot.md` com as instrucoes de sistema que quiser. Exemplo:

```markdown
# Instrucoes do Sistema
Voce e um especialista em Python e automacao.
Sempre responda de forma objetiva e com exemplos de codigo.
```

Depois reinicie para aplicar:

```powershell
docker-compose restart
```

---

## Modelos disponiveis

### Claude (requer `--claude-login`)

| Modelo | ID | Uso recomendado |
|--------|----|-----------------|
| Claude Opus 4.5 | `claude-opus-4-5-20251101` | Tarefas complexas, raciocinio avancado |
| Claude Sonnet 4.5 | `claude-sonnet-4-5-20250929` | Uso geral (recomendado como primary) |
| Claude Sonnet 4 | `claude-sonnet-4-20250514` | Alternativa equilibrada |
| Claude Haiku 4.5 | `claude-haiku-4-5-20251001` | Respostas rapidas, tarefas simples |

### Gemini (requer `--login`)

| Modelo | ID | Uso recomendado |
|--------|----|-----------------|
| Gemini 2.5 Pro | `gemini-2.5-pro` | Tarefas complexas, contexto longo |
| Gemini 2.5 Flash | `gemini-2.5-flash` | Respostas rapidas, fallback |

### Qwen (requer `--qwen-login`)

Modelos disponiveis dependem da sua conta Qwen. Apos login, verifique com:

```powershell
curl http://localhost:8317/v1/models
```

### OpenAI/Codex (requer `--codex-login`)

Modelos disponiveis dependem da sua assinatura OpenAI. Apos login, verifique com:

```powershell
curl http://localhost:8317/v1/models
```

---

## Comandos uteis

| Acao | Comando |
|------|---------|
| Iniciar tudo (automatico) | `.\iniciar-clawdbot.bat` |
| Subir container | `docker-compose up -d` |
| Parar container | `docker-compose down` |
| Reiniciar | `docker-compose restart` |
| Ver logs em tempo real | `docker-compose logs -f` |
| Testar se o proxy responde | `curl http://localhost:8317/v1/models` |
| Listar modelos no clawdbot | `docker exec clawdbot_sandbox clawdbot models list` |
| Listar agentes | `docker exec clawdbot_sandbox clawdbot agents list` |

---

## Trocar de modelo/provider

### Mudar o modelo principal

Edite `primary` no `clawdbot.json`:

```json
"primary": "cliproxy/gemini-2.5-pro"
```

Depois: `docker-compose restart`

### Usar fallbacks automaticos

Se o modelo principal falhar (rate limit, erro, etc), o Clawdbot tenta o proximo da lista:

```json
"model": {
  "primary": "cliproxy/claude-sonnet-4-5-20250929",
  "fallbacks": [
    "cliproxy/gemini-2.5-pro",
    "cliproxy/claude-haiku-4-5-20251001",
    "cliproxy/gemini-2.5-flash"
  ]
}
```

---

## Solucao de problemas

| Problema | Solucao |
|----------|---------|
| "pairing required" | Aguarde alguns segundos e recarregue a pagina, ou `docker-compose restart` |
| "Unknown model" | Verifique se o CLIProxyAPI esta rodando: `curl http://localhost:8317/v1/models` |
| Modelo nao responde | Confirme que fez login no provider correto (veja tabela acima) |
| Rate limit | Limites compartilhados com uso no site/app. Reset a cada ~5 horas |
| Container nao inicia | Verifique se Docker Desktop esta rodando: `docker info` |
| Proxy nao responde | Verifique se a janela do CLIProxyAPI esta aberta e sem erros |

---

## Seguranca

- O container Docker e isolado: so acessa as pastas mapeadas no `docker-compose.yml`
- Secrets ficam no `.env` que esta no `.gitignore` (nunca sobe pro git)
- Gere um token forte: `openssl rand -hex 24`
- O CLIProxyAPI roda com `allow-remote: false` (so aceita conexoes locais)
- Credenciais de login ficam em `~/.cli-proxy-api/` no seu usuario (fora do repo)

---

## Links uteis

- [CLIProxyAPI - GitHub](https://github.com/router-for-me/CLIProxyAPI)
- [CLIProxyAPI - Releases](https://github.com/router-for-me/CLIProxyAPI/releases)
- [Clawdbot - Documentacao](https://docs.molt.bot/)
- [Clawdbot - Modelos](https://docs.molt.bot/concepts/models)
