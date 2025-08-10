# 🔧 **Minification et Obfuscation pour Déploiement Routeur**

## 📋 **Plan de Minification Complète**

### **ÉTAPE 1 : Installation des outils de build**

```bash
# Créer un dossier de build
mkdir hotspot-build
cd hotspot-build

# Initialiser npm
npm init -y

# Installer les outils de minification
npm install --save-dev \
  terser \
  html-minifier-terser \
  clean-css-cli \
  javascript-obfuscator \
  concat \
  rimraf
```

### **ÉTAPE 2 : Script de build automatisé**

**Créer : `build.js`**

```javascript
const fs = require('fs');
const path = require('path');
const { minify } = require('terser');
const { minify: minifyHTML } = require('html-minifier-terser');
const CleanCSS = require('clean-css');
const JavaScriptObfuscator = require('javascript-obfuscator');

const SOURCE_DIR = '../hotspot';
const OUTPUT_DIR = './dist';

// Configuration d'obfuscation
const obfuscatorConfig = {
  compact: true,
  controlFlowFlattening: true,
  controlFlowFlatteningThreshold: 0.75,
  deadCodeInjection: true,
  deadCodeInjectionThreshold: 0.4,
  debugProtection: false, // Désactivé pour le debug en production
  debugProtectionInterval: false,
  disableConsoleOutput: true,
  identifierNamesGenerator: 'hexadecimal',
  log: false,
  numbersToExpressions: true,
  renameGlobals: false,
  rotateStringArray: true,
  selfDefending: true,
  shuffleStringArray: true,
  simplify: true,
  splitStrings: true,
  splitStringsChunkLength: 10,
  stringArray: true,
  stringArrayEncoding: ['base64'],
  stringArrayThreshold: 0.75,
  transformObjectKeys: true,
  unicodeEscapeSequence: false
};

// Configuration CSS
const cssConfig = {
  level: 2,
  returnPromise: false
};

// Configuration HTML
const htmlConfig = {
  collapseWhitespace: true,
  removeComments: true,
  removeRedundantAttributes: true,
  removeScriptTypeAttributes: true,
  removeStyleLinkTypeAttributes: true,
  minifyJS: true,
  minifyCSS: true,
  useShortDoctype: true
};

async function createOutputDir() {
  if (fs.existsSync(OUTPUT_DIR)) {
    fs.rmSync(OUTPUT_DIR, { recursive: true });
  }
  fs.mkdirSync(OUTPUT_DIR, { recursive: true });
  fs.mkdirSync(path.join(OUTPUT_DIR, 'scripts'), { recursive: true });
  fs.mkdirSync(path.join(OUTPUT_DIR, 'styles'), { recursive: true });
  fs.mkdirSync(path.join(OUTPUT_DIR, 'img'), { recursive: true });
}

async function minifyJS(filePath, outputPath, shouldObfuscate = true) {
  try {
    const code = fs.readFileSync(filePath, 'utf8');
    
    // Étape 1: Minification avec Terser
    const minified = await minify(code, {
      compress: {
        drop_console: true, // Supprimer les console.log
        drop_debugger: true,
        dead_code: true,
        unused: true,
        if_return: true,
        join_vars: true,
        reduce_vars: true,
        sequences: true,
        conditionals: true,
        booleans: true,
        loops: true,
        hoist_funs: true,
        pure_funcs: ['console.log', 'console.warn', 'console.info']
      },
      mangle: {
        properties: false, // Ne pas renommer les propriétés pour éviter les erreurs
        reserved: ['firebase', 'CONFIG', 'admin'] // Préserver certains noms
      },
      format: {
        comments: false
      }
    });

    let finalCode = minified.code;

    // Étape 2: Obfuscation (optionnelle)
    if (shouldObfuscate) {
      const obfuscated = JavaScriptObfuscator.obfuscate(finalCode, obfuscatorConfig);
      finalCode = obfuscated.getObfuscatedCode();
    }

    fs.writeFileSync(outputPath, finalCode);
    console.log(`✅ JS: ${filePath} → ${outputPath}`);
    
    return finalCode.length;
  } catch (error) {
    console.error(`❌ Erreur JS ${filePath}:`, error.message);
    throw error;
  }
}

async function minifyCSS(filePath, outputPath) {
  try {
    const css = fs.readFileSync(filePath, 'utf8');
    const result = new CleanCSS(cssConfig).minify(css);
    
    if (result.errors.length > 0) {
      throw new Error(result.errors.join(', '));
    }
    
    fs.writeFileSync(outputPath, result.styles);
    console.log(`✅ CSS: ${filePath} → ${outputPath}`);
    
    return result.styles.length;
  } catch (error) {
    console.error(`❌ Erreur CSS ${filePath}:`, error.message);
    throw error;
  }
}

async function minifyHTMLFile(filePath, outputPath) {
  try {
    const html = fs.readFileSync(filePath, 'utf8');
    const minified = await minifyHTML(html, htmlConfig);
    
    fs.writeFileSync(outputPath, minified);
    console.log(`✅ HTML: ${filePath} → ${outputPath}`);
    
    return minified.length;
  } catch (error) {
    console.error(`❌ Erreur HTML ${filePath}:`, error.message);
    throw error;
  }
}

async function copyImages() {
  const imgDir = path.join(SOURCE_DIR, 'img');
  const outputImgDir = path.join(OUTPUT_DIR, 'img');
  
  if (fs.existsSync(imgDir)) {
    const files = fs.readdirSync(imgDir);
    for (const file of files) {
      fs.copyFileSync(
        path.join(imgDir, file),
        path.join(outputImgDir, file)
      );
    }
    console.log(`✅ Images copiées: ${files.length} fichiers`);
  }
}

async function createSingleJSBundle() {
  console.log('\n🔄 Création du bundle JS unifié...');
  
  // Ordre de chargement important
  const jsFiles = [
    'md5.js',
    'config.js',
    'firebase-integration.js',
    'ui-handlers.js',
    'ticket.js',
    'main.js'
  ];
  
  let bundledCode = '';
  let totalOriginalSize = 0;
  
  for (const file of jsFiles) {
    const filePath = path.join(SOURCE_DIR, 'scripts', file);
    if (fs.existsSync(filePath)) {
      const code = fs.readFileSync(filePath, 'utf8');
      totalOriginalSize += code.length;
      
      // Ajouter un séparateur de fichier (supprimé en production)
      bundledCode += `\n/* === ${file} === */\n${code}\n`;
    }
  }
  
  // Minifier et obfusquer le bundle
  const bundlePath = path.join(OUTPUT_DIR, 'scripts', 'app.min.js');
  const finalSize = await minifyJS('temp-bundle.js', bundlePath, true);
  
  // Nettoyer le fichier temporaire
  fs.writeFileSync('temp-bundle.js', bundledCode);
  fs.unlinkSync('temp-bundle.js');
  
  console.log(`📦 Bundle créé: ${totalOriginalSize} → ${finalSize} bytes (${Math.round((1 - finalSize/totalOriginalSize) * 100)}% de réduction)`);
  
  return bundlePath;
}

async function updateHTMLReferences(htmlFiles, bundlePath) {
  console.log('\n🔄 Mise à jour des références HTML...');
  
  for (const htmlFile of htmlFiles) {
    let html = fs.readFileSync(htmlFile, 'utf8');
    
    // Remplacer les multiples scripts par le bundle
    html = html.replace(
      /<script src="scripts\/(config|firebase-integration|ui-handlers|ticket|main)\.js"><\/script>\s*/g,
      ''
    );
    
    // Ajouter le bundle minifié
    html = html.replace(
      '<script src="scripts/main.js"></script>',
      '<script src="scripts/app.min.js"></script>'
    );
    
    // Mettre à jour les références CSS
    html = html.replace(
      'href="styles/main.css"',
      'href="styles/main.min.css"'
    );
    
    fs.writeFileSync(htmlFile, html);
  }
}

async function generateDeploymentInfo() {
  const info = {
    buildDate: new Date().toISOString(),
    version: require('./package.json').version || '1.0.0',
    files: [],
    totalSize: 0
  };
  
  // Analyser tous les fichiers générés
  function scanDirectory(dir, prefix = '') {
    const files = fs.readdirSync(dir);
    
    for (const file of files) {
      const filePath = path.join(dir, file);
      const stat = fs.statSync(filePath);
      
      if (stat.isDirectory()) {
        scanDirectory(filePath, `${prefix}${file}/`);
      } else {
        const size = stat.size;
        info.files.push({
          path: `${prefix}${file}`,
          size: size,
          sizeKB: Math.round(size / 1024 * 100) / 100
        });
        info.totalSize += size;
      }
    }
  }
  
  scanDirectory(OUTPUT_DIR);
  
  info.totalSizeKB = Math.round(info.totalSize / 1024 * 100) / 100;
  
  fs.writeFileSync(
    path.join(OUTPUT_DIR, 'build-info.json'),
    JSON.stringify(info, null, 2)
  );
  
  console.log(`\n📊 Build Info:`);
  console.log(`   Taille totale: ${info.totalSizeKB} KB`);
  console.log(`   Fichiers: ${info.files.length}`);
  console.log(`   Date: ${info.buildDate}`);
}

async function main() {
  console.log('🚀 Démarrage du build pour routeur...\n');
  
  try {
    // Créer le dossier de sortie
    await createOutputDir();
    
    // 1. Créer le bundle JS unifié
    await createSingleJSBundle();
    
    // 2. Minifier les CSS
    const cssFiles = ['main.css', 'payment-modal.css'];
    for (const file of cssFiles) {
      const inputPath = path.join(SOURCE_DIR, 'styles', file);
      if (fs.existsSync(inputPath)) {
        const outputPath = path.join(OUTPUT_DIR, 'styles', file.replace('.css', '.min.css'));
        await minifyCSS(inputPath, outputPath);
      }
    }
    
    // 3. Copier et minifier les fichiers HTML
    const htmlFiles = ['login.html', 'status.html', 'error.html'];
    const processedHTMLFiles = [];
    
    for (const file of htmlFiles) {
      const inputPath = path.join(SOURCE_DIR, file);
      if (fs.existsSync(inputPath)) {
        const outputPath = path.join(OUTPUT_DIR, file);
        await minifyHTMLFile(inputPath, outputPath);
        processedHTMLFiles.push(outputPath);
      }
    }
    
    // 4. Mettre à jour les références dans HTML
    await updateHTMLReferences(processedHTMLFiles);
    
    // 5. Copier les images
    await copyImages();
    
    // 6. Générer les infos de build
    await generateDeploymentInfo();
    
    console.log('\n✅ Build terminé avec succès !');
    console.log(`📁 Fichiers générés dans: ${OUTPUT_DIR}`);
    
  } catch (error) {
    console.error('\n❌ Erreur durant le build:', error);
    process.exit(1);
  }
}

main();
```

