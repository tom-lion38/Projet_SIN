# Installation native de ThingsBoard CE sur Raspberry Pi

## Présentation

Ce projet met en place un serveur ThingsBoard Community Edition installé nativement (sans Docker) sur un Raspberry Pi 4.

L’objectif est de créer une base solide pour piloter :

- Lumières des salles
- Chauffage
- Détection de fenêtres ouvertes
- Température
- Présence
- Gestion des utilisateurs (1 prof = 1 salle)

Cette architecture est évolutive vers une application mobile future sans modifier le backend.

---

## Architecture obtenue

Raspberry Pi
├── PostgreSQL
├── ThingsBoard (service systemd)
└── Interface Web (port 8080)

Accès via navigateur :

http://IP_DU_RPI:8080

---

## Prérequis

- Raspberry Pi 4 (4 Go minimum recommandé)
- Debian / Raspberry Pi OS 64-bit
- Accès root (sudo)
- Connexion Internet

---

## Installation

1. Rendre le script exécutable :

chmod +x install_thingsboard_native_rpi.sh

2. Lancer l’installation :

sudo ./install_thingsboard_native_rpi.sh

L’installation est automatique.

---

## Ce que fait le script

### 1. Installation des dépendances
- Java 17
- Outils système
- OpenSSL

### 2. Installation PostgreSQL
- Ajout du dépôt officiel PGDG
- Installation PostgreSQL 16
- Activation automatique du service

### 3. Sécurisation PostgreSQL
- Génération automatique d’un mot de passe sécurisé
- Stockage dans :

/opt/projet_sin/secrets/postgres_password.txt

- Création de la base de données `thingsboard`

### 4. Installation ThingsBoard
- Téléchargement du package officiel .deb
- Installation via dpkg
- Résolution automatique des dépendances

### 5. Configuration système

Modification du fichier :

/etc/thingsboard/conf/thingsboard.conf

Configuration ajoutée :
- Connexion PostgreSQL locale
- Partitionnement mensuel des données
- Allocation mémoire JVM

### 6. Initialisation de la base

Exécution de :

/usr/share/thingsboard/bin/install/install.sh --loadDemo

Si LOAD_DEMO=true, des comptes de démonstration sont créés.

### 7. Activation du service

- Démarrage immédiat
- Activation automatique au boot

---

## Accès à l’interface

URL :

http://IP_DU_RPI:8080

### Comptes par défaut (mode demo activé)

Sysadmin
sysadmin@thingsboard.org
sysadmin

Tenant
tenant@thingsboard.org
tenant

Customer
customer@thingsboard.org
customer

---

## Commandes utiles

Vérifier le statut :

systemctl status thingsboard

Redémarrer :

systemctl restart thingsboard

Voir les logs :

tail -f /var/log/thingsboard/thingsboard.log

Logs systemd :

journalctl -u thingsboard -n 200 --no-pager

---

## Configuration mémoire

Par défaut :

JAVA_HEAP=2G

Recommandations :

- 4 Go RAM → 2G
- 8 Go RAM → 3G à 4G

La valeur est modifiable dans le script avant exécution.

---

## Variables modifiables dans le script

- TB_VER
- LOAD_DEMO
- JAVA_HEAP
- PG_VERSION

---

## Sécurité

- Mot de passe PostgreSQL généré automatiquement
- Stocké avec permissions restreintes (600)
- Installation système standard (pas de conteneur)

Pour un déploiement externe prévoir :

- Reverse proxy (Nginx)
- HTTPS
- Configuration firewall

---

## Évolution future

Cette base permet :

- 1 salle = 1 device
- 1 prof = 1 customer
- Gestion des permissions par entité
- Historique complet des données
- Intégration ESP32 / Arduino via MQTT
- Évolution vers application mobile sans modification backend

---

## Désinstallation

Arrêter le service :

systemctl stop thingsboard

Supprimer ThingsBoard :

apt remove thingsboard

Supprimer PostgreSQL :

apt remove postgresql-16

Supprimer la base :

sudo -u postgres dropdb thingsboard

---

## Conclusion

Ce script fournit une installation propre, stable et maintenable pour le projet d’automatisation du lycée.

Le serveur est prêt pour :

- Création des salles
- Création des professeurs
- Mise en place des dashboards
- Déploiement des microcontrôleurs par salle