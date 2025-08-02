import 'package:flutter/services.dart';
import 'package:dnet_buy/features/zones/models/ticket_type_model.dart';
import 'package:dnet_buy/features/zones/models/zone_model.dart';
import 'package:get/get.dart';

class ZoneDetailsController extends GetxController {
  final String zoneId;
  ZoneDetailsController({required this.zoneId});

  var isLoading = true.obs;
  var zone = Rx<ZoneModel?>(null);
  var ticketTypes = <TicketTypeModel>[].obs;

  @override
  void onInit() {
    fetchData();
    super.onInit();
  }

  Future<void> fetchData() async {
    isLoading.value = true;
    await Future.delayed(const Duration(seconds: 1));

    zone.value = ZoneModel(
      id: zoneId,
      name: 'Restaurant - Terrasse',
      description: 'Couverture extérieure près de la fontaine',
      routerType: 'MikroTik hAP ac²',
      isActive: true,
    );

    ticketTypes.assignAll([
      TicketTypeModel(
        id: 'type1',
        name: 'Pass Journée',
        description: 'Accès 24h',
        price: 1000,
        validity: '24 Heures',
        expirationAfterCreation: 30,
        nbMaxUtilisations: 1,
        isActive: true,
      ),
      TicketTypeModel(
        id: 'type2',
        name: 'Forfait Soirée',
        description: 'Accès de 18h à minuit',
        price: 500,
        validity: '6 Heures',
        expirationAfterCreation: 7,
        nbMaxUtilisations: 1,
        isActive: true,
      ),
      TicketTypeModel(
        id: 'type3',
        name: 'Pass Semaine',
        description: 'Accès 7 jours',
        price: 5000,
        validity: '7 Jours',
        expirationAfterCreation: 90,
        nbMaxUtilisations: 1,
        isActive: false,
      ),
    ]);

    isLoading.value = false;
  }

  void goToAddTicketType() {
    Get.toNamed('/dashboard/zones/$zoneId/add-ticket');
  }

  void copyPaymentLink(String ticketTypeId) {
    const merchantId = 'simulated_merchant_id';

    final baseUrl = 'https://app.dnet.com';
    final paymentUrl =
        '$baseUrl/buy?merchantId=$merchantId&zoneId=$zoneId&typeId=$ticketTypeId';

    Clipboard.setData(ClipboardData(text: paymentUrl));

    Get.snackbar(
      'Lien Copié',
      'Le lien de paiement pour ce forfait a été copié dans le presse-papiers.',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void goToTicketManagement(String ticketTypeId) {
    Get.toNamed('/dashboard/zones/$zoneId/ticket-types/$ticketTypeId');
    Get.snackbar(
      'Navigation',
      'Gestion des tickets pour le forfait $ticketTypeId',
    );
  }
}
