#!/usr/bin/env bash
# install_thingsboard_native_rpi.sh
# Install ThingsBoard CE nativement (sans Docker) sur Debian/Raspberry Pi OS 64-bit.
# - Java 17
# - PostgreSQL + DB thingsboard
# - ThingsBoard .deb + init DB + service
#
# Usage:
#   chmod +x install_thingsboard_native_rpi.sh
#   sudo ./install_thingsboard_native_rpi.sh
#
# Après install:
#   http://<IP_RPI>:8080
#
set -Eeuo pipefail

# ================== Réglages ==================
TB_VER="${TB_VER:-4.3.0.1}"          # Version ThingsBoard CE
LOAD_DEMO="${LOAD_DEMO:-true}"       # true/false
JAVA_HEAP="${JAVA_HEAP:-2G}"         # 2G recommandé sur petites machines
PG_VERSION="${PG_VERSION:-16}"       # Version PostgreSQL (repo PGDG)

INSTALL_DIR="/opt/projet_sin"        # Ton dossier projet (où tu ranges tes fichiers)
SECRETS_DIR="${INSTALL_DIR}/secrets"
PG_PASS_FILE="${SECRETS_DIR}/postgres_password.txt"
TB_CONF="/etc/thingsboard/conf/thingsboard.conf"
# ==============================================

if [[ "${EUID}" -ne 0 ]]; then
  echo "Lance ce script en root: sudo $0"
  exit 1
fi

log() { echo -e "\n[+] $*"; }
warn() { echo -e "\n[!] $*"; }

log "1/9 Préparation dossiers projet + secrets"
mkdir -p "${SECRETS_DIR}"
chmod 700 "${SECRETS_DIR}"

log "2/9 Paquets de base + Java 17"
apt update
apt install -y ca-certificates curl wget gnupg lsb-release openssl openjdk-17-jdk-headless

log "3/9 Ajout du dépôt PostgreSQL (PGDG) + installation PostgreSQL ${PG_VERSION}"
install -d -m 0755 /etc/apt/keyrings
if [[ ! -f /etc/apt/keyrings/postgresql.gpg ]]; then
  curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc | gpg --dearmor -o /etc/apt/keyrings/postgresql.gpg
fi
echo "deb [signed-by=/etc/apt/keyrings/postgresql.gpg] https://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" \
  > /etc/apt/sources.list.d/pgdg.list
apt update
apt install -y "postgresql-${PG_VERSION}"
systemctl enable --now postgresql

log "4/9 Génération (ou lecture) du mot de passe postgres"
if [[ -f "${PG_PASS_FILE}" ]]; then
  POSTGRES_PASS="$(cat "${PG_PASS_FILE}")"
else
  POSTGRES_PASS="$(openssl rand -base64 24 | tr -d '\n' | tr -d '/+=' | cut -c1-24)"
  echo "${POSTGRES_PASS}" > "${PG_PASS_FILE}"
  chmod 600 "${PG_PASS_FILE}"
fi

log "5/9 Configuration PostgreSQL (mot de passe + DB thingsboard)"
sudo -u postgres psql -v ON_ERROR_STOP=1 -c "ALTER USER postgres WITH PASSWORD '${POSTGRES_PASS}';"

DB_EXISTS="$(sudo -u postgres psql -tAc "SELECT 1 FROM pg_database WHERE datname='thingsboard';" || true)"
if [[ "${DB_EXISTS}" != "1" ]]; then
  sudo -u postgres psql -v ON_ERROR_STOP=1 -c "CREATE DATABASE thingsboard;"
else
  warn "DB 'thingsboard' existe déjà, on garde."
fi

log "6/9 Téléchargement + installation ThingsBoard CE v${TB_VER} (.deb)"
cd /tmp
TB_DEB="thingsboard-${TB_VER}.deb"
if [[ ! -f "${TB_DEB}" ]]; then
  wget -q "https://github.com/thingsboard/thingsboard/releases/download/v${TB_VER}/${TB_DEB}"
fi

dpkg -i "${TB_DEB}" || true
apt -f install -y

log "7/9 Configuration ThingsBoard (PostgreSQL + mémoire)"
touch "${TB_CONF}"

# Nettoyage idempotent (si relancé)
sed -i '/^export DATABASE_TS_TYPE=/d' "${TB_CONF}"
sed -i '/^export SPRING_DATASOURCE_URL=/d' "${TB_CONF}"
sed -i '/^export SPRING_DATASOURCE_USERNAME=/d' "${TB_CONF}"
sed -i '/^export SPRING_DATASOURCE_PASSWORD=/d' "${TB_CONF}"
sed -i '/^export SQL_POSTGRES_TS_KV_PARTITIONING=/d' "${TB_CONF}"
# Supprime une ancienne ligne JAVA_OPTS -Xms/-Xmx si présente
sed -i '/^export JAVA_OPTS="\$JAVA_OPTS -Xms.*-Xmx.*"$/d' "${TB_CONF}"

cat >> "${TB_CONF}" <<EOF

# ===== Projet_SIN - ThingsBoard (auto) =====
export DATABASE_TS_TYPE=sql
export SPRING_DATASOURCE_URL=jdbc:postgresql://localhost:5432/thingsboard
export SPRING_DATASOURCE_USERNAME=postgres
export SPRING_DATASOURCE_PASSWORD=${POSTGRES_PASS}
export SQL_POSTGRES_TS_KV_PARTITIONING=MONTHS

# Mémoire JVM
export JAVA_OPTS="\$JAVA_OPTS -Xms${JAVA_HEAP} -Xmx${JAVA_HEAP}"
# ==========================================
EOF

log "8/9 Initialisation DB ThingsBoard (install.sh) + démarrage service"
if [[ "${LOAD_DEMO}" == "true" ]]; then
  /usr/share/thingsboard/bin/install/install.sh --loadDemo
else
  /usr/share/thingsboard/bin/install/install.sh
fi

systemctl enable --now thingsboard

log "9/9 Vérification + infos"
IP="$(hostname -I | awk '{print $1}')"
TB_STATUS="$(systemctl is-active thingsboard || true)"

echo
echo "=== Résumé ==="
echo "ThingsBoard: ${TB_STATUS}"
echo "URL:        http://${IP}:8080"
echo "Logs:       tail -f /var/log/thingsboard/thingsboard.log"
echo "PG pass:    ${PG_PASS_FILE} (chmod 600)"
echo
if [[ "${LOAD_DEMO}" == "true" ]]; then
  echo "Comptes demo:"
  echo "  Sysadmin: sysadmin@thingsboard.org / sysadmin"
  echo "  Tenant:   tenant@thingsboard.org   / tenant"
  echo "  Customer: customer@thingsboard.org / customer"
fi
echo
echo "Commandes utiles:"
echo "  systemctl status thingsboard"
echo "  systemctl restart thingsboard"
echo "  journalctl -u thingsboard -n 200 --no-pager"
