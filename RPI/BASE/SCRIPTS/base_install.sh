#!/usr/bin/env bash
# =====================================================================
# Projet_SIN - Setup Raspberry Pi (RPi OS / Debian)
# Installe automatiquement : Nginx + Node.js + MariaDB + sécurité de base
# Optionnel : MQTT (Mosquitto), UFW, Fail2ban
#
# Usage :
#   1) chmod +x setup_projet_sin_rpi.sh
#   2) sudo ./setup_projet_sin_rpi.sh
#
# Notes :
# - Ce script vise le "simple et efficace", pas l’usine à gaz.
# - MariaDB est configuré avec une base + un user dédiés.
# =====================================================================

set -euo pipefail

# ----------------------------
# CONFIG (modifie si tu veux)
# ----------------------------

# Nom du projet (sert juste pour les dossiers)
PROJECT_NAME="projet_sin"

# MariaDB (simple)
DB_NAME="lycee_automation"
DB_USER="sin_app"
# Si tu laisses vide -> le script génère un mot de passe
DB_PASS=""
# Mot de passe root MariaDB (si vide -> le script en génère un)
DB_ROOT_PASS=""

# Node.js
# Sur Raspberry Pi OS, "nodejs" via apt peut être un peu vieux.
# On reste simple : apt. Tu pourras upgrader plus tard si besoin.
INSTALL_NODE="yes"

# Services optionnels
INSTALL_MQTT="yes"     # Mosquitto (recommandé si tu fais plein de salles/capteurs)
INSTALL_UFW="yes"      # Firewall simple
INSTALL_FAIL2BAN="yes" # Anti brute-force

# Nginx
NGINX_SITE_NAME="${PROJECT_NAME}"

# Port de ton API Node.js (Nginx reverse proxy vers ce port)
API_PORT="3000"

# ----------------------------
# Helpers
# ----------------------------

log() { echo -e "\n[+] $*"; }

gen_pass() {
  # Génère un mot de passe solide et copiable
  tr -dc 'A-Za-z0-9!@#%^_-+=' </dev/urandom | head -c 28
}

require_root() {
  if [[ "${EUID}" -ne 0 ]]; then
    echo "[!] Lance ce script en root : sudo $0"
    exit 1
  fi
}

detect_ip() {
  hostname -I 2>/dev/null | awk '{print $1}' || true
}

# ----------------------------
# Start
# ----------------------------

require_root

log "Mise à jour du système"
apt update -y
apt upgrade -y

log "Installation outils de base"
apt install -y ca-certificates curl gnupg git

# ----------------------------
# NGINX
# ----------------------------
log "Installation Nginx"
apt install -y nginx
systemctl enable --now nginx

# ----------------------------
# Node.js (simple via apt)
# ----------------------------
if [[ "${INSTALL_NODE}" == "yes" ]]; then
  log "Installation Node.js + npm (version repo Debian/RPi OS, simple)"
  apt install -y nodejs npm
fi

# ----------------------------
# MariaDB
# ----------------------------
log "Installation MariaDB"
apt install -y mariadb-server
systemctl enable --now mariadb

# Génération des mots de passe si vides
if [[ -z "${DB_ROOT_PASS}" ]]; then DB_ROOT_PASS="$(gen_pass)"; fi
if [[ -z "${DB_PASS}" ]]; then DB_PASS="$(gen_pass)"; fi

log "Configuration MariaDB (simple + sécurisé)"
# On applique un "secure install" version script :
# - mot de passe root
# - suppression user anonyme
# - désactivation remote root
# - suppression base test
# - création DB + user appli
mariadb -u root <<SQL
-- Set root password (MariaDB sur Debian/RPi OS utilise souvent unix_socket : on force un password + auth classique)
ALTER USER 'root'@'localhost' IDENTIFIED BY '${DB_ROOT_PASS}';

DELETE FROM mysql.user WHERE User='';
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';

-- Empêche root distant (par défaut root@localhost seulement, mais on verrouille)
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost','127.0.0.1','::1');

