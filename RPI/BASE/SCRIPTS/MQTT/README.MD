# Installation et configuration de MQTT sur le Raspberry Pi

## Présentation

Dans le cadre du projet **Projet_SIN**, le protocole **MQTT** est utilisé pour assurer la communication entre les différents équipements du système :

- les **Arduino** présents dans chaque salle
- le **serveur central** hébergé sur le **Raspberry Pi**
- l'**interface web** utilisée par les enseignants

MQTT est un protocole de messagerie **léger et rapide**, conçu pour les systèmes **IoT (Internet of Things)**.  
Il permet aux capteurs et aux contrôleurs d'échanger des informations en temps réel avec très peu de bande passante.

Dans ce projet, MQTT sert à transmettre :

- l'état des capteurs (température, luminosité, fenêtres ouvertes, etc.)
- les commandes envoyées par l'interface web (allumer la lumière, couper le chauffage, etc.)

Le Raspberry Pi joue le rôle de **serveur MQTT**, appelé **broker**.

---

# Architecture MQTT dans le projet

Le fonctionnement général est le suivant :

Arduino (capteurs / actionneurs)  
↓  
MQTT  
↓  
Raspberry Pi (Broker MQTT)  
↓  
API / Backend  
↓  
Interface Web (professeurs / administration)

Les Arduino **publient** les informations des capteurs vers le broker MQTT.

Le serveur web **écoute** ces informations et peut également **envoyer des commandes** aux Arduino via MQTT.

---

# Broker MQTT utilisé

Le broker choisi pour ce projet est **Mosquitto**.

Mosquitto est :

- open source
- léger
- très utilisé dans les projets IoT
- parfaitement compatible avec Raspberry Pi

Site officiel :  
https://mosquitto.org/

---

# Installation de Mosquitto

L'installation se fait directement sur le Raspberry Pi à l'aide d'un script d'installation présent dans ce dépôt.

Ce script installe automatiquement :

- le broker Mosquitto
- les outils clients MQTT
- la configuration du service
- le démarrage automatique au boot

Le broker sera accessible sur le port standard :

1883

---

# Vérification du fonctionnement

Une fois installé, le service Mosquitto doit être actif sur le Raspberry Pi.

Le broker permet alors :

- aux Arduino de publier des données
- au serveur web de recevoir les messages
- au système d'envoyer des commandes

Les communications utilisent des **topics MQTT**.

Exemples :

lycee/salle101/temperature  
lycee/salle101/lumiere  
lycee/salle101/fenetre  
lycee/salle101/commande/lumiere  

Chaque salle possède ses propres topics afin de séparer les données.

---

# Organisation des topics MQTT

La structure utilisée dans le projet est la suivante :

lycee/  
  salleXXX/  
    temperature  
    luminosite  
    fenetre  
    chauffage  
    lumiere  
    commande/  
      lumiere  
      chauffage  

Exemple :

lycee/salle204/temperature

Un Arduino dans la salle 204 publiera la température sur ce topic.

Pour allumer la lumière :

lycee/salle204/commande/lumiere

---

# Sécurité

Dans un premier temps, le broker MQTT fonctionne en **réseau local uniquement**.

Les mesures suivantes sont prévues :

- accès limité au réseau interne du lycée
- authentification possible si nécessaire
- séparation des topics par salle

Cela garantit que :

- un professeur ne peut agir que sur **sa salle**
- le système reste **sécurisé et contrôlé**

---

# Intégration avec le reste du projet

MQTT est utilisé par plusieurs composants.

## Arduino

Les Arduino envoient les données des capteurs et reçoivent les commandes.

## Backend Node.js

Le serveur backend :

- écoute les messages MQTT
- stocke les données dans la base
- transmet les commandes envoyées par l'interface web

## Interface Web

L'interface permet :

- de visualiser l'état des salles
- d'allumer ou d'éteindre les équipements
- de surveiller les capteurs

Toutes les actions passent par le broker MQTT.

---

# Avantages de MQTT dans ce projet

L'utilisation de MQTT permet :

- une communication en temps réel
- une faible consommation réseau
- une architecture très évolutive
- une gestion simple de nombreux appareils

Cela rend le système capable de gérer facilement :

- plusieurs dizaines d'Arduino
- plusieurs salles
- de nombreux capteurs

---

# Évolution future

Le système MQTT pourra évoluer vers :

- une application mobile
- des notifications en temps réel
- une gestion énergétique du bâtiment
- une analyse des données des capteurs

MQTT restera le cœur de la communication entre tous les équipements.

---

# Conclusion

MQTT constitue l'élément central de communication du projet.

Grâce au broker Mosquitto installé sur le Raspberry Pi, tous les équipements du système peuvent échanger des informations de manière simple, rapide et fiable.

Cette architecture permet de construire un système d'automatisation du lycée **modulaire, évolutif et facilement maintenable**.
