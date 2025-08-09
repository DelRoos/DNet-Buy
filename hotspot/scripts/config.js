/**
 * Configuration centrale de l'application de portail captif Dnet
 * 
 * Ce fichier centralise tous les paramètres de configuration de l'application:
 * - Paramètres de connexion Firebase
 * - Configuration de la zone hotspot
 * - URLs des services API
 * - Forfaits de fallback en cas d'indisponibilité du service
 * - Paramètres d'interface utilisateur
 * 
 * IMPORTANT: Remplacez les valeurs de développement par vos vraies valeurs de production
 * 
 * @author Dnet Team
 * @version 1.0
 */
const CONFIG = {
  /**
   * Configuration Firebase pour l'authentification et les Cloud Functions
   * 
   * Ces paramètres connectent l'application à votre projet Firebase.
   * IMPORTANT: Remplacez ces valeurs par celles de votre projet Firebase.
   */
  firebase: {
    apiKey: "AIzaSyDT9KnNJgE5ShcT8KKsOj5J9cOmW6Rx3kY",
    authDomain: "dnet-29b02.firebaseapp.com",
    projectId: "dnet-29b02",
    storageBucket: "dnet-29b02.appspot.com",
    messagingSenderId: "123456789",
    appId: "1:123456789:web:abcdef123456"
  },

  /**
   * Configuration de la zone hotspot
   * 
   * Ces paramètres identifient votre zone hotspot spécifique.
   * L'ID de zone doit correspondre à celui configuré dans votre système.
   */
  zone: {
    id: 'S78uMjeYRf11EvMIW2x3',
    publicKey: null // Clé publique optionnelle pour la sécurité
  },

  /**
   * Configuration des services API
   * 
   * Ces URLs pointent vers vos Cloud Functions Firebase qui gèrent:
   * - La récupération des forfaits disponibles
   * - L'initiation des paiements
   * - La vérification du statut des transactions
   */
  api: {
    cloudFunctionsUrl: 'https://us-central1-dnet-29b02.cloudfunctions.net',
    endpoints: {
      getPlans: '/getPublicTicketTypes',
      initiatePayment: 'initiatePublicPayment',
      checkTransaction: 'checkTransactionStatus'
    }
  },

  /**
   * Forfaits de fallback utilisés en cas d'indisponibilité de Firebase
   * 
   * Ces forfaits sont affichés quand l'application ne peut pas se connecter
   * aux services Firebase. Ils permettent à l'application de continuer à
   * fonctionner même en mode dégradé.
   * 
   * Structure de chaque forfait:
   * - id: Identifiant unique du forfait
   * - name: Nom affiché à l'utilisateur
   * - price: Prix en francs CFA
   * - formattedPrice: Prix formaté pour l'affichage
   * - validityText: Durée de validité
   * - isAvailable: Disponibilité du forfait
   * - hasPromotion: Indique si le forfait est en promotion
   * - originalPrice: Prix original avant promotion
   */
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

  /**
   * Configuration de l'interface utilisateur
   * 
   * Ces paramètres contrôlent le comportement de l'interface:
   * - Timeouts pour les opérations asynchrones
   * - Intervalles de vérification des transactions
   * - Comportements d'affichage
   */
  ui: {
    loaderTimeout: 10000,              // 10 secondes max pour charger les forfaits
    transactionMonitorTimeout: 300000, // 5 minutes max pour une transaction
    transactionCheckInterval: 3000     // Vérifier toutes les 3 secondes
  }
};