# Graphiti - Temporal Knowledge Graph

Sistema de memória temporal com knowledge graphs para o Clawdbot.

## O que é Graphiti?

Graphiti é um framework da [Zep](https://www.getzep.com/) que cria grafos de conhecimento temporal para agentes de IA. Diferente de memórias simples, o Graphiti:

- **Rastreia mudanças ao longo do tempo** - Sabe quando fatos eram válidos
- **Conecta informações relacionadas** - Cria um grafo de conhecimento
- **Responde queries contextuais** - Busca semântica inteligente
- **Evolui com novas informações** - Atualiza fatos automaticamente

## Arquitetura

```
┌─────────────┐
│  Clawdbot   │ ──> Adiciona episódios/memórias
└─────────────┘
       │
       ↓
┌─────────────┐
│  Graphiti   │ ──> API REST (porta 8001)
│   Server    │
└─────────────┘
       │
       ↓
┌─────────────┐
│   Neo4j     │ ──> Banco de dados de grafos
│  (porta     │     Armazena nós e relacionamentos
│   7474/7687)│
└─────────────┘
```

## Componentes

### Neo4j (porta 7474/7687)
- **Interface Web**: http://localhost:7474
- **Usuário**: `neo4j`
- **Senha**: `graphitipass`
- Armazena o grafo de conhecimento

### Graphiti Server (porta 8001)
- **API REST**: http://localhost:8001
- **Docs**: http://localhost:8001/docs
- Processa episódios e queries

## Uso via API

### 1. Adicionar um Episódio (Memória)

```bash
curl -X POST http://localhost:8001/episodes \
  -H "Content-Type: application/json" \
  -d '{
    "name": "conversa_usuario_123",
    "episode_body": "O usuário João disse que gosta de programar em Python e está aprendendo Machine Learning.",
    "source_description": "Telegram chat",
    "episode_type": "message"
  }'
```

### 2. Buscar Informações

```bash
curl -X POST http://localhost:8001/search \
  -H "Content-Type: application/json" \
  -d '{
    "query": "O que o João gosta de fazer?",
    "num_results": 5
  }'
```

Resposta:
```json
{
  "query": "O que o João gosta de fazer?",
  "num_results": 2,
  "results": [
    {
      "uuid": "abc-123",
      "fact": "João gosta de programar em Python",
      "valid_at": "2026-02-01T04:30:00Z",
      "created_at": "2026-02-01T04:30:00Z"
    },
    {
      "uuid": "def-456",
      "fact": "João está aprendendo Machine Learning",
      "valid_at": "2026-02-01T04:30:00Z",
      "created_at": "2026-02-01T04:30:00Z"
    }
  ]
}
```

### 3. Health Check

```bash
curl http://localhost:8001/health
```

### 4. Estatísticas

```bash
curl http://localhost:8001/stats
```

## Uso no Clawdbot

O Clawdbot pode usar o Graphiti através da skill `graphiti`:

```
/graphiti search "O que sabemos sobre as preferências do usuário?"
```

Ou adicionar episódios automaticamente após cada conversa.

## Variáveis de Ambiente

Já configuradas no `docker-compose.yml`:

```yaml
GRAPHITI_URL=http://graphiti:8001
NEO4J_URI=bolt://neo4j:7687
NEO4J_USER=neo4j
NEO4J_PASSWORD=graphitipass
```

## Visualizar o Grafo

Acesse http://localhost:7474 e execute queries Cypher:

```cypher
// Ver todos os nós
MATCH (n) RETURN n LIMIT 50

// Ver episódios
MATCH (e:Episode) RETURN e LIMIT 20

// Ver entidades
MATCH (ent:Entity) RETURN ent LIMIT 20

// Ver relacionamentos
MATCH (a)-[r]->(b) RETURN a, r, b LIMIT 30
```

## Exemplos de Uso

### Rastrear Preferências do Usuário

```python
# Adicionar preferência
POST /episodes
{
  "name": "preferencia_usuario",
  "episode_body": "Maria prefere receber notificações às 18h",
  "source_description": "Configuração de preferências"
}

# Mais tarde...
POST /episodes
{
  "name": "preferencia_atualizada",
  "episode_body": "Maria mudou as notificações para 20h",
  "source_description": "Atualização de configuração"
}

# Buscar preferência atual
POST /search
{
  "query": "Que horas Maria quer receber notificações?"
}
# Retorna: "Maria prefere receber notificações às 20h" (mais recente)
```

### Rastrear Conversas

```python
# Cada mensagem do usuário vira um episódio
POST /episodes
{
  "name": "msg_001",
  "episode_body": "Usuário: Preciso de ajuda com Docker\nBot: Claro! O que você precisa?",
  "source_description": "Telegram conversation"
}

# Buscar contexto de conversas anteriores
POST /search
{
  "query": "Sobre o que o usuário perguntou ontem?"
}
```

## Resolução de Problemas

### Neo4j não inicia

```bash
# Ver logs
docker logs graphiti_neo4j

# Verificar se a porta está livre
netstat -ano | findstr :7474
netstat -ano | findstr :7687
```

### Graphiti não conecta ao Neo4j

```bash
# Verificar se Neo4j está healthy
docker ps

# Testar conexão manual
docker exec -it graphiti_service bash
apt-get update && apt-get install -y curl
curl http://neo4j:7474
```

### Limpar dados do grafo

```bash
# Parar containers
docker-compose down

# Remover volume do Neo4j
docker volume rm clawdbot_docker_neo4j-data

# Reiniciar
docker-compose up -d
```

## Performance

- **Memória Neo4j**: Configurado para usar até 2GB de heap
- **Índices automáticos**: Graphiti cria índices para buscas rápidas
- **Cache**: Resultados de busca podem ser cacheados no Clawdbot

## Recursos

- [Graphiti GitHub](https://github.com/getzep/graphiti)
- [Documentação Oficial](https://www.getzep.com/product/open-source/)
- [Neo4j Cypher Guide](https://neo4j.com/docs/cypher-manual/current/)
- [FastAPI Docs](https://fastapi.tiangolo.com/)

## Sources

- [Graphiti: Build Real-Time Knowledge Graphs for AI Agents](https://github.com/getzep/graphiti)
- [Graphiti: Temporal Knowledge Graphs for Agentic Apps](https://blog.getzep.com/graphiti-knowledge-graphs-for-agents/)
- [Building AI Agents with Knowledge Graph Memory](https://medium.com/@saeedhajebi/building-ai-agents-with-knowledge-graph-memory-a-comprehensive-guide-to-graphiti-3b77e6084dec)
