#!/bin/bash
set -e

# Install rsyslog
sudo apt update
sudo apt install -y rsyslog

# Enable UDP reception in rsyslog.conf
sudo sed -i '/^#module(load="imudp")/s/^#//' /etc/rsyslog.conf
sudo sed -i '/^#input(type="imudp"/s/^#//' /etc/rsyslog.conf

# Custom rule to log all 'local7.*' messages (used by NGINX)
sudo tee /etc/rsyslog.d/20-nginx.conf > /dev/null <<EOF
local7.*    /var/log/nginx-syslog.log
EOF

# Create the log file with proper permissions
sudo touch /var/log/nginx-syslog.log
sudo chmod 644 /var/log/nginx-syslog.log
sudo chown syslog:adm /var/log/nginx-syslog.log

# Restart rsyslog to apply changes
sudo systemctl restart rsyslog
