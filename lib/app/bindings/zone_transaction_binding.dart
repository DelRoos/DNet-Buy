import 'package:get/get.dart';
import 'package:dnet_buy/features/zones/services/zone_transaction_service.dart';

class ZoneTransactionBinding extends Bindings {
  @override
  void dependencies() {
    // Enregistrer le service ZoneTransactionService
    Get.lazyPut<ZoneTransactionService>(
      () => ZoneTransactionService(),
      fenix: true, // Permet la réinitialisation automatique
    );
  }
}
