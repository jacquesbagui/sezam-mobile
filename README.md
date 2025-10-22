# SEZAM - Application d'Identité Numérique Sécurisée

SEZAM est une application mobile d'identité numérique sécurisée permettant aux utilisateurs de centraliser et partager leurs documents d'identité de manière contrôlée avec des prestataires de services (banques, assurances, etc.).

## 🚀 Fonctionnalités

### ✅ Implémentées
- **Splash Screen** : Écran de démarrage avec animation
- **Onboarding** : Flow d'introduction avec 4 étapes explicatives
- **Authentification** : Connexion/Inscription avec validation
- **Dashboard** : Écran principal avec statistiques et actions rapides
- **Design System** : Composants UI cohérents et thème sombre/clair
- **Navigation** : Navigation bottom avec indicateurs

### 🔄 À implémenter
- Gestion des documents (ajout, visualisation, suppression)
- Scanner QR Code pour connexions
- Gestion des demandes de connexion
- Profil utilisateur et paramètres
- Authentification biométrique
- Notifications push

## 🛠️ Technologies Utilisées

- **Flutter** : Framework de développement mobile
- **Go Router** : Navigation déclarative
- **Google Fonts** : Typographie (Inter/Roboto)
- **Provider** : Gestion d'état (préparé)
- **Shared Preferences** : Stockage local
- **Local Auth** : Authentification biométrique

## 📱 Plateformes Supportées

- **iOS** : 13.0+
- **Android** : API 23+ (Android 6.0)

## 🎨 Design System

### Couleurs Principales
- **Primary** : `#0066FF` (Bleu électrique)
- **Secondary** : `#00D4AA` (Vert/Turquoise)
- **Success** : `#34C759`
- **Warning** : `#FF9500`
- **Error** : `#FF3B30`

### Typographie
- **Police principale** : Inter (Google Fonts)
- **Police secondaire** : Roboto
- **Tailles** : 12px à 36px avec hiérarchie claire

### Espacement
- **Système de grille** : 8pt
- **Rayons de bordure** : 4px à 32px
- **Ombres** : 5 niveaux (xs, sm, md, lg, xl)

## 🏗️ Architecture du Projet

```
lib/
├── core/                    # Code partagé
│   ├── theme/              # Design system
│   │   ├── app_colors.dart
│   │   ├── app_spacing.dart
│   │   ├── app_typography.dart
│   │   └── app_theme.dart
│   ├── widgets/             # Composants UI réutilisables
│   │   ├── sezam_button.dart
│   │   ├── sezam_text_field.dart
│   │   └── sezam_card.dart
│   ├── navigation/         # Navigation
│   │   └── sezam_navigation.dart
│   └── router/             # Configuration des routes
│       └── app_router.dart
├── features/               # Fonctionnalités par écran
│   ├── splash/
│   ├── onboarding/
│   ├── auth/
│   └── dashboard/
└── main.dart              # Point d'entrée
```

## 🚀 Installation et Lancement

### Prérequis
- Flutter SDK 3.9.2+
- Dart SDK
- Android Studio / Xcode
- Émulateur ou appareil physique

### Installation
1. **Cloner le projet**
   ```bash
   git clone <repository-url>
   cd sezam
   ```

2. **Installer les dépendances**
   ```bash
   flutter pub get
   ```

3. **Lancer l'application**
   ```bash
   flutter run
   ```

### Commandes Utiles
```bash
# Analyser le code
flutter analyze

# Formater le code
flutter format .

# Tests
flutter test

# Build pour production
flutter build apk --release  # Android
flutter build ios --release  # iOS
```

## 📋 Écrans Implémentés

### 1. Splash Screen
- Logo animé avec effet de scale et fade
- Transition automatique vers l'onboarding
- Durée : 3 secondes

### 2. Onboarding
- 4 pages explicatives avec animations
- Indicateurs de progression
- Boutons "Suivant" et "Passer"
- Messages clés :
  - "Centralisez votre identité numérique"
  - "Partagez vos documents en toute sécurité"
  - "Contrôlez qui accède à vos données"
  - "Connexions instantanées"

### 3. Authentification
- Formulaire de connexion/inscription
- Validation en temps réel
- Option "Se souvenir de moi"
- Bouton d'authentification biométrique
- Récupération de mot de passe

### 4. Dashboard
- En-tête avec informations utilisateur
- Statistiques (Documents, Connexions, Alertes)
- Actions rapides (Ajouter document, Scanner QR, etc.)
- Activité récente
- Navigation bottom avec 4 onglets

## 🎯 Prochaines Étapes

1. **Gestion des Documents**
   - Ajout de documents (photo/galerie)
   - Visualisation et édition
   - Catégorisation et tags

2. **Scanner QR Code**
   - Intégration de la caméra
   - Détection et parsing des QR codes
   - Gestion des connexions

3. **Demandes de Connexion**
   - Liste des demandes en attente
   - Acceptation/refus avec personnalisation
   - Historique des connexions

4. **Profil Utilisateur**
   - Informations personnelles
   - Paramètres de sécurité
   - Préférences d'application

## 🔒 Sécurité

- Chiffrement des données sensibles
- Authentification biométrique
- Validation des documents
- Audit trail des accès
- Conformité RGPD

## 📄 Licence

Ce projet est sous licence MIT. Voir le fichier `LICENSE` pour plus de détails.

## 🤝 Contribution

Les contributions sont les bienvenues ! Merci de :
1. Fork le projet
2. Créer une branche feature
3. Commiter vos changements
4. Pousser vers la branche
5. Ouvrir une Pull Request

## 📞 Support

Pour toute question ou problème :
- Ouvrir une issue sur GitHub
- Contacter l'équipe de développement

---

**SEZAM** - Votre identité numérique sécurisée 🛡️