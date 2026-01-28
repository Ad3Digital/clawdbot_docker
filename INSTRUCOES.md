# Guia de Uso: Clawdbot no Docker

## Configuracao Inicial (CLIProxyAPI + Claude Max)

Para usar sua subscription do Claude Max em vez de pagar API separada:

### 1. Instalar CLIProxyAPI (no Windows/Mac host)

**macOS:**
```bash
brew tap router-for-me/tap
brew install cliproxyapi
```

**Windows:** Baixe de https://github.com/router-for-me/CLIProxyAPI/releases

### 2. Fazer login na sua conta Claude
```bash
cliproxyapi --claude-login
```

### 3. Criar config em `~/.cli-proxy-api/config.yaml`
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

### 4. Iniciar o proxy
```bash
cliproxyapi --config ~/.cli-proxy-api/config.yaml
```

### 5. Iniciar o Clawdbot
```powershell
docker-compose up -d
```

---

## Acesso ao Painel

O token esta configurado no arquivo `.env`. Acesse:

```
http://localhost:18789/?token=SEU_TOKEN_AQUI
```

Veja o valor de `CLAWDBOT_GATEWAY_TOKEN` no seu `.env` para o token correto.

---

## Personalizacao ("Setup do CMD")

Você perguntou como configurar as "instruções" ou "cérebro" dele antes de rodar. Isso é feito pelo arquivo **`boot.md`**.

1. Vá na pasta `workspace` que está aqui dentro.
2. Abra (ou crie) o arquivo `boot.md`.
3. Escreva suas instruções de sistema lá.

**Exemplo de conteúdo para o `boot.md`:**
```markdown
# Instruções do Sistema
Você é um especialista em Marketing Digital.
Sempre responda com tom profissional e direto.
Use emojis apenas para celebrar conquistas.
```

**Para aplicar as mudanças:**
Sempre que editar o `boot.md`, você precisa reiniciar o bot para ele ler as novas regras:
```powershell
docker-compose restart
```

---

## 🚀 Comandos Úteis

| Ação | Comando (no terminal da pasta clawdbot_docker) |
|---|---|
| **Iniciar** | `docker-compose up -d` |
| **Reiniciar** | `docker-compose restart` |
| **Parar** | `docker-compose down` |
| **Ver Logs** | `docker-compose logs -f` |

## 📂 Arquivos Importantes
- **`workspace/`**: Onde você coloca seus arquivos e onde o bot salva coisas.
- **`workspace/boot.md`**: As regras iniciais do bot (System Prompt).
- **`.clawdbot/clawdbot.json`**: Configurações técnicas (Tokens de API, Portas, etc).