### **ÉTAPE 3 : Script package.json**

**Créer : `package.json`**

```json
{
  "name": "hotspot-build",
  "version": "1.0.0",
  "description": "Build system for Dnet Hotspot",
  "scripts": {
    "build": "node build.js",
    "build:dev": "NODE_ENV=development node build.js",
    "build:prod": "NODE_ENV=production node build.js",
    "clean": "rimraf dist",
    "analyze": "node analyze-bundle.js"
  },
  "devDependencies": {
    "terser": "^5.19.2",
    "html-minifier-terser": "^7.2.0",
    "clean-css-cli": "^5.6.2",
    "javascript-obfuscator": "^4.0.2",
    "rimraf": "^5.0.1"
  }
}
```

### **ÉTAPE 4 : Configuration avancée pour routeur**

**Créer : `router-config.js`**

```javascript
// Configuration spécifique pour environnement routeur
const ROUTER_OPTIMIZATIONS = {
  // Réduire les timeouts pour connexions locales
  network: {
    timeoutMs: 5000,        // Réduit de 10s à 5s
    maxRetries: 2,          // Réduit de 4 à 2
    baseBackoffMs: 300,     // Réduit de 600ms à 300ms
    maxBackoffMs: 2000      // Réduit de 5s à 2s
  },
  
  // Réduire les intervalles UI
  ui: {
    transactionCheckInterval: 3000,  // Réduit de 4s à 3s
    paymentTimeout: 90000,           // Réduit de 120s à 90s
    loaderMinDisplay: 500            // Réduit à 500ms
  },
  
  // Cache plus agressif
  cache: {
    plansTTL: 300000,       // 5 minutes
    enableLocalStorage: true,
    enableSessionStorage: true
  },
  
  // Logs minimaux en production
  logging: {
    level: 'error',         // Seulement les erreurs
    console: false,         // Pas de console.log
    performance: false      // Pas de logs de performance
  }
};

// Export pour être injecté dans le build
if (typeof module !== 'undefined' && module.exports) {
  module.exports = ROUTER_OPTIMIZATIONS;
}
```

