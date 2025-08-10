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