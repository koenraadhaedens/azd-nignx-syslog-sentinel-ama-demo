#!/bin/bash

sudo apt update
sudo apt install -y rsyslog

# Enable UDP reception
sudo sed -i '/^#module(load="imudp")/s/^#//' /etc/rsyslog.conf
sudo sed -i '/^#input(type="imudp"/s/^#//' /etc/rsyslog.conf

# Optional: add custom rule
cat <<EOF | sudo tee /etc/rsyslog.d/20-nginx.conf
if \$programname == 'nginx_access' then /var/log/nginx_access.log
& stop
EOF

sudo systemctl restart rsyslog
