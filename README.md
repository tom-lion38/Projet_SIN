# 🏫 SmartSchool — Système d’Automatisation Intelligent (Raspberry Pi 4B + Arduino)

> **Projet STI2D — Spécialité SIN**  
> Plateforme centrale : **Raspberry Pi 4B** • Contrôle matériel : **Arduino**  
> Objectif : automatiser et sécuriser la gestion des équipements d’un établissement scolaire.

---

## ✨ Présentation

**SmartSchool** est un système d’automatisation modulaire visant à piloter intelligemment les équipements d’un lycée :

- 💡 **Éclairage**
- 💻 **Alimentation des PC**
- 🌡️ **Chauffage**
- 🔌 **Prises / zones électriques**
- 🧠 **Automatisations** (horaires, présence, température, luminosité…)

Le projet repose sur une architecture hybride :

- 🖥️ **Raspberry Pi 4B** : serveur central (interface web, authentification, permissions, base de données, logs)
- ⚙️ **Arduino** : contrôle local (relais, capteurs, exécution des ordres)

---

## 🎯 Objectifs

- ✅ Centraliser le contrôle des équipements
- ✅ Réduire la consommation énergétique
- ✅ Sécuriser l’accès par utilisateur (droits/permissions)
- ✅ Démontrer une architecture **IoT + réseau + sécurité**
- ✅ Mettre en place une solution évolutive, adaptée à un “smart building”

---

## 🧠 Architecture générale

### 🖥️ Raspberry Pi 4B (serveur central)

Le Raspberry Pi héberge :
- Interface web de contrôle (réseau local)
- Base de données utilisateurs et salles
- Gestion des rôles et permissions (RBAC)
- API de communication vers les Arduino
- Journalisation des actions (audit)
- Évolutions possibles : HTTPS local, statistiques, dashboard

**Le Pi = le cerveau du système.**

### ⚙️ Arduino (contrôle physique)

Chaque Arduino gère une salle ou une zone :
- Modules **relais** (lumières, PC, chauffage…)
- Capteurs : **température**, **présence**, **luminosité** (selon besoin)
- Exécute les commandes reçues du Raspberry Pi
- Retour d’état (optionnel) : ON/OFF, température, présence…

**L’Arduino = les muscles du système.**

---

## 🔐 Gestion des accès (sécurité)

Chaque utilisateur dispose :
- d’un **identifiant**
- d’un **mot de passe**
- d’un **rôle**
- de **salles autorisées**
- de **permissions** sur des équipements

### Exemple de permissions

| Utilisateur | Salle | Droits |
|-----------:|:-----:|:------|
| Prof SIN   | G113  | Lumière, PC, chauffage |
| Prof Maths | C02 & C04  | Lumière uniquement |
| CPE        | Toutes | Lumière + coupure générale |
| Admin      | Global | Accès complet |

Le système vérifie toujours :
1. Authentification valide  
2. Salle autorisée  
3. Équipement autorisé  
4. Action enregistrée dans les logs  

---

## 🌐 Fonctionnement global

1. L’utilisateur se connecte via l’interface web (sur le Raspberry Pi)
2. Le serveur vérifie l’identité et les permissions
3. Le serveur envoie une commande à l’Arduino concerné
4. L’Arduino active le relais (ou applique l’action)
5. Le serveur enregistre l’action (date, utilisateur, salle, commande)

---

## 🧰 Technologies envisagées

### Serveur (Raspberry Pi)
- Raspberry Pi OS
- Python (**Flask** ou **FastAPI**)
- Base de données : **SQLite** (simple) ou **PostgreSQL** (évolutif)
- Serveur web : **Nginx**
- Auth : sessions ou **JWT**
- Sécurité : hash des mots de passe, rôles/permissions

### Embarqué (Arduino)
- C/C++
- Modules relais 5V
- Capteurs (ex. DHT22, PIR, LDR)
- Communication : Ethernet / Wi-Fi (selon matériel)

---

## 🌱 Optimisation énergétique

SmartSchool vise des automatisations concrètes :
- Extinction automatique hors horaires
- Coupure des PC si salle vide
- Gestion chauffage par température + présence
- Statistiques de consommation
- Mode “urgence” : coupure globale (si autorisé)

---

## 🔭 Évolutions possibles

- Badge **RFID** (connexion rapide)
- Application mobile interne
- Dashboard temps réel (consommation / température)
- Intégration ENT (si applicable)
- Segmentation réseau IoT + journalisation avancée
- Scénarios automatiques (ex : “cours”, “pause”, “fin de journée”)

---

## 🎓 Problématique Grand Oral (exemple)

> **Comment une architecture distribuée basée sur Raspberry Pi et Arduino peut-elle optimiser la gestion énergétique et sécuriser le contrôle des infrastructures d’un établissement scolaire ?**

---

## 📚 Compétences mobilisées

- Systèmes embarqués
- Réseau / communication
- Cybersécurité (authentification, droits, logs)
- Développement web / API
- Base de données
- Gestion de projet (Git)

---

## 🏁 Vision d’avenir

Ce projet est une base réaliste pour évoluer vers :
- un “smart building” à grande échelle
- la gestion centralisée multi-salles / multi-bâtiments
- des économies d’énergie mesurables et pilotables

---