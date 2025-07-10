# frontend/Dockerfile
# 💭 DREAM CONTAINER - Elegant HTMX Frontend (Transcending React Bureaucracy!)
# Simple, fast, beautiful - the way frontend should be

FROM nginx:alpine

# Copy static assets for your frontend dreams
COPY static/ /usr/share/nginx/html/static/

# Copy HTML templates (nginx will serve them directly)
COPY templates/pages/ /usr/share/nginx/html/

# Create nginx configuration for HTMX-optimized serving
RUN cat > /etc/nginx/conf.d/default.conf << 'EOF'
server {
    listen 80;
    server_name localhost;
    root /usr/share/nginx/html;
    index index.html;

    # Serve static assets with long cache for dreams
    location /static/ {
        expires 1y;
        add_header Cache-Control "public, immutable";
        access_log off;
    }
    
    # Serve HTML pages for your dream frontend
    location / {
        try_files $uri $uri.html $uri/ =404;
        add_header X-Dream-Container "Transcending bureaucracy with HTMX ✨";
    }
    
    # Health check for dream monitoring
    location /health {
        access_log off;
        return 200 "💭 Frontend dreams are flowing!";
        add_header Content-Type text/plain;
    }
}
EOF

# Health check for monitoring your frontend dreams
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost/health || exit 1

# Expose port for your frontend dreams
EXPOSE 80

# Start nginx with dream-optimized config
CMD ["nginx", "-g", "daemon off;"]