#!/bin/bash
set -e

# Set your syslog server private IP
SYSLOG_IP="${SYSLOG_IP:-10.0.0.5}"  # Fallback IP; ideally injected from outside

# Validate it's not a placeholder
if [[ "$SYSLOG_IP" == "10.0.0.5" ]]; then
  echo "WARNING: Using placeholder SYSLOG_IP. Set a real IP before deployment."
fi

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

# Configure syslog logging (corrected for variable expansion)
echo "access_log syslog:server=${SYSLOG_IP}:514,tag=nginx_access;" | sudo tee /etc/nginx/conf.d/syslog-logging.conf

# Reload NGINX
sudo nginx -t && sudo systemctl restart nginx
