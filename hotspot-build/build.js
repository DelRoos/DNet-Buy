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
    // Vérifier que le fichier source existe
    if (!fs.existsSync(filePath)) {
      throw new Error(`Fichier source non trouvé: ${filePath}`);
    }
    
    const code = fs.readFileSync(filePath, 'utf8');
    
    if (!code.trim()) {
      throw new Error(`Fichier source vide: ${filePath}`);
    }
    
    // Étape 1: Minification avec Terser
    const minified = await minify(code, {
      compress: {
        drop_console: process.env.NODE_ENV === 'production', // Garder les logs en dev
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
        pure_funcs: process.env.NODE_ENV === 'production' ? 
          ['console.log', 'console.warn', 'console.info'] : []
      },
      mangle: {
        properties: false, // Ne pas renommer les propriétés pour éviter les erreurs
        reserved: [
          'firebase', 'CONFIG', 'admin', 'PaymentFlow', 'MyTickets', 
          'TicketStore', 'PhoneMemory', 'uiHandlers', 'firebaseIntegration',
          'HotspotApp', 'FirebaseIntegration', 'UIHandlers'
        ] // Préserver certains noms critiques
      },
      format: {
        comments: false
      }
    });

    if (minified.error) {
      throw new Error(`Erreur Terser: ${minified.error}`);
    }

    let finalCode = minified.code;

    // Étape 2: Obfuscation (optionnelle et seulement en production)
    if (shouldObfuscate && process.env.NODE_ENV === 'production') {
      try {
        const obfuscated = JavaScriptObfuscator.obfuscate(finalCode, {
          ...obfuscatorConfig,
          // Configuration plus conservatrice pour éviter les erreurs
          controlFlowFlattening: false, // Désactivé pour éviter les erreurs Firebase
          selfDefending: false, // Désactivé pour compatibilité routeur
          debugProtection: false
        });
        finalCode = obfuscated.getObfuscatedCode();
      } catch (obfuscationError) {
        console.warn(`⚠️  Obfuscation échouée pour ${filePath}, utilisation de la version minifiée seulement`);
        console.warn(`   Erreur: ${obfuscationError.message}`);
        // Continuer avec le code minifié seulement
      }
    }

    // Créer le dossier de sortie si nécessaire
    const outputDir = path.dirname(outputPath);
    if (!fs.existsSync(outputDir)) {
      fs.mkdirSync(outputDir, { recursive: true });
    }

    fs.writeFileSync(outputPath, finalCode);
    console.log(`✅ JS: ${path.basename(filePath)} → ${path.basename(outputPath)} (${finalCode.length} bytes)`);
    
    return finalCode.length;
  } catch (error) {
    console.error(`❌ Erreur JS ${filePath}:`, error.message);
    throw error;
  }
}

