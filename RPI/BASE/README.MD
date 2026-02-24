# 🏫 SMART LYCÉE CONTROL SYSTEM  
## 🎓 Projet STI2D – Spécialité SIN  
### RPI / BASE – Serveur Central

---

![Status](https://img.shields.io/badge/Status-En%20Développement-orange)
![Platform](https://img.shields.io/badge/Platform-Raspberry%20Pi%204B-red)
![Backend](https://img.shields.io/badge/Backend-API%20Backend-blue)
![Database](https://img.shields.io/badge/Database-SQL-green)
![Security](https://img.shields.io/badge/Security-Auth%20%2B%20Permissions-critical)

---

# 🧠 Centre de Commande du Lycée

Ce dossier représente le cerveau numérique du projet.

Le Raspberry Pi 4B héberge l’infrastructure centrale permettant d’automatiser :

- 💡 Les lumières  
- 🖥️ Les ordinateurs  
- 🔥 Le chauffage  
- 🚪 Autres équipements électriques  

Chaque professeur dispose d’un accès sécurisé limité à sa salle.

---

# 🎯 Objectif du Serveur

Centraliser :

- 🌐 Interface Web  
- 🔐 Authentification  
- 🗄️ Base de données  
- 🔌 API Arduino  
- 📊 Logs & supervision  
- 🏫 Gestion des salles  

---

# 🏗️ Architecture Globale

Professeur (PC / Tablette)  
        ↓  
Serveur Web (RPI)  
        ↓  
API Backend  
        ↓  
Base de Données  
        ↓  
Arduino Salle  
        ↓  
Relais → Lumière / PC / Chauffage  

Le Raspberry Pi agit comme :

- 🧠 Serveur central  
- 🔐 Contrôleur d’accès  
- 📡 Coordinateur réseau  
- 🗃️ Gestionnaire de données  

---

# 🌐 Serveur Web

Permet aux professeurs :

- De se connecter avec identifiant sécurisé  
- D’accéder uniquement à leur salle  
- De contrôler les équipements  
- De visualiser l’état en temps réel  

Interface prévue :

- Dashboard moderne  
- Boutons ON/OFF  
- Affichage statut équipements  
- Compatible PC / tablette  

---

# 🔐 Système d’Authentification

Chaque professeur possède :

- Identifiant unique  
- Mot de passe sécurisé (hashé)  
- Accès limité par salle  

Exemple :

| Utilisateur | Accès |
|-------------|--------|
| prof_sin | Salle SIN uniquement |
| prof_math | Salle Maths uniquement |
| admin | Toutes les salles |

---

# 🗄️ Base de Données

Stocke :

- Comptes utilisateurs  
- Permissions  
- Salles  
- Historique des actions  
- Logs sécurité  

Exemple de log :

| Prof | Salle | Action | Date |
|------|-------|--------|------|
| SIN | B203 | Lumière ON | 08:12 |

---

# 🔌 API & Communication Arduino

Communication locale via :

- Requêtes HTTP  
- Format JSON  
- Commandes sécurisées  

Exemple logique :

POST /api/salle/B203/lumiere  
{  
  "etat": "on"  
}

L’Arduino active le relais correspondant.

---

# 📊 Logs & Supervision

Chaque action est enregistrée :

- Qui  
- Quand  
- Quelle salle  
- Quelle action  

Objectifs :

- Sécurité  
- Traçabilité  
- Diagnostic  
- Optimisation énergétique  

---

# 🌍 Schéma Réseau

Internet  
   ↓  
Routeur (Livebox)  
   ↓  
Raspberry Pi 4B – 192.168.1.100  
   ↓  
Arduino A – 192.168.1.201  
Arduino B – 192.168.1.202  
Arduino SIN – 192.168.1.203  
   ↓  
Relais → Lumière / PC / Chauffage  

---

# 🛡️ Sécurité

- Accès réseau local uniquement  
- Authentification obligatoire  
- Isolation des permissions  
- Hash des mots de passe  
- Journalisation complète  

---

# 📦 Services à installer sur le Raspberry Pi

- Serveur Web  
- Backend API  
- Base de données SQL  
- Gestionnaire de services  
- Système de logs  
- Service auto-démarrage  

---

# 🚀 Évolutions Futures

- 📱 Application mobile  
- 🔔 Alertes automatiques  
- 🌡️ Capteurs température  
- 🧍 Détection de présence  
- 🔐 Badge RFID  
- 📊 Dashboard administrateur global  
- ⚡ Optimisation énergétique automatique  

---

# 🏫 Vision Finale

Un lycée où :

- Chaque professeur contrôle uniquement sa salle  
- L’énergie est optimisée  
- Les accès sont sécurisés  
- Tout est centralisé sur un Raspberry Pi  

---

🛠️ En développement  
🎓 Projet d’automatisation intelligent – STI2D SIN  
🧠 Hébergé sur Raspberry Pi 4B  

---

Un Arduino contrôle une salle.  
Un Raspberry contrôle tout le lycée.