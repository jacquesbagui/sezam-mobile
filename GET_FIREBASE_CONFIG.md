# Obtenir la configuration Firebase correcte

## Problème

Le fichier `GoogleService-Info.plist` n'a pas le bon Bundle ID ou des identifiants invalides.

## Solution - Télécharger depuis Firebase Console

### Étape 1 : Aller sur Firebase Console

1. Ouvrir [Firebase Console](https://console.firebase.google.com/)
2. Sélectionner le projet **sezam-88792**

### Étape 2 : Ajouter l'app iOS

1. Cliquer sur l'icône iOS dans "Add an app"
2. Entrer le Bundle ID : **com.example.sezam**
3. Entrer le nom de l'app : **Sezam** (optionnel)
4. Cliquer sur "Register app"

### Étape 3 : Télécharger le fichier de configuration

1. Télécharger le fichier `GoogleService-Info.plist`
2. Ouvrir le fichier téléchargé et vérifier que le BUNDLE_ID est bien `com.example.sezam`
3. Remplacer le fichier existant :

```bash
# Sauvegarder l'ancien
mv ios/Runner/GoogleService-Info.plist ios/Runner/GoogleService-Info.plist.backup

# Copier le nouveau
cp ~/Downloads/GoogleService-Info.plist ios/Runner/
```

### Étape 4 : Pour Android (si nécessaire)

1. Dans Firebase Console, ajouter une app Android
2. Package name : **com.example.sezam**
3. Télécharger `google-services.json`
4. Copier dans `android/app/`

### Étape 5 : Reconstruire

```bash
flutter clean
flutter pub get
cd ios && pod install && cd ..
flutter run
```

## Alternative : Utiliser FlutterFire CLI (recommandé)

```bash
# Installer
dart pub global activate flutterfire_cli

# Configuration automatique
flutterfire configure
```

Cette commande :
- ✅ Génère les bons fichiers pour iOS et Android
- ✅ Met à jour le code Flutter automatiquement
- ✅ Configure tout correctement

## Vérification

Après configuration, vous devriez voir :
```
✅ Firebase initialized successfully
✅ Permission accordée
📱 FCM Token obtenu: ...
```

## Bundle ID actuel

Votre projet Xcode utilise : **com.example.sezam**  
Firebase doit être configuré avec ce même Bundle ID.


