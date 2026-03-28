# SSL-certificate-processing-in-Debian
Hands-on lab: generating, installing, and verifying SSL certificates using OpenSSL and Apache on Debian.

> **Environment:** Ubuntu/Debian Linux — local VM, cloud server, or WSL2

---

## 📋 Prerequisites

```bash
openssl version          # verify OpenSSL is installed
apache2 -v               # verify Apache is installed
```

Install Apache if missing:

```bash
sudo apt update && sudo apt install apache2 -y
```

---

## Task 1 — Generate a Self-Signed Certificate

### 1.1 Create a working directory

```bash
mkdir ~/ssl-certs && cd ~/ssl-certs
```

### 1.2 Generate a private key

```bash
openssl genrsa -out server.key 2048
```

| Flag | Meaning |
|------|---------|
| `genrsa` | Generate an RSA private key |
| `-out server.key` | Save key to `server.key` |
| `2048` | Key size in bits (standard strength) |

### 1.3 Create a Certificate Signing Request (CSR)

```bash
openssl req -new -key server.key -out server.csr \
  -subj "/C=RU/ST=SaintPetersburg/L=SaintPetersburg/O=MyOrg/CN=example.com"
```

| Flag | Meaning |
|------|---------|
| `req -new` | Create a new CSR |
| `-key server.key` | Use the private key from step 1.2 |
| `-out server.csr` | Save the CSR to `server.csr` |
| `-subj` | Certificate fields — replace values as needed |

`-subj` fields: `C` = Country · `ST` = State · `L` = City · `O` = Organization · `CN` = Domain name

### 1.4 Generate the self-signed certificate

```bash
openssl x509 -req -days 365 -in server.csr -signkey server.key -out server.crt
```

| Flag | Meaning |
|------|---------|
| `x509 -req` | Process a CSR into a certificate |
| `-days 365` | Certificate valid for 1 year |
| `-in server.csr` | Input CSR from step 1.3 |
| `-signkey server.key` | Sign with the private key |
| `-out server.crt` | Output certificate file |

### 1.5 Verify the certificate

```bash
openssl x509 -in server.crt -text -noout
```

Checking that `Subject:` matches the `-subj` values and `Validity` shows a 365-day window.

**Files created:**

```
~/ssl-certs/
├── server.key   ← private key
├── server.csr   ← signing request (intermediate)
└── server.crt   ← certificate (used by the server)
```

---

## Task 2 — Install Certificate on Apache

### 2.1 Copy files to system directories

```bash
sudo cp server.key /etc/ssl/private/
sudo cp server.crt /etc/ssl/certs/
```

| Path | Purpose |
|------|---------|
| `/etc/ssl/private/` | Restricted directory for private keys |
| `/etc/ssl/certs/` | Standard location for public certificates |

### 2.2 Create a virtual host config

```bash
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
```

| Directive | Meaning |
|-----------|---------|
| `<VirtualHost *:443>` | Listen on HTTPS port 443 |
| `SSLEngine on` | Enable SSL for this virtual host |
| `SSLCertificateFile` | Path to the `.crt` certificate |
| `SSLCertificateKeyFile` | Path to the `.key` private key |

### 2.3 Enable SSL module and activate the site

```bash
sudo a2enmod ssl                  # enable Apache SSL module
sudo a2ensite ssl-test.conf       # activate the virtual host
sudo systemctl reload apache2     # apply changes
```

### 2.4 Open port 443 in the firewall

```bash
sudo ufw allow 443/tcp
sudo ufw reload
```

---

## Task 3 — Verify the Certificate

### 3.1 Test HTTPS with curl

```bash
curl -k https://localhost
```

`-k` skips certificate validation — required for self-signed certificates.

### 3.2 Inspect certificate details

```bash
openssl s_client -connect localhost:443 -showcerts </dev/null
```

| Flag | Meaning |
|------|---------|
| `s_client` | Act as an SSL/TLS client |
| `-connect localhost:443` | Connect to the server on port 443 |
| `-showcerts` | Print the full certificate chain |
| `</dev/null` | Send EOF immediately so the connection closes |

Look now for `Subject:` and `Certificate chain` in the output.

---

## File Reference

| File | Location | Description |
|------|----------|-------------|
| `server.key` | `/etc/ssl/private/server.key` | Private key — never expose this |
| `server.crt` | `/etc/ssl/certs/server.crt` | Public certificate served to clients |
| `server.csr` | `~/ssl-certs/server.csr` | Intermediate CSR (not needed after cert is generated) |
| `ssl-test.conf` | `/etc/apache2/sites-available/` | Apache virtual host config |

---

> ⚠️ Self-signed certificates are **not trusted by browsers** — suitable for local and development environments only. For a publicly trusted certificate, use Let's Encrypt / Certbot.




