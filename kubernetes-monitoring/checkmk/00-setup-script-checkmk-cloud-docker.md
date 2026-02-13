# Umgesetzt mit digitalocean 

  * Für normale Verwendung ohne digitalocean einfach diese Bereich auskommentieren

```
#!/bin/bash
set -e

# Startzeit für Dauer-Berechnung
START_TIME=$(date +%s)

# ============================================================================
# WICHTIG - Vor Deployment manuell setzen!
# ============================================================================
DO_TOKEN="ENTER_YOUR_DO_TOKEN"
CMK_PASSWORD="ENTER_YOUR_CHECKMK_ADMIN_PASS_HERE"
# ============================================================================

# ============================================================================
# NUTZER und ssh konfigurieren 
# ============================================================================

groupadd sshadmin
USERS="11trainingdo"
echo $USERS
for USER in $USERS
do
  echo "Adding user $USER"
  useradd -s /bin/bash --create-home $USER
  usermod -aG sshadmin $USER
  echo "$USER:YOUR_PASSWORD_HERE" | chpasswd
done

# We can sudo with 11trainingdo
usermod -aG sudo 11trainingdo 

# 20.04 and 22.04 this will be in the subfolder
if [ -f /etc/ssh/sshd_config.d/50-cloud-init.conf ]
then
  sed -i "s/PasswordAuthentication no/PasswordAuthentication yes/g" /etc/ssh/sshd_config.d/50-cloud-init.conf
fi

# seen this in ubuntu 24.04 important here
if [ -f /etc/ssh/sshd_config.d/60-cloudimg-settings.conf ]
then
  sed -i "s/PasswordAuthentication no/PasswordAuthentication yes/g" /etc/ssh/sshd_config.d/60-cloudimg-settings.conf
fi

## both is needed 
sed -i "s/PasswordAuthentication no/PasswordAuthentication yes/g" /etc/ssh/sshd_config

usermod -aG sshadmin root

# TBD - Delete AllowUsers Entries with sed 
# otherwice we cannot login by group 
echo "AllowGroups sshadmin" >> /etc/ssh/sshd_config 

# Looks like it takes a while till ssh is running 
date > /var/log/training_reload_ssh
systemctl restart ssh 


# ============================================================================
# KONFIGURATION
# ============================================================================
BASE_DOMAIN="do.t3isp.de"
EMAIL="j.metzger@t3company.de"

# Dynamisch aus Hostname (wird in DO GUI gesetzt)
SUBDOMAIN=$(hostname -s)
DOMAIN="${SUBDOMAIN}.${BASE_DOMAIN}"

CMK_VERSION="2.4.0p20"
NGINX_VERSION="1.27-alpine"
CERTBOT_VERSION="v3.0.1"

INSTALL_DIR="/root/checkmk"
STATUS_FILE="/root/install-status.txt"

# Farben
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

update_status() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> ${STATUS_FILE}
}

cleanup_on_error() {
    log_error "Installation fehlgeschlagen. Räume auf..."
    update_status "[FAILED] Installation fehlgeschlagen"
    cd ${INSTALL_DIR} 2>/dev/null && docker-compose down 2>/dev/null || true
    exit 1
}

trap cleanup_on_error ERR

# Status-Datei initialisieren
echo "=== Checkmk Installation Status ===" > ${STATUS_FILE}
update_status "[START] Installation gestartet für ${DOMAIN}"

echo "╔═══════════════════════════════════════════════════════════╗"
echo "║     Checkmk Installation mit SSL - docker-compose only    ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""
echo "Hostname: $(hostname)"
echo "Subdomain: ${SUBDOMAIN}"
echo "Domain: ${DOMAIN}"
echo ""

# ============================================================================
# PRE-FLIGHT CHECKS
# ============================================================================

log_info "Starte Pre-Flight Checks..."
update_status "[RUNNING] Pre-Flight Checks"

# DO Token Check
if [ -z "${DO_TOKEN}" ] || [ "${DO_TOKEN}" = "<dein-digitalocean-api-token>" ]; then
    log_error "DO_TOKEN nicht gesetzt!"
    echo "Bitte DO_TOKEN im Script setzen!"
    update_status "[FAILED] DO_TOKEN nicht gesetzt"
    exit 1
fi

# CMK Password Check
if [ -z "${CMK_PASSWORD}" ] || [ "${CMK_PASSWORD}" = "<sicheres-passwort-fuer-checkmk>" ]; then
    log_error "CMK_PASSWORD nicht gesetzt!"
    echo "Bitte CMK_PASSWORD im Script setzen!"
    update_status "[FAILED] CMK_PASSWORD nicht gesetzt"
    exit 1
fi

# Root Check
if [ "$EUID" -ne 0 ]; then
    log_error "Script muss als root ausgeführt werden!"
    exit 1
fi

update_status "[OK] Pre-Flight Checks bestanden"

# ============================================================================
# PAKETE INSTALLIEREN
# ============================================================================

log_info "Installiere Pakete..."
update_status "[RUNNING] Pakete installieren"
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y -qq docker.io docker-compose curl wget dnsutils ufw > /dev/null 2>&1

systemctl enable docker > /dev/null 2>&1
systemctl start docker
update_status "[OK] Pakete installiert"

# ============================================================================
# DOCTL INSTALLIEREN
# ============================================================================

log_info "Installiere doctl..."
update_status "[RUNNING] doctl installieren"
cd /tmp
wget -q https://github.com/digitalocean/doctl/releases/download/v1.104.0/doctl-1.104.0-linux-amd64.tar.gz
tar xf doctl-1.104.0-linux-amd64.tar.gz > /dev/null 2>&1
mv doctl /usr/local/bin/
chmod +x /usr/local/bin/doctl
rm -f doctl-*.tar.gz

# on cloud-init we need to set home
export HOME=/root

doctl auth init -t ${DO_TOKEN} > /dev/null 2>&1

if ! doctl compute domain list > /dev/null 2>&1; then
    log_error "DigitalOcean API Token ungültig oder keine DNS-Berechtigung!"
    update_status "[FAILED] DO API Token ungültig oder keine DNS-Berechtigung"
    exit 1
fi
log_info "DigitalOcean DNS-Zugriff validiert ✓"
update_status "[OK] doctl installiert und DNS-Zugriff validiert"

# ============================================================================
# IP & DNS
# ============================================================================

log_info "Ermittle Droplet IP..."
update_status "[RUNNING] IP und DNS konfigurieren"
DROPLET_IP=$(curl -s http://169.254.169.254/metadata/v1/interfaces/public/0/ipv4/address)

if [ -z "$DROPLET_IP" ]; then
    log_error "Konnte Droplet IP nicht ermitteln!"
    update_status "[FAILED] Droplet IP nicht ermittelt"
    exit 1
fi
log_info "Droplet IP: ${DROPLET_IP}"

# Domain Check
if ! doctl compute domain list --format Domain --no-header | grep -q "^${BASE_DOMAIN}$"; then
    log_error "Domain ${BASE_DOMAIN} nicht in DigitalOcean!"
    update_status "[FAILED] Base Domain nicht gefunden"
    exit 1
fi

# A-Record erstellen/aktualisieren
log_info "Erstelle/Aktualisiere A-Record für ${SUBDOMAIN}..."
EXISTING_RECORD=$(doctl compute domain records list ${BASE_DOMAIN} --format Name,Type --no-header | grep "^${SUBDOMAIN}[[:space:]]" | grep "A" || true)

if [ -n "$EXISTING_RECORD" ]; then
    RECORD_ID=$(doctl compute domain records list ${BASE_DOMAIN} --format ID,Name,Type --no-header | grep "${SUBDOMAIN}[[:space:]]" | grep "A" | awk '{print $1}')
    doctl compute domain records update ${BASE_DOMAIN} --record-id ${RECORD_ID} --record-data ${DROPLET_IP} > /dev/null 2>&1
    log_info "A-Record aktualisiert"
else
    doctl compute domain records create ${BASE_DOMAIN} \
        --record-type A \
        --record-name ${SUBDOMAIN} \
        --record-data ${DROPLET_IP} \
        --record-ttl 300 > /dev/null 2>&1
    log_info "A-Record erstellt"
fi

# DNS Propagation Check - prüft Google DNS und DO Nameserver
log_info "Warte auf DNS Propagation (max. 5 Minuten)..."
DNS_RESOLVED=false
for i in {1..60}; do
    # Prüfe zuerst Google DNS
    RESOLVED_IP=$(dig +short ${DOMAIN} @8.8.8.8 | grep -E '^[0-9.]+$' | head -n1)

    if [ "$RESOLVED_IP" = "$DROPLET_IP" ]; then
        DNS_RESOLVED=true
        log_info "DNS aufgelöst (Google): ${DOMAIN} → ${DROPLET_IP} ✓"
        break
    fi

    # Nach 2 Minuten: akzeptiere auch DO Nameserver (Let's Encrypt funktioniert damit)
    if [ $i -ge 24 ]; then
        RESOLVED_IP_DO=$(dig +short ${DOMAIN} @ns1.digitalocean.com | grep -E '^[0-9.]+$' | head -n1)
        if [ "$RESOLVED_IP_DO" = "$DROPLET_IP" ]; then
            DNS_RESOLVED=true
            log_info "DNS aufgelöst (DO NS): ${DOMAIN} → ${DROPLET_IP} ✓"
            log_warn "Google DNS noch nicht propagiert - fahre trotzdem fort"
            break
        fi
    fi

    if [ $((i % 10)) -eq 0 ]; then
        log_warn "Warte... ($((i*5))/300 Sekunden)"
    fi
    sleep 5
done

if [ "$DNS_RESOLVED" = false ]; then
    log_error "DNS Propagation fehlgeschlagen!"
    update_status "[FAILED] DNS Propagation fehlgeschlagen"
    exit 1
fi
update_status "[OK] DNS konfiguriert: ${DOMAIN} → ${DROPLET_IP}"

# ============================================================================
# FIREWALL
# ============================================================================

log_info "Konfiguriere Firewall..."
update_status "[RUNNING] Firewall konfigurieren"
if command -v ufw > /dev/null 2>&1; then
    # WICHTIG: Regeln ZUERST hinzufügen, DANN aktivieren!
    ufw allow 22/tcp > /dev/null 2>&1
    ufw allow 80/tcp > /dev/null 2>&1
    ufw allow 443/tcp > /dev/null 2>&1
    ufw allow 8000/tcp > /dev/null 2>&1  # Checkmk Agent Registration
    ufw --force enable > /dev/null 2>&1
    log_info "Firewall konfiguriert ✓"
fi
update_status "[OK] Firewall konfiguriert (22, 80, 443, 8000)"

# ============================================================================
# VERZEICHNISSE ERSTELLEN
# ============================================================================

log_info "Erstelle Verzeichnisstruktur..."
update_status "[RUNNING] Verzeichnisse erstellen"
rm -rf ${INSTALL_DIR} 2>/dev/null || true
mkdir -p ${INSTALL_DIR}/{nginx/html,certbot/conf,certbot/www}
cd ${INSTALL_DIR}
update_status "[OK] Verzeichnisse erstellt"

# ============================================================================
# DOCKER-COMPOSE ERSTELLEN
# ============================================================================

log_info "Erstelle docker-compose.yml..."
update_status "[RUNNING] docker-compose.yml erstellen"
cat > docker-compose.yml << EOF
version: '3.8'

services:
  checkmk:
    image: checkmk/check-mk-cloud:${CMK_VERSION}
    container_name: monitoring
    restart: always
    environment:
      - CMK_PASSWORD=${CMK_PASSWORD}
      - TZ=Europe/Berlin
    volumes:
      - monitoring:/omd/sites
    tmpfs:
      - /opt/omd/sites/cmk/tmp:uid=1000,gid=1000
    ports:
      - "127.0.0.1:5000:5000"
      - "8000:8000"
    networks:
      - checkmk

  nginx:
    image: nginx:${NGINX_VERSION}
    container_name: nginx
    restart: always
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx/nginx.conf:/etc/nginx/conf.d/default.conf:ro
      - ./nginx/html:/etc/nginx/html:ro
      - ./certbot/conf:/etc/letsencrypt:ro
      - ./certbot/www:/var/www/certbot:ro
    networks:
      - checkmk
    depends_on:
      - checkmk

  certbot:
    image: certbot/certbot:${CERTBOT_VERSION}
    container_name: certbot
    volumes:
      - ./certbot/conf:/etc/letsencrypt
      - ./certbot/www:/var/www/certbot
    entrypoint: "/bin/sh -c 'trap exit TERM; while :; do certbot renew --quiet; sleep 12h & wait \$\${!}; done;'"

networks:
  checkmk:
    driver: bridge

volumes:
  monitoring:
EOF
update_status "[OK] docker-compose.yml erstellt"

# ============================================================================
# CUSTOM 404 ERROR PAGE
# ============================================================================

log_info "Erstelle Custom 404 Error Page..."
cat > nginx/html/404.html << 'HTML_EOF'
<!DOCTYPE html>
<html lang="de">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>404 - Seite nicht gefunden</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background: linear-gradient(135deg, #1a5f2a 0%, #2d8a3e 100%);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            color: #333;
        }
        .container {
            background: white;
            border-radius: 12px;
            box-shadow: 0 20px 60px rgba(0, 0, 0, 0.3);
            padding: 3rem 2rem;
            max-width: 500px;
            text-align: center;
        }
        .error-code {
            font-size: 8rem;
            font-weight: bold;
            background: linear-gradient(135deg, #1a5f2a 0%, #2d8a3e 100%);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            background-clip: text;
            line-height: 1;
            margin-bottom: 1rem;
        }
        h1 { font-size: 1.5rem; color: #333; margin-bottom: 1rem; }
        p { color: #666; line-height: 1.6; margin-bottom: 2rem; }
        .btn {
            display: inline-block;
            background: linear-gradient(135deg, #1a5f2a 0%, #2d8a3e 100%);
            color: white;
            padding: 0.75rem 2rem;
            border-radius: 6px;
            text-decoration: none;
            font-weight: 500;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="error-code">404</div>
        <h1>Seite nicht gefunden</h1>
        <p>Die angeforderte Seite existiert nicht.</p>
        <a href="/" class="btn">Zur Startseite</a>
    </div>
</body>
</html>
HTML_EOF

# ============================================================================
# PHASE 1: HTTP-ONLY NGINX CONFIG
# ============================================================================

log_info "Erstelle HTTP-only Nginx Config (Phase 1)..."
update_status "[RUNNING] Nginx HTTP Config erstellen"
cat > nginx/nginx.conf << NGINX_EOF
server {
    listen 80;
    server_name ${DOMAIN};

    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }

    error_page 404 /404.html;
    location = /404.html {
        root /etc/nginx/html;
        internal;
    }

    location / {
        proxy_pass http://checkmk:5000/;
        proxy_buffering off;
        proxy_http_version 1.1;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection \$http_connection;
        proxy_set_header Host \$host;
        proxy_intercept_errors on;
    }
}
NGINX_EOF
update_status "[OK] Nginx HTTP Config erstellt"

# ============================================================================
# CONTAINER STARTEN (HTTP ONLY)
# ============================================================================

log_info "Starte Container (HTTP only)..."
update_status "[RUNNING] Container starten"
docker-compose up -d checkmk nginx

log_info "Warte auf Container-Start (60 Sekunden für Checkmk)..."
sleep 60

# Container Health Check
if ! docker ps | grep -q monitoring; then
    log_error "Checkmk Container läuft nicht!"
    docker logs monitoring
    update_status "[FAILED] Checkmk Container läuft nicht"
    exit 1
fi

if ! docker ps | grep -q nginx; then
    log_error "nginx läuft nicht!"
    docker logs nginx
    update_status "[FAILED] Nginx Container läuft nicht"
    exit 1
fi

log_info "Alle Container laufen ✓"
update_status "[OK] Container gestartet"

# HTTP Test
log_info "Teste HTTP Verbindung..."
sleep 5
if curl -s -o /dev/null -w "%{http_code}" http://localhost/ | grep -q "200\|302"; then
    log_info "HTTP funktioniert ✓"
else
    log_warn "HTTP Test fehlgeschlagen - fahre trotzdem fort"
fi

# ============================================================================
# SSL ZERTIFIKAT HOLEN
# ============================================================================

log_info "Fordere SSL Zertifikat an..."
update_status "[RUNNING] SSL Zertifikat anfordern"
if docker run --rm \
    -v ${INSTALL_DIR}/certbot/conf:/etc/letsencrypt \
    -v ${INSTALL_DIR}/certbot/www:/var/www/certbot \
    certbot/certbot:${CERTBOT_VERSION} certonly \
    --webroot \
    --webroot-path=/var/www/certbot \
    --email ${EMAIL} \
    --agree-tos \
    --no-eff-email \
    -d ${DOMAIN}; then
    log_info "SSL Zertifikat erfolgreich erstellt ✓"
else
    log_error "SSL Zertifikat Erstellung fehlgeschlagen!"
    update_status "[FAILED] SSL Zertifikat fehlgeschlagen"
    exit 1
fi

# Zertifikat Check
if [ ! -f "certbot/conf/live/${DOMAIN}/fullchain.pem" ]; then
    log_error "Zertifikat nicht gefunden!"
    ls -la certbot/conf/live/
    update_status "[FAILED] Zertifikat nicht gefunden"
    exit 1
fi

log_info "Zertifikat validiert ✓"
update_status "[OK] SSL Zertifikat erstellt"

# ============================================================================
# PHASE 2: HTTPS NGINX CONFIG
# ============================================================================

log_info "Update zu HTTPS Nginx Config (Phase 2)..."
update_status "[RUNNING] Nginx HTTPS Config erstellen"
cat > nginx/nginx.conf << NGINX_EOF
server {
    listen 80;
    server_name ${DOMAIN};

    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }

    location / {
        return 301 https://\$host\$request_uri;
    }
}

server {
    listen 443 ssl http2;
    server_name ${DOMAIN};

    ssl_certificate /etc/letsencrypt/live/${DOMAIN}/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/${DOMAIN}/privkey.pem;

    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-CHACHA20-POLY1305;
    ssl_prefer_server_ciphers on;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;

    error_page 404 /404.html;
    location = /404.html {
        root /etc/nginx/html;
        internal;
    }

    location / {
        proxy_pass http://checkmk:5000/;
        proxy_buffering off;
        proxy_http_version 1.1;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection \$http_connection;
        proxy_set_header Host \$host;
        proxy_intercept_errors on;
    }
}
NGINX_EOF

# Nginx restart
log_info "Restart Nginx mit SSL Config..."
sleep 3
docker-compose restart nginx
update_status "[OK] Nginx HTTPS Config aktiviert"

# Certbot Renewal Service starten
log_info "Starte Certbot Renewal Service..."
docker-compose up -d certbot

# ============================================================================
# FINAL CHECKS
# ============================================================================

log_info "Führe finale Tests durch..."
update_status "[RUNNING] Finale Tests"
sleep 5

HTTP_CODE=$(curl -k -s -o /dev/null -w "%{http_code}" https://${DOMAIN}/ || echo "000")
if [[ "$HTTP_CODE" =~ ^(200|302)$ ]]; then
    log_info "HTTPS funktioniert ✓"
    update_status "[OK] HTTPS funktioniert"
else
    log_warn "HTTPS Status: ${HTTP_CODE} - bitte manuell prüfen"
    update_status "[WARN] HTTPS Status: ${HTTP_CODE}"
fi

# ============================================================================
# CREDENTIALS AUSGABE
# ============================================================================

cat > credentials.txt << EOF
═══════════════════════════════════════════════════
         CHECKMK INSTALLATION - CREDENTIALS
═══════════════════════════════════════════════════

🌐 URL:        https://${DOMAIN}/cmk/
🖥️  Droplet IP: ${DROPLET_IP}

👤 ADMIN LOGIN:
   Username: cmkadmin
   Password: ${CMK_PASSWORD}

📋 WORKFLOW:
   1. Browser öffnen: https://${DOMAIN}/cmk/
   2. Login mit cmkadmin / ${CMK_PASSWORD}
   3. Hosts hinzufügen und monitoren

🐳 DOCKER BEFEHLE:
   Status:   cd ${INSTALL_DIR} && docker-compose ps
   Logs:     docker-compose logs -f monitoring
   Restart:  docker-compose restart
   Stop:     docker-compose down
   Start:    docker-compose up -d

🔄 SSL ERNEUERUNG:
   Automatisch alle 12h via Certbot Container
   Manuell: docker-compose run --rm certbot renew

📁 INSTALLATION:
   Verzeichnis: ${INSTALL_DIR}
   Nginx:       ${INSTALL_DIR}/nginx/nginx.conf

🔌 AGENT REGISTRATION:
   Port 8000 ist offen für Agent-Registrierung

═══════════════════════════════════════════════════
EOF

chmod 600 credentials.txt

echo ""
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║         ✅  INSTALLATION ERFOLGREICH ABGESCHLOSSEN         ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""
cat credentials.txt
echo ""
log_info "Credentials gespeichert in: ${INSTALL_DIR}/credentials.txt"

# Dauer berechnen
END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))
MINUTES=$((DURATION / 60))
SECONDS=$((DURATION % 60))

log_info "Installation abgeschlossen in ${MINUTES} Minuten und ${SECONDS} Sekunden!"

update_status "[DONE] Installation erfolgreich abgeschlossen"
update_status "Dauer: ${MINUTES} Minuten ${SECONDS} Sekunden"
update_status "URL: https://${DOMAIN}/cmk/"
update_status "User: cmkadmin"


```