CREATE DATABASE IF NOT EXISTS \`${DB_NAME}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;

CREATE USER IF NOT EXISTS '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASS}';
GRANT ALL PRIVILEGES ON \`${DB_NAME}\`.* TO '${DB_USER}'@'localhost';

FLUSH PRIVILEGES;
SQL

# ----------------------------
# Schema minimal (pour éviter de "se faire chier" avec la BDD)
# ----------------------------
log "Création d’un schéma minimal (users / rooms / permissions / logs)"
mariadb -u "${DB_USER}" -p"${DB_PASS}" "${DB_NAME}" <<'SQL'
CREATE TABLE IF NOT EXISTS users (
  id INT AUTO_INCREMENT PRIMARY KEY,
  username VARCHAR(64) NOT NULL UNIQUE,
  password_hash VARCHAR(255) NOT NULL,
  role VARCHAR(32) NOT NULL DEFAULT 'teacher',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS rooms (
  id INT AUTO_INCREMENT PRIMARY KEY,
  code VARCHAR(32) NOT NULL UNIQUE,      -- ex: "SIN_101"
  name VARCHAR(128) NOT NULL,            -- ex: "Salle SIN"
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS permissions (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  room_id INT NOT NULL,
  can_lights BOOLEAN NOT NULL DEFAULT 0,
  can_pc BOOLEAN NOT NULL DEFAULT 0,
  can_heating BOOLEAN NOT NULL DEFAULT 0,
  UNIQUE KEY uniq_user_room (user_id, room_id),
  CONSTRAINT fk_perm_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  CONSTRAINT fk_perm_room FOREIGN KEY (room_id) REFERENCES rooms(id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS audit_logs (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NULL,
  room_id INT NULL,
  action VARCHAR(64) NOT NULL,           -- ex: "lights_on", "pc_shutdown"
  detail TEXT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX (created_at),
  CONSTRAINT fk_log_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL,
  CONSTRAINT fk_log_room FOREIGN KEY (room_id) REFERENCES rooms(id) ON DELETE SET NULL
) ENGINE=InnoDB;
SQL

# ----------------------------
# MQTT (Mosquitto)
# ----------------------------
if [[ "${INSTALL_MQTT}" == "yes" ]]; then
  log "Installation Mosquitto (MQTT)"
  apt install -y mosquitto mosquitto-clients
  systemctl enable --now mosquitto
fi

# ----------------------------
# Sécurité: UFW + Fail2ban
# ----------------------------
if [[ "${INSTALL_UFW}" == "yes" ]]; then
  log "Installation + config UFW (HTTP/HTTPS/SSH)"
  apt install -y ufw
  ufw allow 22/tcp
  ufw allow 80/tcp
  ufw allow 443/tcp
  ufw --force enable
fi

if [[ "${INSTALL_FAIL2BAN}" == "yes" ]]; then
  log "Installation Fail2ban"
  apt install -y fail2ban
  systemctl enable --now fail2ban
fi

# ----------------------------
# Dossier projet + mini API Node (squelette)
# ----------------------------
log "Création d’un squelette projet dans /opt/${PROJECT_NAME}"
mkdir -p "/opt/${PROJECT_NAME}"
chown -R "${SUDO_USER:-root}:${SUDO_USER:-root}" "/opt/${PROJECT_NAME}" || true

# On crée un mini serveur Node (Express) qui écoute sur API_PORT
# (Tu pourras le remplacer par ton vrai code ensuite.)
if [[ "${INSTALL_NODE}" == "yes" ]]; then
  log "Création d’une mini API Node.js (Express) + connexion MariaDB"
  apt install -y nodejs npm >/dev/null 2>&1 || true

  cat > "/opt/${PROJECT_NAME}/package.json" <<EOF
{
  "name": "${PROJECT_NAME}",
  "version": "1.0.0",
  "main": "server.js",
  "type": "commonjs",
  "scripts": {
    "start": "node server.js"
  },
  "dependencies": {
    "express": "^4.19.2",
    "mysql2": "^3.11.0"
  }
}
EOF

  cat > "/opt/${PROJECT_NAME}/server.js" <<EOF
const express = require("express");
const mysql = require("mysql2/promise");

const app = express();
app.use(express.json());

const pool = mysql.createPool({
  host: "localhost",
  user: "${DB_USER}",
  password: "${DB_PASS}",
  database: "${DB_NAME}",
  waitForConnections: true,
  connectionLimit: 10
});

app.get("/health", async (req, res) => {
  try {
    const [rows] = await pool.query("SELECT 1 AS ok");
    res.json({ status: "ok", db: rows[0].ok });
  } catch (e) {
    res.status(500).json({ status: "error", error: e.message });
  }
});

// Exemple : liste des salles
app.get("/rooms", async (req, res) => {
  const [rows] = await pool.query("SELECT id, code, name, created_at FROM rooms ORDER BY id DESC");
  res.json(rows);
});

app.listen(${API_PORT}, () => {
  console.log("API running on port ${API_PORT}");
});
EOF

  # Installer dépendances
  (cd "/opt/${PROJECT_NAME}" && npm install --silent)

  # Service systemd pour lancer l’API au boot
  cat > "/etc/systemd/system/${PROJECT_NAME}.service" <<EOF
[Unit]
Description=${PROJECT_NAME} Node API
After=network.target mariadb.service

[Service]
Type=simple
WorkingDirectory=/opt/${PROJECT_NAME}
ExecStart=/usr/bin/node /opt/${PROJECT_NAME}/server.js
Restart=always
User=${SUDO_USER:-root}
Environment=NODE_ENV=production

[Install]
WantedBy=multi-user.target
EOF

  systemctl daemon-reload
  systemctl enable --now "${PROJECT_NAME}.service"
fi

# ----------------------------
# Nginx reverse proxy -> API
# ----------------------------
log "Config Nginx (reverse proxy vers l’API Node sur localhost:${API_PORT})"
cat > "/etc/nginx/sites-available/${NGINX_SITE_NAME}" <<EOF
server {
    listen 80;
    server_name _;

    # reverse proxy API
    location /api/ {
        proxy_pass http://127.0.0.1:${API_PORT}/;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }

    # page simple (tu remplaceras par ton front)
    location / {
        return 200 "Projet SIN OK. API: /api/health\\n";
        add_header Content-Type text/plain;
    }
}
EOF

ln -sf "/etc/nginx/sites-available/${NGINX_SITE_NAME}" "/etc/nginx/sites-enabled/${NGINX_SITE_NAME}"
rm -f /etc/nginx/sites-enabled/default || true

nginx -t
systemctl reload nginx

# ----------------------------
# Résumé
# ----------------------------
IP="$(detect_ip)"
log "Terminé."

echo "============================================================="
echo "Accès:"
echo "  - Nginx:        http://${IP:-<ip_du_rpi>}/"
echo "  - API health:   http://${IP:-<ip_du_rpi>}/api/health"
echo ""
echo "MariaDB:"
echo "  - Root password: ${DB_ROOT_PASS}"
echo "  - DB name:       ${DB_NAME}"
echo "  - App user:      ${DB_USER}"
echo "  - App password:  ${DB_PASS}"
echo ""
echo "Commandes utiles:"
echo "  - Voir status API:   systemctl status ${PROJECT_NAME}.service"
echo "  - Logs API:          journalctl -u ${PROJECT_NAME}.service -f"
echo "  - Se connecter DB:   mariadb -u ${DB_USER} -p${DB_PASS} ${DB_NAME}"
echo "============================================================="