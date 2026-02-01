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

# Configuration from environment
NEO4J_URI = os.getenv("NEO4J_URI", "bolt://localhost:7687")
NEO4J_USER = os.getenv("NEO4J_USER", "neo4j")
NEO4J_PASSWORD = os.getenv("NEO4J_PASSWORD", "graphitipass")
PORT = int(os.getenv("GRAPHITI_PORT", "8001"))

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
        graphiti = Graphiti(NEO4J_URI, NEO4J_USER, NEO4J_PASSWORD)
        print(f"✓ Connected to Neo4j at {NEO4J_URI}")
    except Exception as e:
        print(f"✗ Failed to connect to Neo4j: {e}")
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
        raise HTTPException(status_code=503, message="Graphiti not initialized")

    try:
        # Convert episode type string to enum
        ep_type = EpisodeType.message
        if episode.episode_type.lower() == "json":
            ep_type = EpisodeType.json

        # Add episode to graph
        await graphiti.add_episode(
            name=episode.name,
            episode_body=episode.episode_body,
            source_description=episode.source_description,
            reference_time=episode.reference_time or datetime.now(),
            episode_type=ep_type
        )

        return {
            "status": "success",
            "message": f"Episode '{episode.name}' added successfully"
        }
    except Exception as e:
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
