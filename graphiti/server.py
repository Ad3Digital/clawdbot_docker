#!/usr/bin/env python3
"""
Graphiti REST API Server
Provides temporal knowledge graph operations for Clawdbot
"""
import os
from datetime import datetime
from typing import List, Optional
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import uvicorn
from graphiti_core import Graphiti
from graphiti_core.nodes import EpisodeType
from graphiti_core.llm_client import OpenAIClient, LLMConfig

# Configuration from environment
NEO4J_URI = os.getenv("NEO4J_URI", "bolt://localhost:7687")
NEO4J_USER = os.getenv("NEO4J_USER", "neo4j")
NEO4J_PASSWORD = os.getenv("NEO4J_PASSWORD", "graphitipass")
PORT = int(os.getenv("GRAPHITI_PORT", "8001"))

# LLM Configuration - Use CLIProxyAPI or OpenAI
OPENAI_API_KEY = os.getenv("OPENAI_API_KEY", "dummy-key-for-cliproxy")
OPENAI_BASE_URL = os.getenv("OPENAI_BASE_URL", "http://clawdbot:8317/v1")
LLM_MODEL = os.getenv("LLM_MODEL", "claude-sonnet-4-5-20250929")

# Initialize FastAPI
app = FastAPI(
    title="Graphiti API",
    description="Temporal Knowledge Graph for AI Agents",
    version="1.0.0"
)

# Initialize Graphiti client
graphiti = None

@app.on_event("startup")
async def startup_event():
    """Initialize Graphiti connection on startup"""
    global graphiti
    try:
        # Configure LLM to use CLIProxyAPI
        llm_config = LLMConfig(
            api_key=OPENAI_API_KEY,
            base_url=OPENAI_BASE_URL,
            model=LLM_MODEL
        )

        llm_client = OpenAIClient(config=llm_config)

        graphiti = Graphiti(
            NEO4J_URI,
            NEO4J_USER,
            NEO4J_PASSWORD,
            llm_client=llm_client
        )
        print(f"✓ Connected to Neo4j at {NEO4J_URI}")
        print(f"✓ Using LLM: {LLM_MODEL} via {OPENAI_BASE_URL}")
    except Exception as e:
        print(f"✗ Failed to initialize Graphiti: {e}")
        import traceback
        traceback.print_exc()
        raise

@app.on_event("shutdown")
async def shutdown_event():
    """Close Graphiti connection on shutdown"""
    global graphiti
    if graphiti:
        await graphiti.close()
        print("✓ Graphiti connection closed")

# Request/Response Models
class Episode(BaseModel):
    """Episode to add to the knowledge graph"""
    name: str
    episode_body: str
    source_description: str
    reference_time: Optional[datetime] = None
    episode_type: str = "message"

class SearchQuery(BaseModel):
    """Search query for the knowledge graph"""
    query: str
    num_results: int = 10
    group_ids: Optional[List[str]] = None

class FactSearchResult(BaseModel):
    """Search result from the knowledge graph"""
    uuid: str
    fact: str
    valid_at: datetime
    invalid_at: Optional[datetime]
    created_at: datetime

# API Endpoints
@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {
        "status": "healthy",
        "neo4j_uri": NEO4J_URI,
        "timestamp": datetime.now().isoformat()
    }

@app.post("/episodes")
async def add_episode(episode: Episode):
    """Add a new episode to the knowledge graph"""
    if not graphiti:
        raise HTTPException(status_code=503, detail="Graphiti not initialized")

    try:
        # Add episode to graph
        await graphiti.add_episode(
            name=episode.name,
            episode_body=episode.episode_body,
            source_description=episode.source_description,
            reference_time=episode.reference_time or datetime.now()
        )

        return {
            "status": "success",
            "message": f"Episode '{episode.name}' added successfully"
        }
    except Exception as e:
        import traceback
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/search")
async def search_facts(query: SearchQuery):
    """Search for facts in the knowledge graph"""
    if not graphiti:
        raise HTTPException(status_code=503, detail="Graphiti not initialized")

    try:
        # Search the graph
        results = await graphiti.search(
            query=query.query,
            num_results=query.num_results,
            group_ids=query.group_ids
        )

        # Format results
        formatted_results = [
            FactSearchResult(
                uuid=fact.uuid,
                fact=fact.fact,
                valid_at=fact.valid_at,
                invalid_at=fact.invalid_at,
                created_at=fact.created_at
            )
            for fact in results
        ]

        return {
            "query": query.query,
            "num_results": len(formatted_results),
            "results": formatted_results
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/stats")
async def get_stats():
    """Get knowledge graph statistics"""
    if not graphiti:
        raise HTTPException(status_code=503, detail="Graphiti not initialized")

    try:
        # This would need custom Cypher queries to Neo4j
        # For now, return basic info
        return {
            "status": "operational",
            "neo4j_uri": NEO4J_URI,
            "timestamp": datetime.now().isoformat()
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

if __name__ == "__main__":
    print(f"""
    ╔══════════════════════════════════════════╗
    ║   Graphiti Temporal Knowledge Graph     ║
    ║   Starting on port {PORT}                  ║
    ╚══════════════════════════════════════════╝
    """)
    uvicorn.run(app, host="0.0.0.0", port=PORT)
