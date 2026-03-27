#!/bin/bash

# ─────────────────────────────────────────────
# SSL Certificate Lab — Tasks 1–3
# ─────────────────────────────────────────────

# ─────────────────────────────────────────────
# Task 1 — Generate a Self-Signed Certificate
# ─────────────────────────────────────────────

# Create working directory
mkdir ~/ssl-certs && cd ~/ssl-certs

# Generate private key (2048-bit RSA)
openssl genrsa -out server.key 2048

# Create CSR — edit -subj fields as needed
openssl req -new -key server.key -out server.csr \
  -subj "/C=RU/ST=SaintPetersburg/L=SaintPetersburg/O=MyOrg/CN=example.com"

# Generate self-signed certificate (valid 365 days)
openssl x509 -req -days 365 -in server.csr -signkey server.key -out server.crt

# Verify the certificate
openssl x509 -in server.crt -text -noout

# ─────────────────────────────────────────────
# Task 2 — Install Certificate on Apache
# ─────────────────────────────────────────────

# Install Apache if not already installed
sudo apt update && sudo apt install apache2 -y

# Copy certificate files to system directories
sudo cp server.key /etc/ssl/private/
sudo cp server.crt /etc/ssl/certs/

# Create virtual host config for HTTPS
sudo tee /etc/apache2/sites-available/ssl-test.conf > /dev/null <<EOF
<VirtualHost *:443>
    ServerName example.com
    DocumentRoot /var/www/html

    SSLEngine on
    SSLCertificateFile    /etc/ssl/certs/server.crt
    SSLCertificateKeyFile /etc/ssl/private/server.key

    <Directory "/var/www/html">
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
</VirtualHost>
EOF

# Enable SSL module and activate the site
sudo a2enmod ssl
sudo a2ensite ssl-test.conf
sudo systemctl reload apache2

# Open port 443 in the firewall
sudo ufw allow 443/tcp
sudo ufw reload

# ─────────────────────────────────────────────
# Task 3 — Verify the Certificate
# ─────────────────────────────────────────────

# Test HTTPS connection (-k ignores self-signed cert warning)
curl -k https://localhost

# Inspect certificate details and chain
openssl s_client -connect localhost:443 -showcerts </dev/null
