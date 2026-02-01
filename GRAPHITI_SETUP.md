# Integração Graphiti + Clawdbot

Sistema de memória temporal com knowledge graphs integrado ao Clawdbot Docker.

## O que foi adicionado?

### 3 novos serviços no Docker Compose:

1. **Neo4j** (porta 7474/7687) - Banco de dados de grafos
2. **Graphiti** (porta 8001) - API REST para knowledge graphs
3. **Clawdbot** - Agora conectado ao Graphiti via variáveis de ambiente

## Quick Start

### 1. Subir todos os serviços

```bash
docker-compose up -d
```

Aguarde ~60 segundos para tudo inicializar.

### 2. Verificar se está tudo rodando

```bash
# Ver status
docker-compose ps

# Deve mostrar:
# - clawdbot_sandbox (healthy)
# - graphiti_neo4j (healthy)
# - graphiti_service (healthy)
```

### 3. Acessar interfaces

- **Neo4j Browser**: http://localhost:7474
  - Usuário: `neo4j`
  - Senha: `graphitipass`

- **Graphiti API Docs**: http://localhost:8001/docs

- **Clawdbot**: http://localhost:18789

### 4. Testar Graphiti

```bash
# Health check
curl http://localhost:8001/health

# Adicionar uma memória
curl -X POST http://localhost:8001/episodes \
  -H "Content-Type: application/json" \
  -d '{
    "name": "first_memory",
    "episode_body": "O Clawdbot foi configurado com sucesso com Graphiti integration!",
    "source_description": "Setup test"
  }'

# Buscar memórias
curl -X POST http://localhost:8001/search \
  -H "Content-Type: application/json" \
  -d '{
    "query": "Como foi a configuração do Clawdbot?",
    "num_results": 5
  }'
```

## Integração com Clawdbot

### Variáveis de ambiente já configuradas:

```env
GRAPHITI_URL=http://graphiti:8001
NEO4J_URI=bolt://neo4j:7687
NEO4J_USER=neo4j
NEO4J_PASSWORD=graphitipass
```

### Usar via skill Graphiti (se disponível):

```
/graphiti search "O que você sabe sobre minhas preferências?"
```

### Programaticamente via Python:

```python
import requests

# Adicionar episódio
response = requests.post(
    "http://localhost:8001/episodes",
    json={
        "name": "user_preference",
        "episode_body": "User prefers dark mode and notifications at 8pm",
        "source_description": "User settings"
    }
)

# Buscar informações
response = requests.post(
    "http://localhost:8001/search",
    json={
        "query": "What are the user's preferences?",
        "num_results": 10
    }
)
print(response.json())
```

## Arquitetura

```
┌──────────────────┐
│   Clawdbot       │
│  (porta 18789)   │
└────────┬─────────┘
         │
         ↓
┌──────────────────┐     ┌──────────────────┐
│   Graphiti API   │────→│     Neo4j        │
│  (porta 8001)    │     │  (porta 7474)    │
└──────────────────┘     └──────────────────┘
                         Graph Database
```

## Volumes Persistentes

Os dados são salvos em volumes Docker:

```yaml
volumes:
  neo4j-data:        # Dados do grafo
  neo4j-logs:        # Logs do Neo4j
  graphiti-cache:    # Cache do Python
```

Para limpar completamente:

```bash
docker-compose down -v
```

## Casos de Uso

### 1. Memória de Conversas

Toda conversa do usuário pode ser salva como um episódio:

```python
{
  "name": f"conversation_{timestamp}",
  "episode_body": f"User: {user_msg}\nBot: {bot_response}",
  "source_description": "Telegram chat"
}
```

### 2. Rastreamento de Preferências

```python
# Primeira vez
"User set notification time to 6pm"

# Atualização
"User changed notification time to 8pm"

# Query retorna a mais recente automaticamente!
```

### 3. Contexto de Longo Prazo

```python
# Buscar tudo relacionado a um tópico
query = "What did we discuss about Docker?"

# Retorna todos os episódios relevantes em ordem temporal
```

### 4. Tracking de Tarefas

```python
"User requested to implement auto-recovery"
"Auto-recovery was implemented successfully"
"User tested auto-recovery and confirmed working"
```

## Performance

### Recursos configurados:

- **Neo4j Heap**: 2GB máximo
- **Graphiti**: Roda em Python 3.11-slim (leve)
- **Health checks**: Monitoramento automático

### Otimizações:

- APOC plugin habilitado (procedimentos avançados)
- Índices automáticos criados pelo Graphiti
- Cache de resultados de busca

## Troubleshooting

### Neo4j não inicia

```bash
# Ver logs detalhados
docker logs graphiti_neo4j

# Verificar recursos
docker stats graphiti_neo4j
```

### Graphiti não conecta

```bash
# Ver logs
docker logs graphiti_service

# Verificar se Neo4j está healthy
docker inspect graphiti_neo4j | grep -i health
```

### Limpar e recomeçar

```bash
# Parar tudo
docker-compose down

# Remover volumes (CUIDADO: perde dados!)
docker volume rm clawdbot_docker_neo4j-data
docker volume rm clawdbot_docker_graphiti-cache

# Subir novamente
docker-compose up -d
```

## Monitoramento

### Verificar saúde dos serviços:

```bash
# Status geral
docker-compose ps

# Logs em tempo real
docker-compose logs -f graphiti

# Neo4j logs
docker-compose logs -f neo4j
```

### Queries úteis no Neo4j Browser:

```cypher
// Total de nós
MATCH (n) RETURN count(n)

// Episódios recentes
MATCH (e:Episode)
RETURN e.name, e.created_at
ORDER BY e.created_at DESC
LIMIT 10

// Grafo completo (cuidado em produção!)
MATCH (n)-[r]->(m)
RETURN n, r, m
LIMIT 50
```

## Próximos Passos

1. **Criar skill Graphiti para Clawdbot** - Comandos tipo `/graphiti search`
2. **Auto-save de conversas** - Salvar automaticamente cada mensagem
3. **Summarização temporal** - Agrupar episódios antigos
4. **Export/Import** - Backup do knowledge graph
5. **Visualização customizada** - Dashboard web do grafo

## Recursos

- [Graphiti Documentation](./graphiti/README.md)
- [Neo4j Browser Guide](https://neo4j.com/docs/browser-manual/current/)
- [Cypher Query Language](https://neo4j.com/docs/cypher-manual/current/)

## Sources

- [GitHub - getzep/graphiti](https://github.com/getzep/graphiti)
- [Graphiti: Temporal Knowledge Graphs for Agentic Apps](https://blog.getzep.com/graphiti-knowledge-graphs-for-agents/)
- [Neo4j GraphRAG Documentation](https://neo4j.com/blog/developer/graphiti-knowledge-graph-memory/)
