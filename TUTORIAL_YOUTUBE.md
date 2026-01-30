# Tutorial: Clawdbot com Subscription Claude Max (Grátis!)

> **Atualizado:** Veja `README.md` para o passo a passo completo e mais recente.

> Use sua assinatura do Claude Max/Pro para rodar o Clawdbot sem pagar API extra!

## O que você vai precisar

- Windows 10/11
- Docker Desktop instalado
- Assinatura Claude Max ou Pro (ou Gemini)
- ~15 minutos

---

## Parte 1: Instalar o CLIProxyAPI

O CLIProxyAPI transforma sua assinatura em uma API local.

### 1.1 Baixar o CLIProxyAPI

1. Acesse: https://github.com/router-for-me/CLIProxyAPI/releases
2. Baixe o arquivo `CLIProxyAPI_x.x.x_windows_amd64.zip`
3. Extraia para `C:\Users\SEU_USUARIO\CLIProxyAPI`

Ou via PowerShell:
```powershell
# Criar pasta e baixar
mkdir $env:USERPROFILE\CLIProxyAPI
cd $env:USERPROFILE\CLIProxyAPI
curl -L -o cliproxyapi.zip "https://github.com/router-for-me/CLIProxyAPI/releases/latest/download/CLIProxyAPI_windows_amd64.zip"
Expand-Archive -Path cliproxyapi.zip -DestinationPath . -Force
```

### 1.2 Criar arquivo de configuração

Crie o arquivo `C:\Users\SEU_USUARIO\config.yaml`:

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

### 1.3 Fazer login na sua conta

Abra o PowerShell e execute:

**Para Claude Max/Pro:**
```powershell
C:\Users\SEU_USUARIO\CLIProxyAPI\cli-proxy-api.exe --claude-login
```

**Para Gemini:**
```powershell
C:\Users\SEU_USUARIO\CLIProxyAPI\cli-proxy-api.exe --login
```

> O navegador vai abrir. Faça login na sua conta.

---

## Parte 2: Configurar o Clawdbot

### 2.1 Baixar os arquivos

Clone ou baixe este repositório para uma pasta, ex: `D:\clawdbot_docker`

### 2.2 Estrutura de arquivos

```
clawdbot_docker/
├── Dockerfile
├── docker-compose.yml
├── workspace/
│   └── boot.md          (instruções do bot)
```

### 2.3 Configurar o clawdbot.json

Edite o arquivo `C:\Users\SEU_USUARIO\.clawdbot\clawdbot.json`:

