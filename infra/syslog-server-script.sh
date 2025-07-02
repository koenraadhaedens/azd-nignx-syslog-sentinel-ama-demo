#!/bin/bash
set -e

# Install rsyslog
sudo apt update
sudo apt install -y rsyslog

# Enable UDP reception
sudo sed -i '/^#module(load="imudp")/s/^#//' /etc/rsyslog.conf
sudo sed -i '/^#input(type="imudp"/s/^#//' /etc/rsyslog.conf

# Custom rule for NGINX logs
sudo tee /etc/rsyslog.d/20-nginx.conf > /dev/null <<EOF
if $programname == 'nginx_access' then /var/log/nginx_access.log
& stop
EOF

# Restart rsyslog
sudo systemctl restart rsyslog
