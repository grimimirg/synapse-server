# Create subdirectories
mkdir scripts
mkdir templates

# Create the script files
touch scripts/setup-ssl.sh
touch scripts/deploy-matrix.sh

# Create the template files
touch templates/docker-compose.yml.template
touch templates/nginx.conf.template
touch templates/homeserver.yaml.template

# Create configuration files
touch config.env
touch README.md

# Make scripts executable
chmod +x scripts/setup-ssl.sh
chmod +x scripts/deploy-matrix.sh
