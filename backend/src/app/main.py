# backend/src/app/main.py
# 💭 DREAM CONTAINER - HTMX-Powered FastAPI Backend
# The ultimate anti-bureaucracy backend that serves beautiful HTML fragments

from fastapi import FastAPI, HTTPException, Form, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import HTMLResponse, JSONResponse
from fastapi.templating import Jinja2Templates
import redis
import psycopg2
from psycopg2.extras import RealDictCursor
import os
from datetime import datetime
from typing import List, Dict, Any, Optional
import json
import asyncio
import time
import psutil

# Create FastAPI app with dream branding
app = FastAPI(
    title="💭 Dream Container API",
    description="HTMX-powered backend that transcends bureaucracy",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc"
)

# Enable CORS for frontend dreams (configure appropriately for production)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Database and Redis configuration
DATABASE_URL = os.getenv("DATABASE_URL", "postgresql://dream_user:secure_dream_2025@db:5432/dream_db")
REDIS_URL = os.getenv("REDIS_URL", "redis://redis:6379")

# Redis connection
try:
    redis_client = redis.from_url(REDIS_URL, decode_responses=True)
except Exception as e:
    print(f"Redis connection failed: {e}")
    redis_client = None

def get_db_connection():
    """Get database connection for data dreams"""
    try:
        url_parts = DATABASE_URL.replace("postgresql+asyncpg://", "postgresql://")
        conn = psycopg2.connect(url_parts, cursor_factory=RealDictCursor)
        return conn
    except Exception as e:
        print(f"Database connection failed: {e}")
        return None

@app.on_event("startup")
async def startup_event():
    """Initialize database tables for your dreams"""
    conn = get_db_connection()
    if conn:
        try:
            cursor = conn.cursor()
            
            # Create dreams table
            cursor.execute("""
                CREATE TABLE IF NOT EXISTS dreams (
                    id SERIAL PRIMARY KEY,
                    title VARCHAR(255) NOT NULL,
                    description TEXT,
                    dreamer_name VARCHAR(100),
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    is_realized BOOLEAN DEFAULT FALSE
                )
            """)
            
            # Insert some example dreams if table is empty
            cursor.execute("SELECT COUNT(*) as count FROM dreams")
            count = cursor.fetchone()['count']
            
            if count == 0:
                cursor.execute("""
                    INSERT INTO dreams (title, description, dreamer_name, is_realized) 
                    VALUES 
                        ('Build the perfect devcontainer', 'Create a development environment that just works', 'Dream Team', TRUE),
                        ('Master HTMX + Tailwind', 'Learn the anti-bureaucracy frontend stack', 'Modern Developer', TRUE),
                        ('Transcend all bureaucracy', 'Eliminate complexity from development forever', 'Visionary Coder', FALSE),
                        ('Scale to millions', 'Build an app that changes the world', 'Ambitious Dreamer', FALSE)
                """)
            
            conn.commit()
            cursor.close()
            conn.close()
            print("💭 Database initialized with example dreams!")
            
        except Exception as e:
            print(f"Database initialization failed: {e}")

# =============================================
# 🌐 MAIN ROUTES (JSON API)
# =============================================

@app.get("/", response_class=HTMLResponse)
async def root():
    """Beautiful welcome page for your Dream Container API"""
    return """
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>💭 Dream Container API</title>
        <script src="https://cdn.tailwindcss.com"></script>
        <script>
            tailwind.config = {
                theme: {
                    extend: {
                        backgroundImage: {
                            'dream-gradient': 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
                        }
                    }
                }
            }
        </script>
    </head>
    <body class="bg-dream-gradient min-h-screen text-white">
        <div class="container mx-auto px-4 py-16 text-center">
            <h1 class="text-6xl font-bold mb-4">💭 Dream Container API</h1>
            <p class="text-2xl mb-8 opacity-90">Transcending bureaucracy since 2025</p>
            
            <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6 max-w-4xl mx-auto">
                <a href="/docs" class="bg-white/10 backdrop-blur-lg rounded-xl p-6 hover:bg-white/20 transition-all duration-300 border border-white/20">
                    <h3 class="text-xl font-bold mb-2">📖 API Docs</h3>
                    <p class="opacity-80">Interactive OpenAPI documentation</p>
                </a>
                <a href="/health" class="bg-white/10 backdrop-blur-lg rounded-xl p-6 hover:bg-white/20 transition-all duration-300 border border-white/20">
                    <h3 class="text-xl font-bold mb-2">🏥 Health Check</h3>
                    <p class="opacity-80">System status and diagnostics</p>
                </a>
                <a href="http://localhost:3000" class="bg-white/10 backdrop-blur-lg rounded-xl p-6 hover:bg-white/20 transition-all duration-300 border border-white/20">
                    <h3 class="text-xl font-bold mb-2">✨ Frontend</h3>
                    <p class="opacity-80">Beautiful HTMX interface</p>
                </a>
            </div>
            
            <div class="mt-12 bg-white/10 backdrop-blur-lg rounded-xl p-8 max-w-2xl mx-auto border border-white/20">
                <h2 class="text-2xl font-bold mb-4">🚀 HTMX + FastAPI + Tailwind</h2>
                <p class="text-lg opacity-90 leading-relaxed">
                    You're running a complete full-stack application with modern, 
                    anti-bureaucracy technologies. No React complexity, no build processes, 
                    just pure development dreams!
                </p>
            </div>
        </div>
    </body>
    </html>
    """

