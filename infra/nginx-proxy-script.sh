#!/bin/bash

# Install NGINX
sudo apt update
sudo apt install -y nginx

# Configure NGINX as a basic forward proxy
cat <<EOF | sudo tee /etc/nginx/conf.d/forward-proxy.conf
server {
    listen 8888;

    resolver 8.8.8.8;

    location / {
        proxy_pass \$scheme://\$http_host\$request_uri;
        proxy_set_header Host \$http_host;
    }
}
EOF

sudo nginx -s reload

# Enable syslog logging
echo 'access_log syslog:server=SYSLOG_SERVER_IP:514,tag=nginx_access;' | sudo tee -a /etc/nginx/nginx.conf
sudo nginx -s reload
