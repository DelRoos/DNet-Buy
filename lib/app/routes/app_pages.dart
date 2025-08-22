import 'package:get/get.dart';
import 'package:dnet_buy/features/zones/views/zone_transactions_page.dart';
import 'package:dnet_buy/features/zones/controllers/zone_transactions_controller.dart';
import 'package:dnet_buy/app/bindings/zone_transaction_binding.dart';

class AppPages {
  static const INITIAL = '/';
  
  static final routes = [
    // ... autres routes existantes
    
    // Route pour les transactions de zone
    GetPage(
      name: '/zones/:zoneId/transactions',
      page: () => const ZoneTransactionsPage(),
      binding: BindingsBuilder(() {
        // Récupérer les paramètres
        final zoneId = Get.parameters['zoneId'] ?? '';
        final arguments = Get.arguments as Map<String, dynamic>? ?? {};
        final zoneName = arguments['zoneName'] ?? 'Zone';
        
        // Initialiser le contrôleur avec les paramètres
        Get.put(ZoneTransactionsController(
          zoneId: zoneId,
          zoneName: zoneName,
        ));
        
        // S'assurer que le service est disponible
        ZoneTransactionBinding().dependencies();
      }),
      middlewares: [
        // Ajouter middleware d'auth si nécessaire
      ],
    ),
  ];
}