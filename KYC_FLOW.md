# Flux KYC (Know Your Customer)

## Vue d'ensemble

Le système KYC guide l'utilisateur pour compléter son profil en 3 étapes obligatoires avant d'accéder au dashboard.

## Les 3 étapes

### 1. Informations personnelles
- **Action** : Aller dans le profil
- **Éléments à compléter** :
  - Date de naissance
  - Genre
  - Nationalité
  - Profession
  - Employeur

### 2. Adresse de résidence
- **Action** : Ajouter l'adresse dans le profil
- **Éléments à compléter** :
  - Adresse principale
  - Ville
  - Code postal
  - Pays

### 3. Documents d'identification
- **Actions** : Télécharger les documents
- **Documents requis** :
  - Pièce d'identité
  - Passeport (optionnel)
  - Justificatif de domicile

## Flux utilisateur

```
Connexion/Inscription
        ↓
Verification KYC (Splash Screen ou après login)
        ↓
   ┌────┴────┐
   │         │
OUI        NON (isComplete = false)
   │         │
   ↓         ↓
Dashboard   KYC Screen
        │
        ├─► Étape 1: Profil
        ├─► Étape 2: Adresse  
        └─► Étape 3: Documents
              │
              ↓
          Dashboard
```

## Implémentation

### Vérification du statut

Le `ProfileProvider` expose :
```dart
bool isComplete          // true si 100%
int completionPercentage // Pourcentage de complétion
```

### Redirection automatique

Après connexion :
```dart
KycRedirection.redirectAfterLogin(context);
```

### Dans le splash screen

```dart
if (!profileProvider.isComplete) {
  context.go('/kyc');
} else {
  context.go('/dashboard');
}
```

## UI/UX

### Design mobile-first
- ✅ Navigation par swipes
- ✅ Indicateurs de progression clairs
- ✅ Icônes pour chaque étape
- ✅ Cards cliquables
- ✅ Feedback visuel

### Expérience utilisateur
- Navigation intuitive
- Pas de blocage (l'utilisateur peut naviguer entre étapes)
- Progression sauvegardée
- Retour possible pour compléter les informations

## Prochaines améliorations

- [ ] Validation en temps réel des champs
- [ ] Prévisualisation des documents uploadés
- [ ] Aide contextuelle pour chaque étape
- [ ] Sauvegarde automatique brouillon
- [ ] Barre de progression plus détaillée


