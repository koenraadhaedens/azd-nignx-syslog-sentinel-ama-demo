#!/bin/bash
set -e

# Install NGINX
sudo apt update
sudo apt install -y nginx

# Configure NGINX as a forward proxy
sudo tee /etc/nginx/conf.d/forward-proxy.conf > /dev/null <<EOF
server {
    listen 8888;

    resolver 8.8.8.8;

    location / {
        proxy_pass \$scheme://\$http_host\$request_uri;
        proxy_set_header Host \$http_host;
    }
}
EOF

# Set up access log to remote syslog server (replace placeholder IP)
SYSLOG_IP="10.0.0.5" # You should replace this with the actual private IP of the syslog server

sudo tee /etc/nginx/conf.d/syslog-logging.conf > /dev/null <<EOF
access_log syslog:server=\${SYSLOG_IP}:514,tag=nginx_access;
EOF

# Reload NGINX
sudo nginx -t && sudo systemctl restart nginx
