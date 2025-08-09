# Rapport de Sécurité - Hotspot WiFi Dnet

## Résumé Exécutif

Ce rapport présente l'analyse sécuritaire du portail captif WiFi Dnet. L'application implémente un système de vente de forfaits WiFi avec intégration de paiement mobile. Plusieurs vulnérabilités critiques et moyennes ont été identifiées nécessitant une attention immédiate.

**Niveau de risque global : ⚠️ ÉLEVÉ**

---

## 📋 Contexte Technique

- **Type d'application** : Portail captif WiFi avec système de paiement
- **Architecture** : Client-side JavaScript + Firebase Cloud Functions
- **Authentification** : MD5-CHAP (MikroTik) + système de tickets
- **Technologies** : JavaScript vanilla, Firebase, Mobile Money API

---

## 🔴 Vulnérabilités Critiques

### 1. Exposition des Clés API Firebase dans le Code Client
**Fichier** : `scripts/config.js:5`
```javascript
apiKey: "AIzaSyDT9KnNJgE5ShcT8KKsOj5J9cOmW6Rx3kY"
```
**Impact** : Les clés Firebase sont directement exposées dans le code source côté client, permettant à un attaquant de :
- Effectuer des appels non autorisés aux services Firebase
- Potentiellement accéder aux données de l'application
- Compromettre l'intégrité du système de paiement

**Recommandation** : Déplacer les appels sensibles côté serveur et implémenter une authentification par token côté client.

### 2. Validation Côté Client Uniquement pour les Paiements
**Fichier** : `scripts/ticket.js:79-81`
```javascript
function isValidCMLocal(n) {
  return /^[6]\d{8}$/.test(n);
}
```
**Impact** : La validation des numéros de téléphone n'existe que côté client, permettant de contourner les vérifications en modifiant le code JavaScript.

**Recommandation** : Implémenter une validation robuste côté serveur avant tout traitement de paiement.

### 3. Stockage Non Sécurisé des Identifiants
**Fichier** : `scripts/ticket.js:2-13`
```javascript
const TicketStore = {
  KEY: 'dnet_tickets',
  all() {
    try { return JSON.parse(localStorage.getItem(this.KEY) || '[]'); } catch { return []; }
  }
```
**Impact** : Les identifiants WiFi sont stockés en clair dans le localStorage, accessibles à tout script malveillant ou extension de navigateur.

**Recommandation** : Chiffrer les données sensibles avant stockage local ou éviter le stockage local pour les informations sensibles.

---

## 🟠 Vulnérabilités Moyennes

### 4. Authentification MD5-CHAP Obsolète
**Fichier** : `login.html:24`
```javascript
document.sendin.password.value = hexMD5('$(chap-id)' + document.login.password.value + '$(chap-challenge)');
```
**Impact** : MD5 est cryptographiquement cassé et vulnérable aux attaques par collision et rainbow tables.

**Recommandation** : Migrer vers un algorithme de hachage sécurisé (SHA-256 minimum) ou implémenter une authentification plus moderne.

### 5. Gestion d'Erreur Révélatrice
**Fichier** : `scripts/firebase-integration.js:96-98`
```javascript
try {
  const data = await resp.json();
  msg = data.error || msg;
} catch {}
```
**Impact** : Les messages d'erreur peuvent révéler des informations sur l'architecture interne de l'application.

**Recommandation** : Implémenter un système de messages d'erreur génériques côté client.

### 6. Absence de Protection CSRF
**Impact** : Aucune protection contre les attaques Cross-Site Request Forgery n'est implémentée.

**Recommandation** : Ajouter des tokens CSRF pour toutes les opérations sensibles.

---

## 🟡 Vulnérabilités Mineures

### 7. Génération d'ID Prévisible
**Fichier** : `scripts/firebase-integration.js:157-159`
```javascript
genExternalId() {
  return `ext_${Date.now()}_${Math.random().toString(36).slice(2, 10)}`;
}
```
**Impact** : L'utilisation de `Date.now()` et `Math.random()` peut rendre les IDs prédictibles.

**Recommandation** : Utiliser `crypto.getRandomValues()` pour générer des identifiants cryptographiquement sécurisés.

### 8. Timeout de Sécurité Insuffisant
**Fichier** : `scripts/firebase-integration.js:220`
```javascript
const HARD_TIMEOUT = CONFIG.ui.transactionMonitorTimeout || 90000; // 90s par défaut
```
**Impact** : Un timeout de 90 secondes peut permettre des attaques de déni de service par maintien de sessions.

**Recommandation** : Réduire le timeout à 30-45 secondes maximum.

---

## ✅ Bonnes Pratiques Identifiées

1. **Retry avec Backoff** : Implémentation correcte du retry exponentiel avec jitter
2. **Gestion des Erreurs Réseau** : Gestion appropriée des timeouts et erreurs de connectivité
3. **Interface Utilisateur Réactive** : Feedback visuel approprié pendant les opérations
4. **Validation Client** : Validation basique des entrées utilisateur (bien que insuffisante)

---

## 🔧 Recommandations Prioritaires

### Immédiat (0-7 jours)
1. **Sécuriser les clés API** : Déplacer la logique sensible côté serveur
2. **Chiffrer les données locales** : Implémenter un chiffrement AES pour le localStorage
3. **Validation serveur** : Ajouter une validation robuste côté backend

### Court terme (1-4 semaines)
1. **Remplacer MD5** : Migrer vers SHA-256 ou authentification moderne
2. **Protection CSRF** : Implémenter des tokens anti-CSRF
3. **Audit de sécurité** : Réaliser un pentest complet

### Long terme (1-3 mois)
1. **Architecture sécurisée** : Refactoriser avec une approche API-first
2. **Monitoring sécurité** : Implémenter la détection d'anomalies
3. **Formation équipe** : Sensibilisation sécurité développement

---

## 📊 Matrice des Risques

| Vulnérabilité | Impact | Probabilité | Risque Global |
|---------------|---------|-------------|---------------|
| Exposition clés API | Élevé | Élevé | 🔴 Critique |
| Validation côté client | Élevé | Moyen | 🔴 Critique |
| Stockage non sécurisé | Moyen | Élevé | 🟠 Moyen |
| MD5-CHAP obsolète | Moyen | Moyen | 🟠 Moyen |
| Absence CSRF | Faible | Moyen | 🟡 Faible |

---

## 💡 Conclusion

Le portail captif présente des vulnérabilités sérieuses principalement liées à la sécurité côté client et à l'exposition d'informations sensibles. Une intervention immédiate est recommandée pour corriger les vulnérabilités critiques avant toute utilisation en production.

**Prochaines étapes recommandées :**
1. Audit de sécurité complémentaire côté serveur
2. Implémentation des correctifs critiques
3. Tests de pénétration
4. Mise en place d'un cycle de révision sécurité

---

*Rapport généré le : 2025-08-09*  
*Analyste : Système d'analyse automatisé Claude Code*