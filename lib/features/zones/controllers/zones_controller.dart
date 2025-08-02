import 'package:get/get.dart';
import 'package:dnet_buy/features/zones/models/zone_model.dart';

class ZonesController extends GetxController {
  var isLoading = true.obs;
  var zones = <ZoneModel>[].obs;

  @override
  void onInit() {
    fetchZones();
    super.onInit();
  }

  Future<void> fetchZones() async {
    isLoading.value = true;
    await Future.delayed(const Duration(seconds: 1));

    zones.assignAll([
      ZoneModel(
        id: 'zone1',
        name: 'Restaurant - Terrasse',
        description: 'Couverture extérieure près de la fontaine',
        routerType: 'MikroTik hAP ac²',
        isActive: true,
      ),
      ZoneModel(
        id: 'zone2',
        name: 'Hôtel - Réception',
        description: 'Zone d\'accueil principale',
        routerType: 'Ubiquiti UniFi AP',
        isActive: true,
      ),
      ZoneModel(
        id: 'zone3',
        name: 'Salle de Conférence',
        description: 'Zone temporairement désactivée',
        routerType: 'MikroTik hAP ac²',
        isActive: false,
      ),
    ]);
    isLoading.value = false;
  }

  void goToAddZone() {
    Get.toNamed('/dashboard/zones/add');
  }

  void goToZoneDetails(String zoneId) {
    Get.toNamed('/dashboard/zones/$zoneId');
    Get.snackbar('Navigation', 'Affichage des détails pour la zone $zoneId');
  }
}