**Adicione a seção `models` (antes de `agents`):**

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
        { "id": "claude-sonnet-4-20250514", "name": "Claude Sonnet 4" },
        { "id": "claude-haiku-4-5-20251001", "name": "Claude Haiku 4.5" },
        { "id": "claude-opus-4-5-20251101", "name": "Claude Opus 4.5" },
        { "id": "gemini-2.5-pro", "name": "Gemini 2.5 Pro" },
        { "id": "gemini-2.5-flash", "name": "Gemini 2.5 Flash" }
      ]
    }
  }
},
```

**Altere o modelo em `agents.defaults.model`:**

```json
"agents": {
  "defaults": {
    "model": {
      "primary": "cliproxy/claude-sonnet-4-5-20250929",
      "fallbacks": [
        "cliproxy/gemini-2.5-flash",
        "cliproxy/claude-haiku-4-5-20251001"
      ]
    },
```

---

## Parte 3: Iniciar tudo

### 3.1 Iniciar o CLIProxyAPI

Abra um PowerShell e deixe rodando:

```powershell
C:\Users\SEU_USUARIO\CLIProxyAPI\cli-proxy-api.exe
```

> Mantenha essa janela aberta!

### 3.2 Iniciar o Clawdbot (Docker)

Em outro terminal, na pasta do projeto:

```powershell
docker-compose up -d
```

### 3.3 Acessar o painel

Abra no navegador:
```
http://localhost:18789/?token=SEU_TOKEN_AQUI
```

> Na primeira vez, pode pedir pareamento. Aguarde alguns segundos e recarregue.

---

## Parte 4: Automatizar a inicialização

### 4.1 Criar script de inicialização

Crie o arquivo `C:\Users\SEU_USUARIO\iniciar-clawdbot.bat`:

```batch
@echo off
echo Iniciando CLIProxyAPI...
start "" "C:\Users\SEU_USUARIO\CLIProxyAPI\cli-proxy-api.exe"
timeout /t 3 /nobreak >nul
echo Iniciando Clawdbot Docker...
cd /d D:\clawdbot_docker
docker-compose up -d
echo.
echo Pronto! Acesse: http://localhost:18789/?token=SEU_TOKEN
pause
```

### 4.2 Iniciar automaticamente com o Windows (Opcional)

1. Pressione `Win + R`
2. Digite `shell:startup` e pressione Enter
3. Crie um atalho para o `iniciar-clawdbot.bat` nessa pasta

---

## Parte 5: Trocar entre Claude e Gemini

### Opção A: Editar o clawdbot.json

Altere a linha `primary` em `agents.defaults.model`:

**Para usar Claude:**
```json
"primary": "cliproxy/claude-sonnet-4-5-20250929"
```

**Para usar Gemini:**
```json
"primary": "cliproxy/gemini-2.5-pro"
```

Depois reinicie o Docker:
```powershell
docker-compose restart
```

### Opção B: Usar fallbacks automáticos

Configure fallbacks para trocar automaticamente se um falhar:

```json
"model": {
  "primary": "cliproxy/claude-sonnet-4-5-20250929",
  "fallbacks": [
    "cliproxy/gemini-2.5-pro",
    "cliproxy/claude-haiku-4-5-20251001"
  ]
}
```

---

## Modelos disponíveis

### Claude (requer --claude-login)
| Modelo | ID |
|--------|-----|
| Claude Opus 4.5 | `cliproxy/claude-opus-4-5-20251101` |
| Claude Sonnet 4.5 | `cliproxy/claude-sonnet-4-5-20250929` |
| Claude Sonnet 4 | `cliproxy/claude-sonnet-4-20250514` |
| Claude Haiku 4.5 | `cliproxy/claude-haiku-4-5-20251001` |

### Gemini (requer --login)
| Modelo | ID |
|--------|-----|
| Gemini 2.5 Pro | `cliproxy/gemini-2.5-pro` |
| Gemini 2.5 Flash | `cliproxy/gemini-2.5-flash` |

---

## Comandos úteis

| Ação | Comando |
|------|---------|
| Iniciar Clawdbot | `docker-compose up -d` |
| Parar Clawdbot | `docker-compose down` |
| Reiniciar | `docker-compose restart` |
| Ver logs | `docker-compose logs -f` |
| Testar proxy | `curl http://localhost:8317/v1/models` |

---

## Solução de problemas

### "pairing required"
- Aguarde alguns segundos e recarregue a página
- Ou reinicie o Docker: `docker-compose restart`

### "Unknown model"
- Verifique se o CLIProxyAPI está rodando
- Teste: `curl http://localhost:8317/v1/models`

### Modelo não responde
- Verifique se fez login no provider correto
- Claude: `--claude-login`
- Gemini: `--login`

### Rate limit
- Os limites são compartilhados com Claude web/app
- Aguarde o reset (a cada 5 horas)

---

## Dicas

1. **Use Haiku/Flash para tarefas simples** - São mais rápidos e consomem menos tokens
2. **Opus/Pro para tarefas complexas** - Melhor raciocínio, mas mais lento
3. **Fallbacks são seus amigos** - Configure múltiplos modelos como backup
4. **Personalize o boot.md** - Defina a personalidade do seu bot

---

## Links úteis

- [CLIProxyAPI GitHub](https://github.com/router-for-me/CLIProxyAPI)
- [Documentação Moltbot](https://docs.molt.bot/)
- [Claude Max Plans](https://claude.ai/pricing)
