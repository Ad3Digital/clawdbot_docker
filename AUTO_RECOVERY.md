# Sistema de Auto-Recuperação do Clawdbot

## Problema Original

O Clawdbot travava quando:
- Sessões de conversa ficavam muito grandes (>10MB, centenas de mensagens)
- Processamento de mensagens com imagens demorava muito (timeout da API)
- Arquivos de lock ficavam órfãos quando processos morriam inesperadamente
- Gateway entrava em deadlock sem recuperação

## Soluções Implementadas

### 1. Watchdog Melhorado (`watchdog.sh`)

O watchdog agora executa **5 verificações automáticas** a cada 5 segundos:

#### a) Limpeza de Locks Órfãos
- Verifica arquivos `.lock` mais antigos que 5 minutos (300s)
- Checa se o PID no lock ainda existe
- Remove locks de processos mortos automaticamente
- **Resolve**: Deadlocks causados por crashes inesperados

#### b) Arquivamento de Sessões Grandes
- Monitora sessões maiores que 10MB
- Move automaticamente para `.old` (arquiva)
- Força início de nova conversa limpa
- **Resolve**: Timeouts causados por contexto muito grande

#### c) Health Check do Gateway
- Detecta processos em state `D` (uninterruptible sleep) ou `Z` (zombie)
- Mata e reinicia gateway automaticamente
- Previne travamentos silenciosos
- **Resolve**: Gateway travado sem responder

#### d) Restart Flag
- Monitora arquivo `/root/.clawdbot/restart.flag`
- Permite reinício programático do bot
- Usado por skills de manutenção

#### e) Ops-Requests
- Processa comandos de operação (restart, set_model, set_timezone)
- Permite controle remoto do container

### 2. Docker Health Check

Adicionado no `docker-compose.yml`:

```yaml
healthcheck:
  test: ["CMD-SHELL", "pgrep -f 'clawdbot-gateway' || exit 1"]
  interval: 30s
  timeout: 10s
  retries: 3
  start_period: 40s
```

**Como funciona:**
- Verifica a cada 30s se o processo `clawdbot-gateway` existe
- Falha após 3 tentativas (90s total)
- Reinicia o container automaticamente via `restart: unless-stopped`
- **Resolve**: Casos extremos onde o gateway morre completamente

## Parâmetros Configuráveis

### Em `watchdog.sh`:

```bash
MAX_SESSION_SIZE_MB=10          # Tamanho máximo antes de arquivar
LOCK_MAX_AGE_SECONDS=300        # Idade máxima de locks (5min)
GATEWAY_HANG_THRESHOLD=600      # Não usado ainda (futuro)
```

### Em `docker-compose.yml`:

```yaml
interval: 30s      # Frequência do health check
timeout: 10s       # Tempo máximo para responder
retries: 3         # Tentativas antes de reiniciar
```

## Como Funciona na Prática

### Cenário 1: Sessão Grande Trava o Bot

1. Usuário envia mensagem em conversa com 800+ mensagens
2. Bot tenta processar mas API dá timeout
3. **Watchdog detecta** que sessão tem >10MB
4. **Arquiva automaticamente** a sessão
5. Próxima mensagem inicia conversa nova e limpa
6. **Tempo de recuperação**: ~5-10 segundos

### Cenário 2: Lock Órfão Bloqueia Sistema

1. Processo morre deixando arquivo `.lock`
2. Novas requisições falham com "session file locked"
3. **Watchdog detecta** lock com >5min de idade
4. **Verifica** que PID não existe mais
5. **Remove** lock órfão
6. Sistema volta ao normal
7. **Tempo de recuperação**: <5 segundos

### Cenário 3: Gateway Trava Completamente

1. Gateway entra em deadlock (state D)
2. **Watchdog detecta** state anormal
3. **Mata** processo com SIGKILL (-9)
4. **Reinicia** gateway automaticamente
5. **Tempo de recuperação**: ~2-5 segundos

### Cenário 4: Gateway Morre

1. Processo `clawdbot-gateway` morre
2. **Health check** falha 3x em 90s
3. **Docker reinicia** container completo
4. **Tempo de recuperação**: ~40-60 segundos

## Logs e Monitoramento

### Ver logs do watchdog:
```bash
docker logs -f clawdbot_sandbox | grep WATCHDOG
```

### Ver health check:
```bash
docker inspect --format='{{json .State.Health}}' clawdbot_sandbox | jq
```

### Logs típicos de auto-recuperação:

```
[WATCHDOG] Removing orphan lock: /root/.clawdbot/agents/main/sessions/708fd147-...lock (PID 37 is dead, age: 320s)
[WATCHDOG] Archiving large session: /root/.clawdbot/agents/main/sessions/708fd147-...jsonl (12MB)
[WATCHDOG] Gateway is hung (state: D), restarting...
```

## Melhorias Futuras

1. **Timeout por mensagem**: Matar processamento que demora >10min
2. **Limpeza programada**: Deletar sessões `.old` após 7 dias
3. **Alertas**: Notificar no Telegram quando auto-recuperação ocorrer
4. **Métricas**: Registrar frequência de travamentos
5. **Circuit breaker**: Desabilitar APIs problemáticas temporariamente

## Testando a Auto-Recuperação

### Simular lock órfão:
```bash
docker exec clawdbot_sandbox sh -c "echo '{\"pid\":99999}' > /root/.clawdbot/agents/main/sessions/test.lock"
# Aguardar 5min ou editar LOCK_MAX_AGE_SECONDS para 10s
```

### Simular sessão grande:
```bash
docker exec clawdbot_sandbox sh -c "dd if=/dev/zero of=/root/.clawdbot/agents/main/sessions/test.jsonl bs=1M count=15"
# Aguardar watchdog ciclar
```

### Forçar restart:
```bash
docker exec clawdbot_sandbox sh -c "touch /root/.clawdbot/restart.flag"
```

## Notas de Segurança

- Watchdog roda como root dentro do container (necessário para pkill)
- Não afeta dados do usuário (apenas arquiva sessões)
- Restart do container preserva todos os volumes
- Sessões arquivadas (`.old`) podem ser recuperadas manualmente se necessário
