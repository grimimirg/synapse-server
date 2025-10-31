#!/bin/bash
set -e

echo "Matrix Server SSL Setup"

# Load config
source config.env

# Check required variables
if [ -z "$DOMAIN" ] || [ -z "$EMAIL" ]; then
    echo "ERROR: Set DOMAIN and EMAIL in config.env"
    exit 1
fi

echo "Domain: $DOMAIN"
echo "Email: $EMAIL"

# Install certbot
if ! command -v certbot &> /dev/null; then
    echo "Installing certbot..."
    sudo apt update && sudo apt install -y certbot
fi

# Stop nginx if running
docker-compose stop nginx 2>/dev/null || true

# Get certificates
echo "Getting SSL certificates..."
sudo certbot certonly \
    --standalone \
    -d "$DOMAIN" \
    --email "$EMAIL" \
    --agree-tos \
    --non-interactive

# Verify certificates exist
if [ -f "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" ]; then
    echo "SSL certificates obtained successfully!"
else
    echo "ERROR: Certificate files not found!"
    exit 1
fi

# Setup auto-renewal
echo "Setting up auto-renewal..."
cat > ~/renew-cert.sh << EOF
#!/bin/bash
docker-compose stop nginx
sudo certbot renew --quiet
docker-compose start nginx
EOF

chmod +x ~/renew-cert.sh
(crontab -l 2>/dev/null; echo "0 3 1 * * ~/renew-cert.sh") | crontab -

echo "SSL setup completed!"
