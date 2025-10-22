Contexte du Projet
SEZAM est une application mobile d'identité numérique sécurisée permettant aux utilisateurs de centraliser et partager leurs documents d'identité de manière contrôlée avec des prestataires de services (banques, assurances, etc.).
Objectif du Design
Créer une interface utilisateur moderne, intuitive et sécurisante pour une application mobile de gestion d'identité numérique, développée en Flutter, destinée aux marchés africains (focus Sénégal/Côte d'Ivoire).

Spécifications Techniques

Plateforme : Flutter (iOS 13+ / Android 6.0+)
Résolutions cibles :

Mobile : 375x812 (iPhone X), 360x800 (Android standard)
Design responsive et adaptatif


Dark mode : Oui (obligatoire)
Langues : Français (principal), Anglais (secondaire)


Palette de Couleurs Recommandée
Option 1 : Confiance & Sécurité (Bleu professionnel)
- Primary: #0066FF (Bleu électrique)
- Primary Dark: #0047B3
- Secondary: #00D4AA (Vert/turquoise - validation)
- Background: #FFFFFF / #F8F9FA (Light) | #1A1D23 (Dark)
- Surface: #FFFFFF / #F5F6F7 (Light) | #25282E (Dark)
- Error: #FF3B30
- Warning: #FF9500
- Success: #34C759
- Text Primary: #1C1C1E / #FFFFFF
- Text Secondary: #8E8E93 / #AEAEB2
```

### Option 2 : Chaleur Africaine (Orange/Terracotta)
```
- Primary: #FF6B35 (Orange chaleureux)
- Primary Dark: #CC4A1A
- Secondary: #004E89 (Bleu profond)
- Accent: #F7931E (Or/sable)

Écrans Principaux à Designer
1. Onboarding / Welcome (3-4 écrans)
Objectif : Expliquer la valeur de l'app

Illustration moderne style flat/3D minimaliste
Titres accrocheurs + sous-titres explicatifs
Indicateurs de progression (dots)
Boutons "Suivant" et "Passer"

Messages clés :

"Centralisez votre identité numérique"
"Partagez vos documents en toute sécurité"
"Contrôlez qui accède à vos données"


2. Authentification
2a. Inscription

Sélection du mode : Email ou Téléphone (tabs ou cards)
Champ input avec validation en temps réel
Checkbox "J'accepte les conditions d'utilisation"
Bouton CTA principal "Créer mon compte"
Lien "Déjà inscrit ? Se connecter"
Icône de sécurité/cadenas visible

2b. Connexion

Input Email/Téléphone avec icône
Input Mot de passe avec toggle show/hide
Checkbox "Se souvenir de moi"
Bouton "Se connecter"
Lien "Mot de passe oublié ?"
Option biométrique (empreinte/Face ID) visible en bas

2c. Vérification OTP

6 champs pour code OTP avec focus automatique
Timer countdown (ex: "Renvoyer dans 0:45")
Bouton "Renvoyer le code"
Illustration d'un smartphone recevant un message

2d. Configuration 2FA

Explication simple de la 2FA
QR Code pour scanner (Google Authenticator)
Champ pour vérifier le code 2FA
Codes de secours affichés dans des cards
Bouton "Activer la double authentification"


3. Dashboard / Accueil
Header :

Photo de profil (cercle) + nom utilisateur
Badge de statut vérification (icône checkmark vert)
Notification bell avec badge count
Menu hamburger ou bouton profil

Statistiques Cards (3 cartes horizontales) :

"Documents stockés" (icône dossier) - nombre
"Connexions actives" (icône lien) - nombre
"Alertes" (icône attention) - nombre

Section "Actions Rapides" (Grid 2x2) :

"Ajouter un document" (icône upload +)
"Demandes en attente" (icône horloge)
"Mes connexions" (icône réseau)
"Scanner QR Code" (icône QR)

Timeline / Activité Récente :

Liste des derniers événements avec icônes
Timestamp relatif ("Il y a 2h")
Swipe actions (si applicable)

Bottom Navigation Bar :