function verifySourceFiles() {
  console.log('🔍 Vérification des fichiers source...');
  
  const requiredFiles = [
    'scripts/config.js',
    'scripts/firebase-integration.js', 
    'scripts/ui-handlers.js',
    'scripts/ticket.js',
    'scripts/main.js',
    'scripts/md5.js',
    'styles/main.css',
    'login.html'
  ];
  
  const missingFiles = [];
  const presentFiles = [];
  
  for (const file of requiredFiles) {
    const filePath = path.join(SOURCE_DIR, file);
    if (fs.existsSync(filePath)) {
      presentFiles.push(file);
    } else {
      missingFiles.push(file);
    }
  }
  
  console.log(`✅ Fichiers trouvés: ${presentFiles.length}`);
  presentFiles.forEach(file => console.log(`   ✓ ${file}`));
  
  if (missingFiles.length > 0) {
    console.log(`❌ Fichiers manquants: ${missingFiles.length}`);
    missingFiles.forEach(file => console.log(`   ✗ ${file}`));
    
    if (missingFiles.some(f => f.includes('.js'))) {
      throw new Error('Fichiers JS critiques manquants');
    }
  }
  
  return { presentFiles, missingFiles };
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
    } else {
      console.warn(`⚠️  Fichier manquant: ${filePath}`);
    }
  }
  
  // ✅ CORRECTION : Créer le fichier temporaire AVANT de le traiter
  const tempBundlePath = 'temp-bundle.js';
  fs.writeFileSync(tempBundlePath, bundledCode);
  
  try {
    // Minifier et obfusquer le bundle
    const bundlePath = path.join(OUTPUT_DIR, 'scripts', 'app.min.js');
    const finalSize = await minifyJS(tempBundlePath, bundlePath, true);
    
    console.log(`📦 Bundle créé: ${totalOriginalSize} → ${finalSize} bytes (${Math.round((1 - finalSize/totalOriginalSize) * 100)}% de réduction)`);
    
    return bundlePath;
  } finally {
    // ✅ Nettoyer le fichier temporaire dans le bloc finally
    if (fs.existsSync(tempBundlePath)) {
      fs.unlinkSync(tempBundlePath);
    }
  }
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
    // Vérifier les fichiers source
    verifySourceFiles();
    
    // Créer le dossier de sortie
    await createOutputDir();
    
    // 1. Créer le bundle JS unifié
    await createSingleJSBundle();
    
    // 2. Minifier les CSS
    const cssFiles = ['main.css'];
    // Vérifier si payment-modal.css existe
    if (fs.existsSync(path.join(SOURCE_DIR, 'styles', 'payment-modal.css'))) {
      cssFiles.push('payment-modal.css');
    }
    
    for (const file of cssFiles) {
      const inputPath = path.join(SOURCE_DIR, 'styles', file);
      if (fs.existsSync(inputPath)) {
        const outputPath = path.join(OUTPUT_DIR, 'styles', file.replace('.css', '.min.css'));
        await minifyCSS(inputPath, outputPath);
      }
    }
    
    // 3. Copier et minifier les fichiers HTML
    const htmlFiles = ['login.html'];
    // Vérifier si d'autres fichiers HTML existent
    const optionalHtmlFiles = ['status.html', 'error.html'];
    for (const file of optionalHtmlFiles) {
      if (fs.existsSync(path.join(SOURCE_DIR, file))) {
        htmlFiles.push(file);
      }
    }
    
    const processedHTMLFiles = [];
    
    for (const file of htmlFiles) {
      const inputPath = path.join(SOURCE_DIR, file);
      const outputPath = path.join(OUTPUT_DIR, file);
      await minifyHTMLFile(inputPath, outputPath);
      processedHTMLFiles.push(outputPath);
    }
    
    // 4. Mettre à jour les références dans HTML
    await updateHTMLReferences(processedHTMLFiles);
    
    // 5. Copier les images
    await copyImages();
    
    // 6. Générer les infos de build
    await generateDeploymentInfo();
    
    console.log('\n✅ Build terminé avec succès !');
    console.log(`📁 Fichiers générés dans: ${OUTPUT_DIR}`);
    console.log(`📊 Taille totale du projet minifié: ${(await getTotalSize()).toFixed(2)} KB`);
    
  } catch (error) {
    console.error('\n❌ Erreur durant le build:', error.message);
    console.error('Stack trace:', error.stack);
    process.exit(1);
  }
}

// Fonction utilitaire pour calculer la taille totale
async function getTotalSize() {
  let totalSize = 0;
  
  function scanDir(dir) {
    const files = fs.readdirSync(dir);
    for (const file of files) {
      const filePath = path.join(dir, file);
      const stat = fs.statSync(filePath);
      if (stat.isDirectory()) {
        scanDir(filePath);
      } else {
        totalSize += stat.size;
      }
    }
  }
  
  if (fs.existsSync(OUTPUT_DIR)) {
    scanDir(OUTPUT_DIR);
  }
  
  return totalSize / 1024; // Retourner en KB
}

main();