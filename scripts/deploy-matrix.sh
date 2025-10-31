#!/bin/bash
set -e

echo "Matrix Server Deployment"

# Load config
source config.env

# Check prerequisites
if ! command -v docker &> /dev/null; then
    echo "ERROR: Docker not installed!"
    exit 1
fi

if ! command -v docker-compose &> /dev/null; then
    echo "ERROR: Docker Compose not installed!"
    exit 1
fi

if [ ! -f "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" ]; then
    echo "ERROR: SSL certificates not found! Run setup-ssl.sh first"
    exit 1
fi

echo "Creating directories..."
mkdir -p data/synapse data/postgresql

echo "Generating configuration files..."
# Export variables for template substitution
export DOMAIN EMAIL POSTGRES_PASSWORD SYNAPSE_REGISTRATION_SHARED_SECRET

# Generate files from templates
envsubst < templates/docker-compose.yml.template > docker-compose.yml
envsubst < templates/nginx.conf.template > nginx.conf

# Generate Synapse config if needed
if [ ! -f "data/synapse/homeserver.yaml" ]; then
    echo "Generating Synapse configuration..."
    docker run -it --rm \
        -v "$PWD/data/synapse:/data" \
        -e SYNAPSE_SERVER_NAME="$DOMAIN" \
        -e SYNAPSE_REPORT_STATS=no \
        matrixdotorg/synapse:latest generate
    
    # Apply our template
    envsubst < templates/homeserver.yaml.template > data/synapse/homeserver.yaml
fi

echo "Starting services..."
# Start database first
docker-compose up -d postgres
sleep 10

# Start Synapse
docker-compose up -d synapse
sleep 15

# Start nginx
docker-compose up -d nginx

echo "Checking status..."
docker-compose ps

echo "Deployment completed!"
echo "Matrix server: https://$DOMAIN"
echo "Create admin user: docker-compose exec synapse register_new_matrix_user -c /data/homeserver.yaml http://localhost:8008"