Accueil (icône maison)
Documents (icône fichier)
Demandes (icône bell)
Profil (icône user)


4. Gestion des Documents
4a. Liste des Documents

Search bar en haut
Filtres par type (chips/badges) : CNI, Passeport, Justificatif, etc.
Cards de documents avec :

Thumbnail/icône du type de document
Nom du document
Date d'ajout
Badge de statut (Vérifié/En attente/Expiré)
Date d'expiration (si applicable) avec code couleur
Menu 3 dots (options)



4b. Détail d'un Document

Image/PDF viewer en haut (zoomable)
Informations structurées :

Type de document
Numéro
Date d'émission / Date d'expiration
Statut de vérification


Tags/métadonnées
Boutons d'actions :

Modifier
Télécharger
Partager
Supprimer (icône poubelle rouge)



4c. Ajout de Document

Choix source :

Prendre photo (icône appareil photo)
Choisir depuis galerie (icône image)


Sélection type de document (dropdown ou cards)
Formulaire avec champs :

Nom du document
Type (dropdown)
Numéro
Date d'émission / expiration (date picker)


Preview de l'image uploadée
Bouton "Enregistrer" (disabled tant que formulaire invalide)


5. Demandes de Connexion / Autorisations
5a. Notification de Demande (Modal/Bottom Sheet)

Logo du prestataire en haut
Nom du prestataire
Type de service (badge)
Message : "X souhaite accéder à vos informations"
Liste des données demandées avec icônes :

☑️ Nom et prénom
☑️ Date de naissance
☑️ Pièce d'identité
etc.


Toggle switches pour personnaliser
Sélecteur de durée d'accès :

1 mois
3 mois
6 mois
Illimité


Boutons :

"Accepter" (vert, primary)
"Refuser" (rouge, outline)
"Personnaliser" (secondaire)



5b. Liste des Demandes

Tabs : En attente / Acceptées / Refusées
Cards avec :

Logo prestataire
Nom + date de la demande
Nombre d'informations demandées
Status badge
Bouton action rapide



5c. Historique des Accès

Timeline avec :

Prestataire
Action effectuée ("A consulté vos documents")
Date et heure
Données accessibles (expandable)


Bouton "Révoquer l'accès" (rouge)


6. Gestion des Connexions Actives
Liste des Prestataires Connectés

Cards avec :

Logo + nom du prestataire
Type de service (badge)
Date de connexion
Date d'expiration
Badge "Actif" vert
Menu 3 dots :

Voir les détails
Modifier les autorisations
Révoquer




Pull to refresh

Détail d'une Connexion

Header avec logo et infos prestataire
Section "Données partagées" :

Liste avec icônes et toggle switches


Section "Historique d'accès" :

Timeline des consultations


Section "Paramètres" :

Durée d'accès (slider ou sélecteur)
Notifications (toggle)


Bouton danger "Révoquer la connexion"


7. Profil Utilisateur
7a. Vue Profil

Header avec :

Photo de profil (grande, éditable)
Nom complet
Badge de vérification
Email
Téléphone


Sections en cards/liste :

Informations personnelles

Date de naissance
Lieu de naissance
Nationalité
Adresse


Informations professionnelles

Situation professionnelle
Revenus approximatifs
Source des fonds


Sécurité

Changer mot de passe
Gérer 2FA
Appareils connectés


Préférences

Langue
Notifications
Mode sombre


Support

Centre d'aide
Nous contacter
Conditions d'utilisation
Politique de confidentialité


Compte

Télécharger mes données
Supprimer mon compte (rouge)





7b. Édition du Profil

Formulaire avec tous les champs éditables
Upload/changement photo de profil
Validation en temps réel
Boutons "Annuler" et "Enregistrer"


8. Scanner QR Code

Overlay caméra avec frame de scan
Instructions en haut : "Scannez le QR Code du prestataire"
Bouton "Activer le flash" (si sombre)
Bouton "Choisir depuis galerie"
Animation lors du scan réussi
Transition vers écran de demande de connexion


9. Paramètres / Settings
Liste organisée par sections :
Compte

Modifier le profil
Changer l'email
Changer le numéro de téléphone