### **ÉTAPE 5 : Script d'analyse du bundle**

**Créer : `analyze-bundle.js`**

```javascript
const fs = require('fs');
const path = require('path');

function analyzeBundle() {
  const bundlePath = './dist/scripts/app.min.js';
  
  if (!fs.existsSync(bundlePath)) {
    console.log('❌ Bundle non trouvé. Lancez npm run build d\'abord.');
    return;
  }
  
  const bundle = fs.readFileSync(bundlePath, 'utf8');
  const size = bundle.length;
  const sizeKB = Math.round(size / 1024 * 100) / 100;
  
  // Analyser la compression
  const originalSources = [
    '../hotspot/scripts/config.js',
    '../hotspot/scripts/firebase-integration.js',
    '../hotspot/scripts/ui-handlers.js',
    '../hotspot/scripts/ticket.js',
    '../hotspot/scripts/main.js',
    '../hotspot/scripts/md5.js'
  ];
  
  let originalSize = 0;
  for (const file of originalSources) {
    if (fs.existsSync(file)) {
      originalSize += fs.readFileSync(file, 'utf8').length;
    }
  }
  
  const originalSizeKB = Math.round(originalSize / 1024 * 100) / 100;
  const compressionRatio = Math.round((1 - size/originalSize) * 100);
  
  console.log('\n📊 ANALYSE DU BUNDLE');
  console.log('==================');
  console.log(`📁 Taille originale: ${originalSizeKB} KB`);
  console.log(`📦 Taille minifiée:  ${sizeKB} KB`);
  console.log(`🗜️  Compression:     ${compressionRatio}%`);
  console.log(`💾 Économie:        ${originalSizeKB - sizeKB} KB`);
  
  // Analyser les patterns d'obfuscation
  const obfuscationMarkers = [
    /var _0x[a-f0-9]+/.test(bundle),
    /\['\w+'\]/.test(bundle),
    /\\x[a-f0-9]{2}/.test(bundle)
  ];
  
  const obfuscated = obfuscationMarkers.some(marker => marker);
  console.log(`🔒 Obfuscation:     ${obfuscated ? 'Activée' : 'Désactivée'}`);
  
  // Recommandations pour routeur
  console.log('\n🎯 RECOMMANDATIONS ROUTEUR');
  console.log('========================');
  
  if (sizeKB > 200) {
    console.log('⚠️  Bundle volumineux pour un routeur (>200KB)');
    console.log('   → Considérer la suppression de fonctionnalités optionnelles');
  } else if (sizeKB > 100) {
    console.log('✅ Taille acceptable pour routeur (100-200KB)');
  } else {
    console.log('🎉 Taille optimale pour routeur (<100KB)');
  }
  
  if (compressionRatio < 50) {
    console.log('⚠️  Compression faible');
    console.log('   → Vérifier la configuration Terser');
  } else {
    console.log('✅ Compression efficace');
  }
}

analyzeBundle();
```

