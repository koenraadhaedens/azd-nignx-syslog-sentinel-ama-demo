#!/bin/bash
set -e

# Set your syslog server private IP
SYSLOG_IP="10.0.0.200"

# Install required packages
apt-get update
apt-get install -y nginx openssl python3

# ------------------------
# Set up demo HTTP website
# ------------------------
mkdir -p /var/www/demo
echo "<h1>Hello from the demo site!</h1>" > /var/www/demo/index.html
chown -R www-data:www-data /var/www/demo

# Create systemd service (correct syntax)
tee /etc/systemd/system/demo-site.service > /dev/null <<'EOF'
[Unit]
Description=Simple HTTP demo site on port 8080
After=network.target

[Service]
WorkingDirectory=/var/www/demo
ExecStart=/usr/bin/python3 -m http.server 8080
Restart=always
User=www-data

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reexec
systemctl daemon-reload
systemctl enable demo-site
systemctl restart demo-site

# ------------------------
# Set up self-signed SSL
# ------------------------
mkdir -p /etc/nginx/ssl
openssl req -x509 -nodes -days 365 \
  -subj "/C=US/ST=None/L=None/O=Demo/CN=localhost" \
  -newkey rsa:2048 \
  -keyout /etc/nginx/ssl/selfsigned.key \
  -out /etc/nginx/ssl/selfsigned.crt

# ------------------------
# Configure NGINX
# ------------------------

# Reverse proxy HTTPS -> local HTTP
tee /etc/nginx/conf.d/reverse-proxy.conf > /dev/null <<EOF
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

# Log to syslog server
tee /etc/nginx/conf.d/syslog-logging.conf > /dev/null <<EOF
access_log syslog:server=${SYSLOG_IP}:514,tag=nginx_access;
EOF

# ------------------------
# Finalize and restart
# ------------------------
nginx -t && systemctl restart nginx
