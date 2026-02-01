# 🆕 Novas Funcionalidades - Clawdbot v2026.1.30

Este documento descreve as novas funcionalidades adicionadas ao Clawdbot Docker.

---

## 📦 Atualização para v2026.1.30

O Clawdbot foi atualizado para a versão **v2026.1.30** com as seguintes melhorias:

### Novos Recursos

- **Shell Completion**: Autocompletar para Bash, Zsh, PowerShell e Fish
- **Per-Agent Models Status**: Status de modelos por agente (`--agent` filter)
- **Kimi K2.5**: Suporte ao modelo Kimi K2.5 no catálogo sintético
- **Segurança**: Restrição de extração de caminhos locais no parser de mídia (previne LFI)
- **Build**: Alinhamento de metadados npm tar e bin
- **Telegram**: Múltiplas correções para threading, HTML nesting e IDs de mensagem

### Instalação

O Dockerfile agora instala o Clawdbot diretamente do release do GitHub:

```dockerfile
RUN npm install -g https://github.com/openclaw/openclaw/releases/download/v2026.1.30/openclaw-2026.1.30.tgz
```

---

## 🌐 Browser Opener Skill

Nova skill para abrir URLs no navegador do sistema.

### Como Usar

O bot agora pode abrir páginas web diretamente quando solicitado:

**Exemplos de comandos:**
```
"Abra o GitHub"
"Open google.com"
"Navegue para https://youtube.com"
```

### Implementação

**Localização:** `/app/data/workspace/skills/browser-opener/`

**Métodos suportados:**
- **Docker/Linux**: Chromium com flags de sandbox desabilitado
- **Windows**: Comando `start`
- **macOS**: Comando `open`
- **Fallback**: `xdg-open` para sistemas Linux

**Exemplo de uso no bot:**
```bash
chromium --no-sandbox --disable-dev-shm-usage "https://github.com" &
```

### Configuração

O Chromium já está instalado no container com as seguintes dependências:
- `chromium` - Navegador
- `chromium-driver` - Driver para automação
- `xvfb` - Servidor X virtual para ambientes headless

---

## 📸 Screenshot Capture Skill

Nova skill para capturar screenshots da tela.

### Como Usar

O bot pode tirar screenshots quando solicitado:

**Exemplos de comandos:**
```
"Tire um screenshot"
"Capture a tela"
"Take a screenshot"
"Show me what's on screen"
```

### Implementação

**Localização:** `/app/data/workspace/skills/screenshot/`

**Script principal:** `capture_screenshot.py`

**Métodos de captura (em ordem de tentativa):**

1. **ImageMagick + Xvfb** (funciona em Docker headless)
   ```bash
   xvfb-run -a import -window root /tmp/screenshot.png
   ```

2. **ImageMagick direto** (se DISPLAY está setado)
   ```bash
   import -window root /tmp/screenshot.png
   ```

3. **scrot** (alternativa leve)
   ```bash
   scrot /tmp/screenshot.png
   ```

4. **gnome-screenshot** (se disponível)
   ```bash
   gnome-screenshot -f /tmp/screenshot.png
   ```

### Recursos

- ✅ **Múltiplos métodos**: Tenta diferentes ferramentas automaticamente
- ✅ **Cleanup automático**: Remove screenshots com mais de 24h
- ✅ **Timestamps**: Nomeia arquivos com data/hora (ex: `screenshot_20260131_123456.png`)
- ✅ **Xvfb integrado**: Servidor X virtual roda automaticamente no container
- ✅ **Diagnóstico**: Mensagens de erro detalhadas para troubleshooting

### Arquivos

```
screenshot/
├── SKILL.md                    # Documentação da skill
└── capture_screenshot.py       # Script de captura
```

### Saída do Script

```
📸 Clawdbot Screenshot Capture
==================================================
  Cleaned up 2 old screenshot(s)
✓ Screenshot captured using ImageMagick (Xvfb)
  Path: /tmp/screenshot_20260131_123456.png
  Size: 1,234,567 bytes

✓ Screenshot ready to send!
```

---

