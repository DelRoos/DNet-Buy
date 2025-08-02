import 'package:dnet_buy/features/zones/controllers/zones_controller.dart';
import 'package:dnet_buy/features/zones/views/widgets/zone_list_item.dart';
import 'package:dnet_buy/shared/constants/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ZonesPage extends GetView<ZonesController> {
  const ZonesPage({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(ZonesController());

    return Scaffold(
      appBar: AppBar(title: const Text('Mes Zones WiFi')),
      floatingActionButton: FloatingActionButton(
        onPressed: controller.goToAddZone,
        child: const Icon(Icons.add),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.zones.isEmpty) {
          return const Center(
            child: Text(
              "Aucune zone WiFi n'a été créée.\nAppuyez sur '+' pour commencer.",
              textAlign: TextAlign.center,
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: controller.fetchZones,
          child: ListView.builder(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            itemCount: controller.zones.length,
            itemBuilder: (context, index) {
              final zone = controller.zones[index];
              return ZoneListItem(
                zone: zone,
                onTap: () => controller.goToZoneDetails(zone.id),
              );
            },
          ),
        );
      }),
    );
  }
}
