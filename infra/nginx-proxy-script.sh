#!/bin/bash
set -e

# Install dependencies
sudo apt update
sudo apt install -y nginx openssl python3

# Set up a basic HTML website on port 8080
sudo mkdir -p /var/www/demo
echo "<h1>Hello from the demo site!</h1>" | sudo tee /var/www/demo/index.html

# Create systemd service for serving demo site
sudo tee /etc/systemd/system/demo-site.service > /dev/null <<EOF
[Unit]
Description=Simple HTTP demo site on port 8080
After=network.target

[Service]
ExecStart=/usr/bin/python3 -m http.server 8080 --directory /var/www/demo
Restart=always
User=www-data

[Install]
WantedBy=multi-user.target
EOF

# Start and enable the demo site
sudo systemctl daemon-reload
sudo systemctl enable demo-site
sudo systemctl start demo-site

# Create self-signed cert
sudo mkdir -p /etc/nginx/ssl
sudo openssl req -x509 -nodes -days 365 \
  -subj "/C=US/ST=NA/L=NA/O=Demo/CN=localhost" \
  -newkey rsa:2048 \
  -keyout /etc/nginx/ssl/selfsigned.key \
  -out /etc/nginx/ssl/selfsigned.crt

# Configure NGINX reverse proxy with HTTPS and self-signed cert
sudo tee /etc/nginx/conf.d/reverse-proxy.conf > /dev/null <<EOF
server {
    listen 443 ssl;
    server_name _;

    ssl_certificate /etc/nginx/ssl/selfsigned.crt;
    ssl_certificate_key /etc/nginx/ssl/selfsigned.key;

    location / {
        proxy_pass http://localhost:8080;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }
}

server {
    listen 80;
    return 301 https://\$host\$request_uri;
}
EOF

# Restart NGINX
sudo nginx -t && sudo systemctl restart nginx
