// Configuration de l'application
const CONFIG = {
  // Firebase Configuration - ✅ REMPLACEZ PAR VOS VRAIES VALEURS
  firebase: {
    apiKey: "AIzaSyDT9KnNJgE5ShcT8KKsOj5J9cOmW6Rx3kY", // Remplacez
    authDomain: "dnet-29b02.firebaseapp.com",
    projectId: "dnet-29b02",
    storageBucket: "dnet-29b02.appspot.com",
    messagingSenderId: "123456789", // Remplacez
    appId: "1:123456789:web:abcdef123456" // Remplacez
  },

  // Configuration de la zone - ✅ REMPLACEZ PAR VOTRE VRAIE ZONE ID
  zone: {
    id: 'S78uMjeYRf11EvMIW2x3', // ✅ Votre zone ID est déjà correcte
    publicKey: null // Optionnel pour la sécurité
  },

  // URLs des services
  api: {
    cloudFunctionsUrl: 'https://us-central1-dnet-29b02.cloudfunctions.net',
    endpoints: {
      getPlans: '/getPublicTicketTypes',
      initiatePayment: 'initiatePublicPayment',
      checkTransaction: 'checkTransactionStatus'
    }
  },

  // Configuration des forfaits de fallback (seront utilisés si Firebase échoue)
  fallbackPlans: [
    {
      id: '1jour',
      name: '1 Jour Illimité',
      price: 500,
      formattedPrice: '500 F',
      validityText: '1 jour',
      isAvailable: true
    },
    {
      id: '3jours',
      name: '3 Jours Illimité',
      price: 1000,
      formattedPrice: '1,000 F',
      originalPrice: 1500,
      validityText: '3 jours',
      isAvailable: true,
      hasPromotion: true
    },
    {
      id: '1semaine',
      name: '1 Semaine Illimité',
      price: 2000,
      formattedPrice: '2,000 F',
      originalPrice: 3500,
      validityText: '1 semaine',
      isAvailable: true,
      hasPromotion: true
    },
    {
      id: '1mois',
      name: '1 Mois Illimité',
      price: 5000,
      formattedPrice: '5,000 F',
      originalPrice: 10000,
      validityText: '1 mois',
      isAvailable: true,
      hasPromotion: true
    }
  ],

  // Configuration UI
  ui: {
    loaderTimeout: 10000, // 10 secondes max pour charger les forfaits
    transactionMonitorTimeout: 300000, // 5 minutes max pour une transaction
    transactionCheckInterval: 5000 // Vérifier toutes les 5 secondes
  }
};