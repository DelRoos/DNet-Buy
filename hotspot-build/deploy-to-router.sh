#!/bin/bash

# Script de déploiement automatique vers routeur MikroTik
# Usage: ./deploy-to-router.sh [IP_ROUTER] [USERNAME]

ROUTER_IP=${1:-"192.168.88.1"}
USERNAME=${2:-"admin"}
REMOTE_PATH="/flash/hotspot"
LOCAL_PATH="./dist"

echo "🚀 Déploiement vers routeur MikroTik"
echo "=================================="
echo "IP Routeur: $ROUTER_IP"
echo "Utilisateur: $USERNAME"
echo "Chemin distant: $REMOTE_PATH"
echo ""

# Vérifier que le build existe
if [ ! -d "$LOCAL_PATH" ]; then
    echo "❌ Dossier dist non trouvé. Lancez npm run build d'abord."
    exit 1
fi

# Fonction de upload via SCP
upload_files() {
    echo "📤 Upload des fichiers..."
    
    # Créer le dossier distant
    ssh ${USERNAME}@${ROUTER_IP} "mkdir -p $REMOTE_PATH"
    
    # Upload récursif
    scp -r ${LOCAL_PATH}/* ${USERNAME}@${ROUTER_IP}:${REMOTE_PATH}/
    
    if [ $? -eq 0 ]; then
        echo "✅ Upload terminé avec succès"
    else
        echo "❌ Erreur lors de l'upload"
        exit 1
    fi
}

# Fonction de vérification
verify_deployment() {
    echo "🔍 Vérification du déploiement..."
    
    # Vérifier les fichiers principaux
    ssh ${USERNAME}@${ROUTER_IP} "ls -la $REMOTE_PATH/login.html $REMOTE_PATH/scripts/app.min.js $REMOTE_PATH/styles/main.min.css" 2>/dev/null
    
    if [ $? -eq 0 ]; then
        echo "✅ Fichiers principaux présents"
    else
        echo "⚠️  Certains fichiers manquent"
    fi
    
    # Afficher la taille totale
    TOTAL_SIZE=$(ssh ${USERNAME}@${ROUTER_IP} "du -sh $REMOTE_PATH" 2>/dev/null | cut -f1)
    echo "📊 Taille totale déployée: $TOTAL_SIZE"
}

# Fonction de redémarrage des services (optionnel)
restart_services() {
    echo "🔄 Redémarrage des services hotspot..."
    ssh ${USERNAME}@${ROUTER_IP} "/ip hotspot print; /ip hotspot enable [find]" 2>/dev/null
    echo "✅ Services redémarrés"
}

# Exécution
echo "1️⃣  Building project..."
npm run build

echo ""
echo "2️⃣  Uploading files..."
upload_files

echo ""
echo "3️⃣  Verifying deployment..."
verify_deployment

echo ""
echo "4️⃣  Restarting services..."
restart_services

echo ""
echo "🎉 Déploiement terminé !"
echo "🌐 Accédez à: http://$ROUTER_IP/login.html"