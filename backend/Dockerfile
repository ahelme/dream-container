# backend/Dockerfile
# 💭 DREAM CONTAINER - Example FastAPI Backend
# A simple but powerful example API to demonstrate your dreams in action

FROM python:3.12-slim

# Set working directory for backend dreams
WORKDIR /app

# Install system dependencies for API dreams
RUN apt-get update && apt-get install -y \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements first for optimal caching
COPY requirements.txt .

# Install Python dependencies for your API dreams
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY . .

# Create a non-root user for security dreams
RUN useradd --create-home --shell /bin/bash app \
    && chown -R app:app /app
USER app

# Health check for monitoring your API dreams
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8000/health || exit 1

# Expose port for your API dreams
EXPOSE 8000

# Start the API server with reload for development dreams
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000", "--reload"]