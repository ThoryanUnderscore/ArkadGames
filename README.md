# 🕹️ ARKAD GAMES

ARKAD GAMES est une plateforme de jeux d'arcade développée entièrement en Bash (Linux). Ce projet scolaire regroupe plusieurs classiques du jeu de réflexion et d'adresse, accessibles via une interface centralisée et intuitive.

## 📋 Présentation du projet

La plateforme repose sur une architecture modulaire :
  Gestionnaire central : Le script menu.sh sert de point d'entrée unique.
  Indépendance : Chaque jeu possède son propre script et son propre environnement d'exécution, garantissant une absence totale de conflits de données et une maintenance simplifiée.
  Documentation : Le code source est intégralement commenté pour expliquer chaque fonctionnalité et faciliter la compréhension de la logique de programmation.

## 🎮 Jeux Disponibles

Le catalogue actuel comprend 5 jeux emblématiques (sur un total de 7 prévus) :
  MASTERMIND : Déduisez la combinaison secrète de couleurs.
  PENDU : Devinez le mot caché avant qu'il ne soit trop tard.
  PUISSANCE 4 : Alignez quatre jetons avant votre adversaire.
  SIMON : Testez votre mémoire visuelle et auditive en reproduisant des suites de couleurs.
  MEMORY : Retrouvez toutes les paires de cartes identiques.

## 🛠️ Structure du Projet

.
├── menu.sh              # Script principal (lanceur)
├── Games/               # Répertoire contenant les jeux
│   ├── mastermind.sh
│   ├── pendu.sh
│   ├── puissance4.sh
│   ├── simon.sh
│   └── memory.sh
└── README.md            # Documentation

## 🚀 Installation et Utilisation
Prérequis :
  Un environnement Linux (ou compatible Bash comme WSL sur Windows).
  Les droits d'exécution sur les scripts.
Lancement :
  Clonez le dépôt ou téléchargez les fichiers.
  Donnez les permissions d'exécution :
    chmod +x menu.sh games/*.sh
  Lancez la plateforme :
    bash ./menu.sh

## 💡 Philosophie de développement

  Modularité : Séparation stricte entre le menu et la logique de chaque jeu.
  Robustesse : Gestion des erreurs de saisie utilisateur pour éviter les plantages.
  Lisibilité : Code documenté pour permettre une évolution future du projet (ajout de nouveaux jeux).