Sécurité et confidentialité

Changer le mot de passe
Authentification à deux facteurs
Appareils connectés
Activité de connexion

Notifications

Demandes de connexion (toggle)
Accès aux documents (toggle)
Documents expirés (toggle)
Mises à jour (toggle)

Apparence

Thème (Light / Dark / Auto)
Langue

Assistance

Centre d'aide / FAQ
Contacter le support
Signaler un problème

Légal

Conditions d'utilisation
Politique de confidentialité
À propos

Danger Zone

Se déconnecter (rouge outline)
Supprimer mon compte (rouge solid)


10. États et Écrans Spéciaux
Empty States

Aucun document : Illustration + "Ajoutez votre premier document"
Aucune demande : Illustration + message encourageant
Aucune connexion active

Error States

Erreur de chargement : Illustration + "Réessayer"
Erreur réseau : Illustration + conseils
Document non valide

Loading States

Skeletons screens pour chaque écran
Spinners pour actions
Progress bars pour uploads

Success States

Modals de confirmation avec icône checkmark
Toast notifications pour actions rapides


Composants UI à Inclure
Boutons

Primary (solid, filled)
Secondary (outline)
Text buttons
Icon buttons
Floating Action Button (FAB)

Inputs

Text fields (avec icônes)
Password fields (avec toggle)
Dropdowns/Select
Date pickers
Toggle switches
Checkboxes
Radio buttons
Search bars

Cards

Standard cards avec shadow
Cards avec actions
Cards expandables
Cards swipeable

Listes

Liste simple
Liste avec avatars
Liste avec icônes
Liste avec actions (swipe)

Navigation

Bottom navigation bar
Top app bar
Drawer menu (si nécessaire)
Tabs

Feedback

Snackbars / Toast
Modals / Dialogs
Bottom sheets
Alert dialogs
Progress indicators

Autres

Badges / Pills
Chips
Avatars
Dividers
Icons (set cohérent)


Principes de Design à Respecter
1. Sécurité Visuelle

Utiliser des icônes de cadenas, boucliers pour rassurer
Badges de vérification visibles
Indicateurs de chiffrement
Codes couleur pour les niveaux de risque

2. Clarté et Lisibilité

Typographie claire (SF Pro pour iOS, Roboto pour Android)
Hiérarchie visuelle nette
Espaces blancs généreux
Contraste WCAG AA minimum

3. Accessibilité

Tailles de touch targets ≥ 44x44 pt
Labels pour screen readers
Support des tailles de police système
Éviter de se reposer uniquement sur la couleur

4. Cohérence

Spacing system (8pt grid)
Border radius cohérents (8px, 12px, 16px)
Shadows system (élévations)
Animations cohérentes (200-300ms)

5. Performance Visuelle

Images optimisées
Lazy loading évident
Skeleton screens pendant chargement
Feedback immédiat sur les interactions


Animations et Micro-interactions

Transitions : Écrans glissent de droite à gauche
Boutons : Scale légère au tap (0.95)
Listes : Slide in/out lors du swipe
Success : Checkmark animé avec bounce
Loading : Shimmer effect sur skeletons
Notifications : Slide down from top
Modals : Fade in avec scale
Biométrie : Pulse animation sur l'icône


Références de Style (Inspiration)

Monzo (banking) : Clarté et simplicité
Revolut : Navigation intuitive
N26 : Minimalisme efficace
Uber : Interactions fluides
Airbnb : Convivialité et confiance


Livrables Attendus

Kit UI Figma/Sketch avec :

Tous les écrans en Light et Dark mode
Components library réutilisables
Style guide (couleurs, typographie, spacing)
Prototype interactif de navigation


Design System Documentation :

Guidelines d'utilisation des composants
Règles de spacing et layout
Iconographie
Animations specs


Assets :

Icônes exportées (SVG)
Illustrations (SVG ou PNG @1x, @2x, @3x)
Splash screen et app icon


Specs pour développeurs :

Annotations de dimensions
Codes couleur (hex)
Typographie (font family, sizes, weights)
États des composants
