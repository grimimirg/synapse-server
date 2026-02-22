#!/bin/bash

PARENT_DIR=$(cd "$(dirname "$0")/.." && pwd)
cd "$PARENT_DIR" || exit 1

# Matrix Server Deployment Script
echo "Matrix Server Deployment"
echo "DEBUG: Current directory: $(pwd)"

# Load main configuration
if [ ! -f "config.env" ]; then
    echo "ERROR: config.env not found!"
    exit 1
fi

# Export all variables from config.env
set -a
source config.env
set +a

# Load domain configuration from .env (if exists)
if [ -f ".env" ]; then
    echo "Loading domain configuration from .env..."
    set -a
    source .env
    set +a
    echo "Domain set to: $DOMAIN"
else
    echo "WARNING: .env file not found, using DOMAIN from config.env"
fi

# Verify DOMAIN is set
if [ -z "$DOMAIN" ]; then
    echo "ERROR: DOMAIN not defined in config.env or .env!"
    echo "Please set DOMAIN in one of these files"
    exit 1
fi

echo "Using DOMAIN: $DOMAIN"

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
    echo "SSL certificates found in ssl/ directory"
fi

# Create data directories
echo "Creating directories..."
mkdir -p data/postgres data/media_store

if [ ! -f "templates/docker-compose.yaml.template" ]; then
    echo "ERROR: templates/docker-compose.yaml.template not found!"
    exit 1
fi

# Generate docker-compose.yaml from template
echo "Generating configuration files..."
export DOMAIN POSTGRES_PASSWORD
envsubst < templates/docker-compose.yaml.template > docker-compose.yaml

if [ ! -f "templates/nginx.conf.template" ]; then
    echo "ERROR: templates/nginx.conf.template not found!"
    exit 1
fi

# Generate nginx.conf from template using sed (more reliable)
echo "Generating nginx.conf with DOMAIN=$DOMAIN..."
sed -e "s/\${DOMAIN}/$DOMAIN/g" \
    -e 's/${DOLLAR}/$/g' \
    templates/nginx.conf.template > nginx.conf

# Verify nginx.conf was generated correctly
if grep -q '${DOMAIN}' nginx.conf; then
    echo "ERROR: DOMAIN variable was not substituted in nginx.conf!"
    exit 1
fi

echo "nginx.conf generated successfully"

if [ ! -f "templates/homeserver.yaml.template" ]; then
    echo "ERROR: templates/homeserver.yaml.template not found!"
    exit 1
fi

# Generate homeserver.yaml from template
echo "Generating homeserver.yaml..."
envsubst < templates/homeserver.yaml.template > data/homeserver.yaml

if [ ! -f "templates/log.config.template" ]; then
    echo "ERROR: templates/log.config.template not found!"
    exit 1
fi

# Generate log.config from template
echo "Generating log.config..."
cp templates/log.config.template data/log.config

# Set correct permissions
echo "Setting permissions..."
if [ "$EUID" -eq 0 ]; then
    chown -R 991:991 data/
    echo "Permissions set for Synapse user (991:991)"
else
    echo "Warning: Not running as root. Setting permissions..."
    sudo chown -R 991:991 data/ || echo "Could not set ownership, continuing anyway..."
fi
chmod -R 755 data/
chmod 644 data/homeserver.yaml 2>/dev/null || true
chmod 644 data/log.config 2>/dev/null || true

# Start services
echo "Starting services..."
docker-compose up -d

echo "Deployment completed!"
echo "Matrix server: https://$DOMAIN"

# Wait for services to be ready
echo "Waiting for services to start..."
sleep 10

# Check status
echo "Checking status..."
docker-compose ps