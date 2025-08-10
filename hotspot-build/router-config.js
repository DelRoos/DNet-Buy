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