#!/bin/bash

# Matrix Server Deployment Script
echo "Matrix Server Deployment"

# Load main configuration
if [ ! -f "config.env" ]; then
    echo "ERROR: config.env not found!"
    exit 1
fi

source config.env

# Load domain configuration from .env (if exists)
if [ -f ".env" ]; then
    echo "Loading domain configuration from .env..."
    export $(cat nginx.env | grep -v '^#' | xargs)
    echo "Domain set to: $DOMAIN"
else
    echo "WARNING: nginx.env file not found, using DOMAIN from config.env"
    if [ -z "$DOMAIN" ]; then
        echo "ERROR: DOMAIN not defined in config.env or .env!"
        echo "Create .env file with: DOMAIN=your-domain.com"
        exit 1
    fi
fi

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "ERROR: Docker is not installed!"
    exit 1
fi

# Check if Docker Compose is installed
if ! command -v docker-compose &> /dev/null; then
    echo "ERROR: Docker Compose is not installed!"
    exit 1
fi

# Check SSL certificates in local ssl directory
if [ ! -f "ssl/fullchain.pem" ] || [ ! -f "ssl/privkey.pem" ]; then
    echo "ERROR: SSL certificates not found in ssl/ directory!"
    echo "Run setup-ssl.sh first or copy certificates manually to ssl/"
    exit 1
else
    echo "✅ SSL certificates found in ssl/ directory"
fi

# Create data directories
echo "Creating directories..."
mkdir -p data/postgres data/media_store

# Generate docker-compose.yml from template
echo "Generating configuration files..."
envsubst < templates/docker-compose.yml.template > docker-compose.yml

# Generate nginx.conf from template
echo "Generating nginx.conf with DOMAIN=$DOMAIN..."
envsubst '${DOMAIN}' < templates/nginx.conf.template > nginx.conf

# Generate homeserver.yaml from template
envsubst < templates/homeserver.yaml.template > homeserver.yaml

# Start services
echo "Starting services..."
docker-compose up -d

# Wait for services to be ready
echo "Waiting for services to start..."
sleep 10

# Check status
echo "Checking status..."
docker-compose ps

echo ""
echo "Deployment completed!"
echo "Matrix server: https://$DOMAIN"
echo "Create admin user: docker-compose exec synapse register_new_matrix_user -c /data/homeserver.yaml http://localhost:8008"