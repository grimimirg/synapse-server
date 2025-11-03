# 🚀 Matrix Synapse Server with Docker

A complete, production-ready Matrix Synapse server setup using Docker, PostgreSQL, and Nginx reverse proxy with automatic SSL certificates.

## 📋 Table of Contents

*   [Features](#features)
*   [Prerequisites](#prerequisites)
*   [Quick Start](#quick-start)
*   [Configuration](#configuration)
*   [Deployment](#deployment)
*   [User Management](#user-management)
*   [Maintenance](#maintenance)
*   [Troubleshooting](#troubleshooting)
*   [Project Structure](#project-structure)
*   [SSL Certificate Management](#ssl-certificate-management)

## ✨ Features

**🐳 Dockerized**  
Complete containerized setup

**🔒 SSL/TLS**  
Automatic Let's Encrypt certificates

**🔄 Reverse Proxy**  
Nginx with proper Matrix configuration

**📊 PostgreSQL**  
Robust database backend

**🌐 Federation**  
Ready for Matrix federation

**👥 User Management**  
Scripts for easy user creation

**🔧 Easy Maintenance**  
Automated scripts for common tasks

## 📋 Prerequisites

*   **Linux Server** (Ubuntu 20.04+ recommended)
*   **Domain Name** pointing to your server
*   **Docker** (v20.10+)
*   **Docker Compose** (v1.29+)
*   **Ports Open**: 80, 443, 8448
*   **Root/Sudo Access**

## ⚡ Quick Start

### 1\. Clone and Setup

```
# Clone the repository
git clone <your-repo-url>
cd synapse-server

# Make scripts executable
chmod +x scripts/*.sh
```

### 2\. Configure Environment

#### - Edit the main configuration file

```
nano config.env
```
Set your values:

```
# Your domain name
DOMAIN=yourdomain.com

# Email for Let's Encrypt certificates
EMAIL=your-email@example.com

# Database password (use a strong password)
POSTGRES_PASSWORD=your_secure_database_password

# Registration secret (use a random string)
SYNAPSE_REGISTRATION_SHARED_SECRET=your_very_long_random_secret
```

####  - Edit the nginx configuration file

```
nano .env
```

Set your domain value:

```
# Your domain name
DOMAIN=yourdomain.com
```

### 3\. Generate SSL Certificates

```
# This will get Let's Encrypt certificates and copy them to ssl/ directory
./scripts/setup-ssl.sh
```

### 4\. Deploy Matrix Server

```
# This will start all services (PostgreSQL, Synapse, Nginx)
./scripts/deploy-matrix.sh
```

### 5\. Create Your First Admin User

```
# Interactive user creation
./scripts/create-user.sh
```

## ⚙️ Configuration

### Main Configuration File: `config.env`

This file contains all the essential configuration for your Matrix server:

| Variable | Description | Example |
| --- | --- | --- |
| `DOMAIN` | Your server domain | `matrix.example.com` |
| `EMAIL` | Email for Let's Encrypt | `admin@example.com` |
| `POSTGRES_PASSWORD` | Database password | `super_secure_password` |
| `SYNAPSE_REGISTRATION_SHARED_SECRET` | User registration secret | `very_long_random_string` |

### Nginx Configuration: `nginx.conf`

After running the deployment script, you'll have a generated `nginx.conf` file. Here's the template structure you should verify:

```
# Minimal Nginx configuration for Matrix
events {
    worker_connections 1024;
}

http {
    # Basic settings
    include /etc/nginx/mime.types;
    sendfile on;
    
    # Upstream for Synapse
    upstream synapse {
        server synapse:8008;
    }
    
    # HTTP server - redirects to HTTPS
    server {
        listen 80;
        server_name YOUR_DOMAIN_HERE;
        
        # Matrix well-known for server discovery
        location /.well-known/matrix/server {
            return 200 '{"m.server": "YOUR_DOMAIN_HERE:8448"}';
            add_header Content-Type application/json;
            add_header Access-Control-Allow-Origin *;
        }
        
        # Matrix client discovery
        location /.well-known/matrix/client {
            return 200 '{"m.homeserver":{"base_url":"https://YOUR_DOMAIN_HERE"}}';
            add_header Content-Type application/json;
            add_header Access-Control-Allow-Origin *;
        }
        
        # Redirect everything else to HTTPS
        location / {
            return 301 https://$host$request_uri;
        }
    }
    
    # HTTPS server for Matrix clients
    server {
        listen 443 ssl;
        server_name YOUR_DOMAIN_HERE;
        
        # SSL certificates (from local ssl directory)
        ssl_certificate /etc/ssl/certs/fullchain.pem;
        ssl_certificate_key /etc/ssl/certs/privkey.pem;
        
        # Matrix API
        location /_matrix {
            proxy_pass http://synapse;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            
            # WebSocket support
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "upgrade";
            
            client_max_body_size 50M;
        }
    }
    
    # Federation server
    server {
        listen 8448 ssl;
        server_name YOUR_DOMAIN_HERE;
        
        # SSL certificates (from local ssl directory)
        ssl_certificate /etc/ssl/certs/fullchain.pem;
        ssl_certificate_key /etc/ssl/certs/privkey.pem;
        
        # All federation traffic goes to Synapse
        location / {
            proxy_pass http://synapse;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            
            client_max_body_size 50M;
        }
    }
}
```

**Note**: Replace `YOUR_DOMAIN_HERE` with your actual domain. The deployment script handles this automatically using the `DOMAIN` variable from `config.env`.

## 🚀 Deployment

### Start Services

```
# Start all services in background
docker-compose up -d

# Check status
docker-compose ps

# View logs
docker-compose logs -f synapse
docker-compose logs -f nginx
```

### Stop Services

```
# Stop all services
docker-compose down
```

**⚠️ Warning:** The following command will delete all data!

```
# Stop and remove volumes
docker-compose down -v
```

### Update Services

```
# Pull latest images
docker-compose pull

# Restart with new images
docker-compose up -d
```

## 👥 User Management

### Create Single User (Interactive)

```
./scripts/create-user.sh
```

This script will prompt you for:

*   Username
*   Password
*   Admin privileges (y/N)

### Batch User Creation

**1\. Create users file**:

```
# Edit the users.txt file
nano users.txt
```

**2\. Add users** (format: `username:password:admin_flag`):

```
alice:secure_password_123:true
bob:another_password_456:false
charlie:third_password_789:false
```

**3\. Run batch creation**:

```
./scripts/batch-create-users.sh
```

### Manual User Creation

```
# Create admin user
docker-compose exec synapse register_new_matrix_user \
    -c /data/homeserver.yaml \
    -u username \
    -p password \
    --admin \
    http://localhost:8008

# Create regular user
docker-compose exec synapse register_new_matrix_user \
    -c /data/homeserver.yaml \
    -u username \
    -p password \
    http://localhost:8008
```

## 🔧 Maintenance

### Backup Data

```
# Backup PostgreSQL database
docker-compose exec postgres pg_dump -U synapse synapse > backup_$(date +%Y%m%d).sql

# Backup media files
tar -czf media_backup_$(date +%Y%m%d).tar.gz data/media_store/
```

### Restore Data

```
# Restore PostgreSQL database
cat backup_20231102.sql | docker-compose exec -T postgres psql -U synapse -d synapse

# Restore media files
tar -xzf media_backup_20231102.tar.gz
```

### Update SSL Certificates

```
# Renew certificates (automatic via cron)
sudo certbot renew

# Manual renewal and copy to ssl/ directory
./scripts/setup-ssl.sh
```

### Monitor Services

```
# Check service health
docker-compose exec synapse curl http://localhost:8008/health

# Check federation
curl https://yourdomain.com:8448/_matrix/federation/v1/version

# Check client API
curl https://yourdomain.com/_matrix/client/versions
```

## 🔍 Troubleshooting

### Common Issues

#### 1\. SSL Certificate Errors

```
# Check certificate files
ls -la ssl/

# Verify certificates are valid
openssl x509 -in ssl/fullchain.pem -text -noout

# Re-run SSL setup
./scripts/setup-ssl.sh
```

#### 2\. Database Connection Issues

```
# Check PostgreSQL logs
docker-compose logs postgres

# Connect to database manually
docker-compose exec postgres psql -U synapse -d synapse
```

#### 3\. Nginx Configuration Errors

```
# Test nginx configuration
docker-compose exec nginx nginx -t

# Reload nginx configuration
docker-compose restart nginx
```

#### 4\. Synapse Not Starting

```
# Check Synapse logs
docker-compose logs synapse

# Check homeserver.yaml syntax
docker-compose exec synapse python -m yaml homeserver.yaml
```

### Service Status Check

```
# Quick health check
curl -f http://localhost:8008/health || echo "Synapse not responding"
curl -f https://yourdomain.com/_matrix/client/versions || echo "Nginx not working"
```

### Reset Everything

**⚠️ WARNING:** This will delete all data!

```
docker-compose down -v
sudo rm -rf data/
./scripts/deploy-matrix.sh
```

## 📁 Project Structure

```
synapse-server/
├── config.env                 # Main configuration file
├── docker-compose.yml         # Generated from template
├── nginx.conf                 # Generated from template  
├── homeserver.yaml            # Generated from template
├── scripts/
│   ├── setup-ssl.sh          # SSL certificate setup
│   ├── deploy-matrix.sh      # Main deployment script
│   ├── create-user.sh        # Interactive user creation
│   └── batch-create-users.sh # Batch user creation
├── templates/
│   ├── docker-compose.yml.template
│   ├── nginx.conf.template
│   └── homeserver.yaml.template
├── ssl/
│   ├── fullchain.pem         # SSL certificate
│   └── privkey.pem           # SSL private key
├── data/
│   ├── postgres/             # PostgreSQL data
│   └── media_store/          # Matrix media files
└── users.txt                 # Batch user creation file
```

## 🔒 SSL Certificate Management

### Automatic Renewal

The setup script configures automatic certificate renewal via cron. Check with:

```
sudo crontab -l | grep certbot
```

### Manual Certificate Management

```
# Check certificate expiration
sudo certbot certificates

# Renew specific certificate
sudo certbot renew --cert-name yourdomain.com

# Copy renewed certificates to ssl/ directory
sudo cp /etc/letsencrypt/live/yourdomain.com/fullchain.pem ssl/
sudo cp /etc/letsencrypt/live/yourdomain.com/privkey.pem ssl/
sudo chown $USER:$USER ssl/*

# Restart nginx to load new certificates
docker-compose restart nginx
```

### 🎯 Testing Your Setup

#### Federation Test

Test if your server can communicate with other Matrix servers:

```
# Test federation endpoint
curl https://yourdomain.com:8448/_matrix/federation/v1/version

# Test with federation tester (external tool)
curl "https://federationtester.matrix.org/api/report?server_name=yourdomain.com"
```

#### Client Connection Test

```
# Test client API
curl https://yourdomain.com/_matrix/client/versions

# Test well-known discovery
curl https://yourdomain.com/.well-known/matrix/server
curl https://yourdomain.com/.well-known/matrix/client
```

## 🎉 Congratulations! You now have a fully functional Matrix server running!

Connect using any Matrix client:

*   **Server**: `https://yourdomain.com`
*   **Username**: `@yourusername:yourdomain.com`
*   **Password**: Your chosen password

### Happy chatting! 💬🚀
