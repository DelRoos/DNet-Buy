# Configuration de la Navigation - Transactions de Zone

## 🛣️ Configuration de Route

Pour que la navigation `Get.toNamed('/zones/${controller.zoneId}/transactions')` fonctionne, voici la configuration nécessaire :

### 1. Dans votre fichier de routes existant

Ajoutez cette route dans votre configuration GetX :

```dart
// Dans app/routes/app_pages.dart ou votre fichier de routes
GetPage(
  name: '/zones/:zoneId/transactions',
  page: () => const ZoneTransactionsPage(),
  binding: BindingsBuilder(() {
    // Récupérer les paramètres de l'URL et des arguments
    final zoneId = Get.parameters['zoneId'] ?? '';
    final arguments = Get.arguments as Map<String, dynamic>? ?? {};
    final zoneName = arguments['zoneName'] ?? 'Zone';
    
    // Initialiser le contrôleur avec les paramètres
    Get.put(ZoneTransactionsController(
      zoneId: zoneId,
      zoneName: zoneName,
    ));
    
    // S'assurer que le service de transactions est disponible
    if (!Get.isRegistered<ZoneTransactionService>()) {
      Get.put<ZoneTransactionService>(ZoneTransactionService());
    }
  }),
),
```

### 2. Alternative avec Binding séparé

Si vous préférez utiliser un binding séparé :

```dart
// Dans app/bindings/zone_transaction_page_binding.dart
class ZoneTransactionPageBinding extends Bindings {
  @override
  void dependencies() {
    // Récupérer les paramètres
    final zoneId = Get.parameters['zoneId'] ?? '';
    final arguments = Get.arguments as Map<String, dynamic>? ?? {};
    final zoneName = arguments['zoneName'] ?? 'Zone';
    
    // Services
    Get.lazyPut<ZoneTransactionService>(() => ZoneTransactionService());
    
    // Contrôleur
    Get.put(ZoneTransactionsController(
      zoneId: zoneId,
      zoneName: zoneName,
    ));
  }
}

// Dans app/routes/app_pages.dart
GetPage(
  name: '/zones/:zoneId/transactions',
  page: () => const ZoneTransactionsPage(),
  binding: ZoneTransactionPageBinding(),
),
```

### 3. Imports nécessaires

Assurez-vous d'avoir ces imports dans votre fichier de routes :

```dart
import 'package:get/get.dart';
import 'package:dnet_buy/features/zones/views/zone_transactions_page.dart';
import 'package:dnet_buy/features/zones/controllers/zone_transactions_controller.dart';
import 'package:dnet_buy/features/zones/services/zone_transaction_service.dart';
```

## 🔧 Vérification du fonctionnement

### Test de la navigation
```dart
// Dans zone_details_page.dart - c'est déjà fait
void _goToTransactionsPage() {
  final zoneName = controller.zone.value?.name ?? 'Zone';
  
  Get.toNamed(
    '/zones/${controller.zoneId}/transactions',
    arguments: {
      'zoneId': controller.zoneId,
      'zoneName': zoneName,
    },
  );
}
```

### Debug si la navigation ne fonctionne pas
```dart
// Ajoutez ces logs pour débugger
void _goToTransactionsPage() {
  final zoneName = controller.zone.value?.name ?? 'Zone';
  final routeName = '/zones/${controller.zoneId}/transactions';
  
  print('🚀 Navigation vers: $routeName');
  print('📊 Arguments: zoneId=${controller.zoneId}, zoneName=$zoneName');
  
  Get.toNamed(
    routeName,
    arguments: {
      'zoneId': controller.zoneId,
      'zoneName': zoneName,
    },
  );
}
```

## 🏗️ Structure recommandée

```
lib/
├── app/
│   ├── routes/
│   │   └── app_pages.dart (configuration des routes)
│   └── bindings/
│       └── zone_transaction_page_binding.dart
├── features/
│   └── zones/
│       ├── controllers/
│       │   └── zone_transactions_controller.dart
│       ├── services/
│       │   └── zone_transaction_service.dart
│       └── views/
│           └── zone_transactions_page.dart
```

## ⚠️ Points d'attention

1. **Paramètres URL** : `zoneId` est extrait de l'URL `/zones/:zoneId/transactions`
2. **Arguments** : `zoneName` est passé via `arguments`
3. **Services** : `ZoneTransactionService` doit être disponible avant le contrôleur
4. **Contrôleur** : Doit être initialisé avec `zoneId` et `zoneName`

## 🧪 Test rapide

Pour tester si tout fonctionne :

```dart
// Dans n'importe quel contrôleur, testez :
Get.toNamed('/zones/test123/transactions', arguments: {'zoneName': 'Test Zone'});
```

Si la page s'affiche avec "Test Zone" dans le titre, la configuration est correcte ! 🎉