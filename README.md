# Matrix Synapse Server with Docker

A complete, production-ready Matrix Synapse server setup using Docker, 
PostgreSQL, and Nginx reverse proxy with automatic SSL certificates.

## Prerequisites

*   **Linux Server** (Ubuntu 20.04+ recommended)
*   **Domain Name** pointing to your server
*   **Docker** (v20.10+)
*   **Docker Compose** (v1.29+)
*   **Ports Open**: 80, 443, 8448
*   **Root/Sudo Access**

## Quick Start

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
DOMAIN="yourdomain.com"

# Email for Let's Encrypt certificates
EMAIL="your-email@example.com"

# Database password (use a strong password)
POSTGRES_PASSWORD="your_secure_database_password"

# Registration secret (use a random string)
SYNAPSE_REGISTRATION_SHARED_SECRET="your_random_secret"
```

####  - Edit the nginx configuration file

```
nano .env
```

Set your domain value:

```
DOMAIN="yourdomain.com"
```

### 3\. Generate SSL Certificates

This will get Let's Encrypt certificates and copy them to ssl/ directory

```
./scripts/setup-ssl.sh
```

### 4\. Deploy Matrix Server

This will start all services (PostgreSQL, Synapse, Nginx)

```
./scripts/deploy-matrix.sh
```

### 5\. Create Your First Admin User

Interactive user creation

```
./scripts/create-user.sh
```

## Deployment

### Start Services

Once installed, all services can be started in background as follows

```
docker-compose up -d
```

To check their status

```
docker-compose ps
```

To view their logs

```
docker-compose logs -f matrix-synapse
docker-compose logs -f matrix-nginx
docker-compose logs -f matrix-postgres
```

### Stop Services

To stop all services

```
docker-compose down
```

**⚠️ Warning:** The following command will delete all data!

To stop and remove volumes

```
docker-compose down -v
```

### Update Services

Pull latest images

```
docker-compose pull
```

Restart with new images

```
docker-compose up -d
```

## User Management

### Create Single User (Interactive)

```
./scripts/create-user.sh
```

This script will prompt you for:

*   Username
*   Password
*   Admin privileges (y/N, default N)

### Batch User Creation

**1\. Create users file**:

Edit the users.txt file

```
nano users.txt
```

**2\. Add users** (use the following syntax: `username:password:admin_flag`):

```
user1:password_123:true
user2:password_456:false
user3:password_789:false
```

**3\. Run batch creation**:

```
./scripts/create-user-batch.sh
```

### Manual User Creation

Is it possible also to manually create a user via Synapse command, as follows:

```
# Admin user
docker-compose exec synapse register_new_matrix_user \
    -c /data/homeserver.yaml \
    -u username \
    -p password \
    --admin \
    http://localhost:8008

# Regular user
docker-compose exec synapse register_new_matrix_user \
    -c /data/homeserver.yaml \
    -u username \
    -p password \
    http://localhost:8008
```

## Maintenance

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

## Troubleshooting

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

NOTE: If you're using a free DNS resolver as https://www.noip.com/ please make
sure first your domain points to some reachable host on your local network.

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

## Project Structure

This is how the entire project structure should look like right after the execution of the deploy-matrix.sh

```
synapse-server/
├── .env   
├── config.env                 # Main configuration file
├── docker-compose.yaml        # Generated from template
├── nginx.conf                 # Generated from template  
├── homeserver.yaml            # Generated from template
├── scripts/
│   ├── setup-ssl.sh          # SSL certificate setup
│   ├── deploy-matrix.sh      # Main deployment script
│   ├── create-user.sh        # Interactive user creation
│   └── create-user-batch.sh  # Batch user creation
├── templates/
│   ├── docker-compose.yaml.template
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

## SSL Certificate Management

### Automatic Renewal

The setup script configures automatic certificate renewal via cron. Check with:

```
sudo crontab -l | grep certbot
```

### Manual Certificate Management

Check certificate expiration

```
sudo certbot certificates
```

Renew specific certificate

```
sudo certbot renew --cert-name yourdomain.com
```

Copy renewed certificates to ssl/ directory

```
sudo cp /etc/letsencrypt/live/yourdomain.com/fullchain.pem ssl/
sudo cp /etc/letsencrypt/live/yourdomain.com/privkey.pem ssl/
sudo chown $USER:$USER ssl/*
```

Restart nginx to load new certificates

```
docker-compose restart nginx
```

### Testing Your Setup

#### Federation Test

Test if your server can communicate with other Matrix servers:

Test federation endpoint

```
curl https://yourdomain.com:8448/_matrix/federation/v1/version
```

Test with federation tester (external tool)

```
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

## Connect using any Matrix client:

*   **Server**: `https://yourdomain.com`
*   **Username**: `@yourusername:yourdomain.com`
*   **Password**: Your chosen password
