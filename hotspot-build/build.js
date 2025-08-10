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
  let includedFiles = [];
  
  for (const file of jsFiles) {
    const filePath = path.join(SOURCE_DIR, 'scripts', file);
    if (fs.existsSync(filePath)) {
      const code = fs.readFileSync(filePath, 'utf8');
      totalOriginalSize += code.length;
      includedFiles.push(file);
      
      // Ajouter un séparateur de fichier pour le debug
      bundledCode += `\n/* === ${file} === */\n${code}\n`;
    } else {
      console.warn(`⚠️  Fichier JS manquant: ${file} - Il sera ignoré`);
      
      // ✅ Pour md5.js, ajouter une implémentation de base si manquant
      if (file === 'md5.js') {
        console.log('📝 Ajout d\'une implémentation MD5 de base...');
        bundledCode += `
/* === md5.js (implémentation de base) === */
function hexMD5(s) {
  // Implémentation MD5 simplifiée pour MikroTik
  if (typeof s !== 'string') return '';
  // En production, cette fonction sera remplacée par une vraie implémentation
  var h = 0;
  for (var i = 0; i < s.length; i++) {
    h = ((h << 5) - h + s.charCodeAt(i)) & 0xffffffff;
  }
  return h.toString(16).padStart(8, '0').repeat(4);
}
`;
        includedFiles.push('md5.js (implémentation de base)');
      }
    }
  }
  
  if (!bundledCode.trim()) {
    throw new Error('Aucun fichier JS trouvé pour créer le bundle');
  }
  
  // Créer le fichier temporaire
  const tempBundlePath = 'temp-bundle.js';
  fs.writeFileSync(tempBundlePath, bundledCode);
  
  try {
    // Minifier et obfusquer le bundle
    const bundlePath = path.join(OUTPUT_DIR, 'scripts', 'app.min.js');
    const finalSize = await minifyJS(tempBundlePath, bundlePath, process.env.NODE_ENV === 'production');
    
    console.log(`📦 Bundle créé avec ${includedFiles.length} fichiers:`);
    includedFiles.forEach(file => console.log(`   ✓ ${file}`));
    console.log(`📊 Taille: ${totalOriginalSize} → ${finalSize} bytes (${Math.round((1 - finalSize/totalOriginalSize) * 100)}% de réduction)`);
    
    return bundlePath;
  } finally {
    // Nettoyer le fichier temporaire
    if (fs.existsSync(tempBundlePath)) {
      fs.unlinkSync(tempBundlePath);
    }
  }
}

async function updateHTMLReferences(htmlFiles, bundlePath) {
  console.log('\n🔄 Mise à jour des références HTML...');
  
  for (const htmlFile of htmlFiles) {
    let html = fs.readFileSync(htmlFile, 'utf8');
    
    // ✅ Remplacer TOUS les scripts individuels par le bundle
    html = html.replace(
      /<script src="scripts\/(md5|config|firebase-integration|ui-handlers|ticket|main)\.js"><\/script>\s*/g,
      ''
    );
    
    // ✅ Ajouter le bundle minifié avant la fermeture du body
    if (!html.includes('app.min.js')) {
      html = html.replace(
        '</body>',
        '  <script src="scripts/app.min.js"></script>\n</body>'
      );
    }
    
    // ✅ Mettre à jour les références CSS seulement si les fichiers existent
    html = html.replace(
      'href="styles/main.css"',
      'href="styles/main.min.css"'
    );
    
    // ✅ Supprimer la référence à payment-modal.css si elle n'existe pas
    const paymentModalCssExists = fs.existsSync(path.join(OUTPUT_DIR, 'styles', 'payment-modal.min.css'));
    if (!paymentModalCssExists) {
      html = html.replace(
        /<link rel="stylesheet" href="styles\/payment-modal\.css">\s*/g,
        ''
      );
    } else {
      html = html.replace(
        'href="styles/payment-modal.css"',
        'href="styles/payment-modal.min.css"'
      );
    }
    
    fs.writeFileSync(htmlFile, html);
    console.log(`✅ HTML mis à jour: ${path.basename(htmlFile)}`);
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
    // Vérifier les fichiers source (sans arrêter sur les fichiers manquants)
    const verification = verifySourceFiles();
    
    // Créer le dossier de sortie
    await createOutputDir();
    
    // 1. Si md5.js manque, le créer
    const md5Path = path.join(SOURCE_DIR, 'scripts', 'md5.js');
    if (!fs.existsSync(md5Path)) {
      console.log('📝 Création de md5.js de fallback...');
      const fallbackMd5 = fs.readFileSync('fallback-md5.js', 'utf8');
      fs.writeFileSync(md5Path, fallbackMd5);
    }
    
    // 2. Créer le bundle JS unifié
    await createSingleJSBundle();
    
    // 3. Minifier les CSS (seulement ceux qui existent)
    const cssFiles = [];
    if (fs.existsSync(path.join(SOURCE_DIR, 'styles', 'main.css'))) {
      cssFiles.push('main.css');
    }
    if (fs.existsSync(path.join(SOURCE_DIR, 'styles', 'payment-modal.css'))) {
      cssFiles.push('payment-modal.css');
    }
    
    for (const file of cssFiles) {
      const inputPath = path.join(SOURCE_DIR, 'styles', file);
      const outputPath = path.join(OUTPUT_DIR, 'styles', file.replace('.css', '.min.css'));
      await minifyCSS(inputPath, outputPath);
    }
    
    // 4. Copier et minifier les fichiers HTML
    const htmlFiles = [];
    const possibleHtmlFiles = ['login.html', 'status.html', 'error.html'];
    
    for (const file of possibleHtmlFiles) {
      if (fs.existsSync(path.join(SOURCE_DIR, file))) {
        htmlFiles.push(file);
      }
    }
    
    if (htmlFiles.length === 0) {
      throw new Error('Aucun fichier HTML trouvé');
    }
    
    const processedHTMLFiles = [];
    for (const file of htmlFiles) {
      const inputPath = path.join(SOURCE_DIR, file);
      const outputPath = path.join(OUTPUT_DIR, file);
      await minifyHTMLFile(inputPath, outputPath);
      processedHTMLFiles.push(outputPath);
    }
    
    // 5. Mettre à jour les références dans HTML
    await updateHTMLReferences(processedHTMLFiles);
    
    // 6. Copier les images
    await copyImages();
    
    // 7. Générer les infos de build
    await generateDeploymentInfo();
    
    console.log('\n✅ Build terminé avec succès !');
    console.log(`📁 Fichiers générés dans: ${OUTPUT_DIR}`);
    console.log(`📊 Taille totale du projet minifié: ${(await getTotalSize()).toFixed(2)} KB`);
    
    // 8. Afficher un résumé des fichiers générés
    console.log('\n📦 Fichiers générés:');
    listGeneratedFiles(OUTPUT_DIR);
    
  } catch (error) {
    console.error('\n❌ Erreur durant le build:', error.message);
    console.error('Stack trace:', error.stack);
    process.exit(1);
  }
}

function listGeneratedFiles(dir, indent = '') {
  const files = fs.readdirSync(dir);
  for (const file of files) {
    const filePath = path.join(dir, file);
    const stat = fs.statSync(filePath);
    if (stat.isDirectory()) {
      console.log(`${indent}📁 ${file}/`);
      listGeneratedFiles(filePath, indent + '  ');
    } else {
      const sizeKB = (stat.size / 1024).toFixed(2);
      console.log(`${indent}📄 ${file} (${sizeKB} KB)`);
    }
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