#!/bin/bash

# Script pour générer la clé de signature SEZAM
# Utilise le JDK d'Android Studio

KEYTOOL_PATH="/Applications/Android Studio.app/Contents/jbr/Contents/Home/bin/keytool"
KEYSTORE_NAME="sezam-release-key.jks"
ALIAS="sezam"

# Vérifier si keytool existe
if [ ! -f "$KEYTOOL_PATH" ]; then
    echo "❌ Erreur: keytool introuvable dans Android Studio"
    echo "   Vérifiez que Android Studio est installé dans /Applications/"
    exit 1
fi

# Vérifier si le keystore existe déjà
if [ -f "$KEYSTORE_NAME" ]; then
    echo "⚠️  Le fichier $KEYSTORE_NAME existe déjà!"
    read -p "Voulez-vous le remplacer? (o/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Oo]$ ]]; then
        echo "Annulé."
        exit 0
    fi
    rm "$KEYSTORE_NAME"
fi

echo "🔑 Génération de la clé de signature SEZAM"
echo ""
echo "📝 Vous allez devoir fournir:"
echo "   - Un mot de passe keystore (minimum 6 caractères)"
echo "   - Un mot de passe pour la clé (peut être le même)"
echo "   - Vos informations personnelles/organisationnelles"
echo ""
echo "⚠️  IMPORTANT: Gardez ces informations en sécurité!"
echo ""

# Générer la clé
"$KEYTOOL_PATH" -genkey -v \
    -keystore "$KEYSTORE_NAME" \
    -keyalg RSA \
    -keysize 2048 \
    -validity 10000 \
    -alias "$ALIAS"

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Clé générée avec succès: $KEYSTORE_NAME"
    echo ""
    echo "📝 Prochaines étapes:"
    echo "   1. Copiez android/key.properties.example vers android/key.properties"
    echo "   2. Éditez android/key.properties avec vos mots de passe"
    echo "   3. Exécutez: flutter build apk --release"
else
    echo ""
    echo "❌ Erreur lors de la génération de la clé"
    exit 1
fi

