# Guide de génération d'APK signé pour SEZAM

Ce guide explique comment générer un APK signé pour la distribution de l'application SEZAM.

## 📋 Prérequis

- Flutter SDK installé et configuré
- Java JDK installé (pour keytool)
- Android SDK configuré

## 🔑 Étape 1 : Créer une clé de signature (première fois uniquement)

### Option A : Utiliser le script helper (recommandé)

Le plus simple est d'utiliser le script fourni :

```bash
cd android
./generate-keystore.sh
```

### Option B : Commande manuelle

#### Sur macOS avec Android Studio

Si vous avez Android Studio installé, utilisez le JDK inclus :

```bash
cd android
"/Applications/Android Studio.app/Contents/jbr/Contents/Home/bin/keytool" \
  -genkey -v \
  -keystore sezam-release-key.jks \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -alias sezam
```

#### Sur Linux/Windows ou avec Java installé

```bash
cd android
keytool -genkey -v -keystore sezam-release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias sezam
```

**Informations à fournir :**
- **Mot de passe du keystore** : Choisissez un mot de passe fort et sécurisé (minimum 6 caractères)
- **Mot de passe de la clé** : Peut être le même que le keystore ou différent (minimum 6 caractères)
- **Nom et prénom** : Votre nom ou celui de votre organisation
- **Unité organisationnelle** : Département/service (optionnel)
- **Organisation** : Nom de votre organisation
- **Ville** : Votre ville
- **État/Province** : Votre région
- **Code pays** : Code à 2 lettres (ex: FR, US)

⚠️ **IMPORTANT** : 
- Gardez ce fichier `.jks` en sécurité et faites-en une sauvegarde
- Ne partagez JAMAIS ce fichier ou les mots de passe
- Si vous perdez ce fichier, vous ne pourrez plus mettre à jour l'application sur le Play Store

## 📝 Étape 2 : Configurer key.properties

1. Copiez le fichier d'exemple :
   ```bash
   cp android/key.properties.example android/key.properties
   ```

2. Éditez `android/key.properties` et remplissez les valeurs :
   ```properties
   storePassword=votre_mot_de_passe_keystore
   keyPassword=votre_mot_de_passe_cle
   keyAlias=sezam
   storeFile=../sezam-release-key.jks
   ```

   ⚠️ **Note** : Le chemin `storeFile` est relatif au dossier `android/app/`, donc `../sezam-release-key.jks` pointe vers `android/sezam-release-key.jks`

## 🏗️ Étape 3 : Vérifier la version de l'application

Avant de générer l'APK, vérifiez et mettez à jour la version dans `pubspec.yaml` :

```yaml
version: 1.0.0+1
```

- Le format est `versionName+versionCode`
- `versionName` : Version visible par l'utilisateur (ex: 1.0.0)
- `versionCode` : Numéro de build incrémental (ex: 1, 2, 3...)

## 📦 Étape 4 : Générer l'APK signé

### Option A : Avec Flutter CLI (recommandé)

```bash
flutter build apk --release
```

L'APK sera généré dans : `build/app/outputs/flutter-apk/app-release.apk`

### Option B : APK Split par architecture (pour réduire la taille)

Pour générer des APK séparés par architecture (armeabi-v7a, arm64-v8a, x86_64) :

```bash
flutter build apk --split-per-abi --release
```

Les APK seront générés dans :
- `build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk`
- `build/app/outputs/flutter-apk/app-arm64-v8a-release.apk`
- `build/app/outputs/flutter-apk/app-x86_64-release.apk`

### Option C : App Bundle (pour Google Play Store)

Si vous publiez sur le Play Store, utilisez plutôt un App Bundle :

```bash
flutter build appbundle --release
```

L'AAB sera généré dans : `build/app/outputs/bundle/release/app-release.aab`

## ✅ Vérification de la signature

Pour vérifier que l'APK est bien signé :

```bash
# Sur macOS/Linux
jarsigner -verify -verbose -certs build/app/outputs/flutter-apk/app-release.apk

# Ou avec apksigner (Android SDK)
apksigner verify --verbose build/app/outputs/flutter-apk/app-release.apk
```

## 🔒 Sécurité

- ✅ Le fichier `key.properties` est déjà dans `.gitignore` et ne sera pas commité
- ✅ Les fichiers `.jks` et `.keystore` sont également ignorés
- ⚠️ **Ne commitez JAMAIS** :
  - `android/key.properties`
  - `android/sezam-release-key.jks` (ou tout fichier `.jks`/`.keystore`)
  - Les mots de passe dans le code

## 🚀 Distribution

### Google Play Store

1. Utilisez `flutter build appbundle --release` pour générer un AAB
2. Téléversez le fichier `.aab` sur Google Play Console
3. Remplissez les informations de la release
4. Soumettez pour révision

### Distribution directe (APK)

1. Utilisez `flutter build apk --release` pour générer l'APK
2. Partagez l'APK avec vos utilisateurs
3. Ils devront autoriser l'installation depuis des sources inconnues

## 🐛 Dépannage

### Erreur : "Unable to locate a Java Runtime" (macOS)

Sur macOS, si vous n'avez pas Java installé séparément, utilisez le JDK d'Android Studio :

```bash
# Utiliser le script helper
cd android && ./generate-keystore.sh

# Ou utiliser directement le keytool d'Android Studio
"/Applications/Android Studio.app/Contents/jbr/Contents/Home/bin/keytool" \
  -genkey -v -keystore sezam-release-key.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias sezam
```

### Erreur : "Keystore password is too short"

Le mot de passe doit contenir au moins 6 caractères. Choisissez un mot de passe plus long et sécurisé.

### Erreur : "key.properties not found"
- Vérifiez que vous avez bien créé `android/key.properties` depuis le fichier `.example`
- Vérifiez que le chemin du `storeFile` est correct

### Erreur : "Keystore file not found"
- Vérifiez que le fichier `.jks` existe au chemin spécifié dans `key.properties`
- Le chemin est relatif à `android/app/`

### Erreur : "Wrong password"
- Vérifiez les mots de passe dans `key.properties`
- Assurez-vous qu'il n'y a pas d'espaces avant/après les valeurs

### Erreur lors de la mise à jour sur Play Store
- Assurez-vous d'utiliser la même clé de signature que pour la version précédente
- Le `versionCode` doit être supérieur à la version précédente

## 📚 Ressources

- [Documentation Flutter - Signing the app](https://docs.flutter.dev/deployment/android#signing-the-app)
- [Documentation Android - Sign your app](https://developer.android.com/studio/publish/app-signing)