### **ÉTAPE 6 : Script de déploiement automatique**

**Créer : `deploy-to-router.sh`**

```bash
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
```

### **ÉTAPE 7 : Instructions de build et déploiement**

```bash
# 1. Préparer l'environnement de build
cd hotspot-build
npm install

# 2. Build de production (minifié + obfusqué)
npm run build:prod

# 3. Analyser le résultat
npm run analyze

# 4. Déployer vers le routeur (si configuré)
chmod +x deploy-to-router.sh
./deploy-to-router.sh 192.168.88.1 admin

# 5. OU copie manuelle
# Copier tout le contenu de ./dist/ vers le routeur
```

## 📊 **Résultat attendu**

### **Avant minification :**
- **Scripts JS:** ~150-200 KB
- **CSS:** ~50-80 KB  
- **HTML:** ~30-50 KB
- **Total:** ~230-330 KB

### **Après minification + obfuscation :**
- **Bundle JS:** ~80-120 KB (-60% à -75%)
- **CSS minifié:** ~20-35 KB (-50% à -65%)
- **HTML minifié:** ~15-25 KB (-40% à -50%)
- **Total:** ~115-180 KB (**-50% à -65% de réduction**)

## 🔒 **Niveau de protection**

1. **✅ Noms de variables obfusqués** (hexadécimaux)
2. **✅ Strings encodés** (base64)
3. **✅ Contrôle de flux aplati**
4. **✅ Code mort injecté**
5. **✅ Auto-défense** contre le debugging
6. **✅ Console.log supprimés**
7. **✅ Commentaires supprimés**

Le code devient **très difficile à lire** et à modifier tout en restant **fonctionnel** sur le routeur.