## 🖥️ Servidor X Virtual (Xvfb)

Para suportar screenshots e browser em ambiente headless (sem GUI), o Xvfb é iniciado automaticamente.

### Configuração Automática

O `entrypoint.sh` agora inicia o Xvfb:

```bash
Xvfb :99 -screen 0 1920x1080x24 > /tmp/xvfb.log 2>&1 &
export DISPLAY=:99
```

**Parâmetros:**
- `:99` - Display number
- `1920x1080x24` - Resolução (1920x1080) com 24-bit color depth

### Verificação

Para verificar se o Xvfb está rodando:

```bash
docker exec -it clawdbot ps aux | grep Xvfb
```

### Logs

Logs do Xvfb estão em `/tmp/xvfb.log` dentro do container.

---

## 🛠️ Dependências do Sistema

As seguintes ferramentas foram adicionadas ao Dockerfile:

```dockerfile
RUN apt-get install -y \
    imagemagick      # Captura e manipulação de imagens
    scrot            # Screenshot utility alternativo
    x11-apps         # Aplicações X11 básicas
    xvfb             # Virtual X server
    chromium         # Navegador web
    chromium-driver  # WebDriver para automação
```

---

## 🚀 Como Testar

### 1. Rebuild do Container

Após as mudanças, reconstrua a imagem:

```bash
docker-compose down
docker-compose build --no-cache
docker-compose up -d
```

### 2. Teste o Browser

Entre no gateway web ou envie mensagem via Telegram/WhatsApp:

```
Abra https://github.com/openclaw/openclaw
```

### 3. Teste o Screenshot

```
Tire um screenshot da tela
```

O bot deve capturar e enviar a imagem.

### 4. Verifique os Logs

```bash
# Logs do container
docker-compose logs -f clawdbot

# Logs internos
docker exec -it clawdbot cat /tmp/xvfb.log
docker exec -it clawdbot cat /tmp/cliproxy.log
```

---

## 🔧 Troubleshooting

### Screenshots não funcionam

**Problema:** "Failed to capture screenshot with any method"

**Solução:**
1. Verifique se Xvfb está rodando:
   ```bash
   docker exec -it clawdbot ps aux | grep Xvfb
   ```

2. Verifique DISPLAY:
   ```bash
   docker exec -it clawdbot echo $DISPLAY
   # Deve mostrar: :99
   ```

3. Reinicie o Xvfb manualmente:
   ```bash
   docker exec -it clawdbot bash -c "Xvfb :99 -screen 0 1920x1080x24 &"
   ```

### Browser não abre

**Problema:** Chromium não inicia

**Solução:**
1. Verifique se está instalado:
   ```bash
   docker exec -it clawdbot which chromium
   ```

2. Teste manualmente:
   ```bash
   docker exec -it clawdbot chromium --version
   docker exec -it clawdbot xvfb-run chromium --no-sandbox https://example.com
   ```

### Permissões negadas

Se houver problemas de permissão com screenshots:

```bash
docker exec -it clawdbot chmod 777 /tmp
docker exec -it clawdbot chmod +x /app/data/workspace/skills/screenshot/capture_screenshot.py
```

---

## 📚 Referências

- [OpenClaw v2026.1.30 Release Notes](https://github.com/openclaw/openclaw/releases/tag/v2026.1.30)
- [ImageMagick Documentation](https://imagemagick.org/index.php)
- [Xvfb Manual](https://www.x.org/releases/X11R7.6/doc/man/man1/Xvfb.1.xhtml)
- [Chromium Command Line Switches](https://peter.sh/experiments/chromium-command-line-switches/)

---

## 🎉 Conclusão

Com essas novas funcionalidades, o Clawdbot agora tem capacidades completas de:

- ✅ **Navegação Web**: Abrir URLs em navegador
- ✅ **Captura Visual**: Tirar screenshots da tela
- ✅ **Ambiente Headless**: Rodar em Docker sem GUI física
- ✅ **Versão Atualizada**: Recursos mais recentes do OpenClaw v2026.1.30

Todas as funcionalidades estão totalmente integradas e prontas para uso!