@app.get("/health")
async def health_check():
    """Health check endpoint for monitoring your dreams"""
    status = {
        "status": "healthy",
        "message": "💭 Dream Container API is transcending bureaucracy!",
        "timestamp": datetime.now().isoformat(),
        "services": {}
    }
    
    # Check Redis connection
    if redis_client:
        try:
            redis_client.ping()
            status["services"]["redis"] = "✅ Dreams cached successfully"
        except:
            status["services"]["redis"] = "❌ Dream caching unavailable"
    else:
        status["services"]["redis"] = "❌ Dream caching not configured"
    
    # Check Database connection
    conn = get_db_connection()
    if conn:
        try:
            cursor = conn.cursor()
            cursor.execute("SELECT 1")
            cursor.close()
            conn.close()
            status["services"]["database"] = "✅ Dream data flowing"
        except:
            status["services"]["database"] = "❌ Dream data unavailable"
    else:
        status["services"]["database"] = "❌ Dream database not connected"
    
    return status

@app.get("/dreams")
async def get_dreams():
    """Get all dreams from the database (JSON response)"""
    conn = get_db_connection()
    if not conn:
        raise HTTPException(status_code=500, detail="Database connection failed")
    
    try:
        cursor = conn.cursor()
        cursor.execute("""
            SELECT id, title, description, dreamer_name, created_at, is_realized 
            FROM dreams 
            ORDER BY created_at DESC
        """)
        dreams = cursor.fetchall()
        cursor.close()
        conn.close()
        
        return {
            "message": "💭 Here are all the dreams in our container!",
            "dreams": [dict(dream) for dream in dreams]
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Dream retrieval failed: {str(e)}")

@app.get("/stats")
async def get_stats():
    """Get statistics about dreams in the system"""
    conn = get_db_connection()
    if not conn:
        raise HTTPException(status_code=500, detail="Database connection failed")
    
    try:
        cursor = conn.cursor()
        
        cursor.execute("SELECT COUNT(*) as total_dreams FROM dreams")
        total_dreams = cursor.fetchone()['total_dreams']
        
        cursor.execute("SELECT COUNT(*) as realized_dreams FROM dreams WHERE is_realized = TRUE")
        realized_dreams = cursor.fetchone()['realized_dreams']
        
        cursor.execute("SELECT COUNT(DISTINCT dreamer_name) as unique_dreamers FROM dreams")
        unique_dreamers = cursor.fetchone()['unique_dreamers']
        
        cursor.close()
        conn.close()
        
        return {
            "message": "📊 Dream Container Statistics",
            "stats": {
                "total_dreams": total_dreams,
                "realized_dreams": realized_dreams,
                "dreams_in_progress": total_dreams - realized_dreams,
                "unique_dreamers": unique_dreamers,
                "success_rate": f"{(realized_dreams/total_dreams*100):.1f}%" if total_dreams > 0 else "0%"
            }
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Stats retrieval failed: {str(e)}")

# =============================================
# ✨ HTMX ENDPOINTS (HTML Fragment Responses)
# =============================================

@app.get("/htmx/health", response_class=HTMLResponse)
async def htmx_health():
    """HTMX endpoint for health dashboard HTML"""
    health_data = await health_check()
    
    health_cards = []
    for service, status in health_data["services"].items():
        is_healthy = "✅" in status
        status_class = "text-green-400" if is_healthy else "text-red-400"
        
        health_cards.append(f"""
        <div class="bg-white/10 backdrop-blur-lg rounded-lg p-6 text-center border border-white/20 hover:scale-105 transition-transform duration-300">
            <h3 class="text-lg font-semibold mb-2 capitalize">{service.replace('_', ' ')}</h3>
            <p class="{status_class} font-bold">{status}</p>
        </div>
        """)
    
    return "".join(health_cards)

@app.get("/htmx/stats", response_class=HTMLResponse)
async def htmx_stats():
    """HTMX endpoint for statistics dashboard HTML"""
    stats_data = await get_stats()
    stats = stats_data["stats"]
    
    stat_cards = [
        ("Total Dreams", stats["total_dreams"], "🌟"),
        ("Realized", stats["realized_dreams"], "✅"),
        ("In Progress", stats["dreams_in_progress"], "⏳"),
        ("Success Rate", stats["success_rate"], "📈"),
    ]
    
    cards_html = []
    for title, value, emoji in stat_cards:
        cards_html.append(f"""
        <div class="bg-white/10 backdrop-blur-lg rounded-lg p-6 text-center border border-white/20 hover:scale-105 hover:bg-white/15 transition-all duration-300">
            <h3 class="text-sm font-medium mb-2 opacity-90">{title}</h3>
            <p class="text-3xl font-bold text-yellow-400 drop-shadow-lg">{emoji} {value}</p>
        </div>
        """)
    
    return "".join(cards_html)

@app.get("/htmx/dreams", response_class=HTMLResponse)
async def htmx_dreams():
    """HTMX endpoint for dreams list HTML"""
    dreams_data = await get_dreams()
    dreams = dreams_data["dreams"]
    
    if not dreams:
        return """
        <div class="text-center p-8 opacity-70">
            <p class="text-xl">💭 No dreams yet... be the first to dream!</p>
        </div>
        """
    
    dreams_html = []
    for dream in dreams:
        # Format the date nicely
        created_date = datetime.fromisoformat(str(dream["created_at"]).replace("Z", "+00:00"))
        formatted_date = created_date.strftime("%B %d, %Y")
        
        # Determine status styling
        if dream["is_realized"]:
            status_bg = "bg-green-500/20"
            status_text = "text-green-400"
            status_icon = "✅"
            status_label = "Realized"
            border_color = "border-green-400/30"
        else:
            status_bg = "bg-yellow-500/20"
            status_text = "text-yellow-400"
            status_icon = "⏳"
            status_label = "In Progress"
            border_color = "border-yellow-400/30"
        
        dreams_html.append(f"""
        <div class="bg-white/10 backdrop-blur-lg rounded-lg p-6 border border-white/20 hover:shadow-xl hover:-translate-y-1 transition-all duration-300 relative overflow-hidden">
            <div class="absolute top-0 left-0 right-0 h-1 bg-gradient-to-r from-yellow-400 to-yellow-600"></div>
            
            <div class="mb-4">
                <h3 class="text-xl font-bold text-yellow-400 mb-2">{dream['title']}</h3>
                <p class="opacity-90 leading-relaxed">{dream['description'] or 'No description provided'}</p>
            </div>
            
            <div class="flex justify-between items-center text-sm">
                <div class="flex items-center space-x-4">
                    <span class="opacity-80">👤 {dream['dreamer_name']}</span>
                    <span class="opacity-60">📅 {formatted_date}</span>
                </div>
                <span class="{status_bg} {status_text} px-3 py-1 rounded-full text-xs font-bold border {border_color}">
                    {status_icon} {status_label}
                </span>
            </div>
        </div>
        """)
    
    return "".join(dreams_html)

@app.post("/htmx/dreams", response_class=HTMLResponse)
async def htmx_create_dream(
    title: str = Form(...),
    description: str = Form(""),
    dreamer_name: str = Form(...)
):
    """HTMX endpoint for creating a new dream (returns new dream HTML)"""
    conn = get_db_connection()
    if not conn:
        return """
        <div class="bg-red-500/20 border border-red-500/30 rounded-lg p-4 text-red-400">
            ❌ Database connection failed
        </div>
        """
    
    try:
        cursor = conn.cursor()
        cursor.execute("""
            INSERT INTO dreams (title, description, dreamer_name) 
            VALUES (%s, %s, %s)
            RETURNING id, title, description, dreamer_name, created_at, is_realized
        """, (title, description, dreamer_name))
        
        new_dream = cursor.fetchone()
        conn.commit()
        cursor.close()
        conn.close()
        
        # Cache in Redis for faster access
        if redis_client:
            try:
                redis_client.setex(
                    f"dream:{new_dream['id']}", 
                    3600,  # 1 hour cache
                    json.dumps(dict(new_dream), default=str)
                )
            except:
                pass  # Cache failure shouldn't break the API
        
        # Format the new dream as HTML
        created_date = datetime.now().strftime("%B %d, %Y")
        
        return f"""
        <div class="bg-white/10 backdrop-blur-lg rounded-lg p-6 border border-white/20 hover:shadow-xl hover:-translate-y-1 transition-all duration-300 relative overflow-hidden animate-pulse">
            <div class="absolute top-0 left-0 right-0 h-1 bg-gradient-to-r from-green-400 to-green-600"></div>
            
            <div class="mb-4">
                <h3 class="text-xl font-bold text-yellow-400 mb-2">{new_dream['title']}</h3>
                <p class="opacity-90 leading-relaxed">{new_dream['description'] or 'No description provided'}</p>
            </div>
            
            <div class="flex justify-between items-center text-sm">
                <div class="flex items-center space-x-4">
                    <span class="opacity-80">👤 {new_dream['dreamer_name']}</span>
                    <span class="opacity-60">📅 {created_date}</span>
                </div>
                <span class="bg-yellow-500/20 text-yellow-400 px-3 py-1 rounded-full text-xs font-bold border border-yellow-400/30">
                    ⏳ In Progress
                </span>
            </div>
            
            <div class="absolute -top-2 -right-2 bg-green-500 text-white text-xs px-2 py-1 rounded-full animate-bounce">
                ✨ New!
            </div>
        </div>
        """
        
    except Exception as e:
        return f"""
        <div class="bg-red-500/20 border border-red-500/30 rounded-lg p-4 text-red-400">
            ❌ Dream creation failed: {str(e)}
        </div>
        """

@app.get("/htmx/performance", response_class=HTMLResponse)
async def htmx_performance():
    """HTMX endpoint for performance metrics HTML"""
    try:
        # Get system performance metrics
        cpu_percent = psutil.cpu_percent(interval=1)
        memory = psutil.virtual_memory()
        disk = psutil.disk_usage('/')
        
        # Get dream-specific metrics
        conn = get_db_connection()
        total_dreams = 0
        if conn:
            try:
                cursor = conn.cursor()
                cursor.execute("SELECT COUNT(*) as count FROM dreams")
                total_dreams = cursor.fetchone()['count']
                cursor.close()
                conn.close()
            except:
                pass
        
        # Create performance display
        return f"""
        <div class="grid grid-cols-2 md:grid-cols-4 gap-4 text-center">
            <div class="bg-white/10 rounded-lg p-3 border border-white/20">
                <div class="text-xs opacity-80">CPU Usage</div>
                <div class="text-lg font-bold text-blue-400">{cpu_percent:.1f}%</div>
            </div>
            <div class="bg-white/10 rounded-lg p-3 border border-white/20">
                <div class="text-xs opacity-80">Memory</div>
                <div class="text-lg font-bold text-green-400">{memory.percent:.1f}%</div>
            </div>
            <div class="bg-white/10 rounded-lg p-3 border border-white/20">
                <div class="text-xs opacity-80">Disk</div>
                <div class="text-lg font-bold text-purple-400">{disk.percent:.1f}%</div>
            </div>
            <div class="bg-white/10 rounded-lg p-3 border border-white/20">
                <div class="text-xs opacity-80">Dreams</div>
                <div class="text-lg font-bold text-yellow-400">{total_dreams}</div>
            </div>
        </div>
        <div class="mt-4 text-center text-sm opacity-70">
            ⚡ Updated every 10 seconds • 💭 Living the dream since {datetime.now().strftime('%H:%M')}
        </div>
        """
        
    except Exception as e:
        return f"""
        <div class="text-center text-red-400">
            ❌ Performance metrics unavailable: {str(e)}
        </div>
        """

# =============================================
# 🎯 UTILITY ENDPOINTS
# =============================================

@app.get("/cache-test")
async def cache_test():
    """Test Redis caching functionality"""
    if not redis_client:
        return {"message": "❌ Redis not available for caching dreams"}
    
    try:
        test_key = "dream_container_test"
        test_value = f"💭 Dream Container cached at {datetime.now().isoformat()}"
        
        redis_client.setex(test_key, 60, test_value)
        cached_value = redis_client.get(test_key)
        
        return {
            "message": "✅ Redis caching is working perfectly!",
            "cached_value": cached_value,
            "cache_info": "Dreams are being cached for optimal performance"
        }
        
    except Exception as e:
        return {"message": f"❌ Cache test failed: {str(e)}"}

@app.get("/environment")
async def get_environment():
    """Show environment information"""
    return {
        "message": "🌍 Dream Container Environment",
        "framework": "FastAPI + HTMX + Tailwind CSS",
        "environment": os.getenv("ENVIRONMENT", "development"),
        "python_version": "3.12",
        "api_docs": "/docs",
        "frontend": "http://localhost:3000",
        "container_status": "💭 Living the dream!",
        "transcendence_level": "Bureaucracy successfully transcended ✨",
        "anti_bureaucracy_stack": ["HTMX", "Tailwind", "FastAPI", "PostgreSQL", "Redis"]
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000, reload=True)