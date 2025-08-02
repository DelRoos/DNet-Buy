import 'package:dnet_buy/features/zones/controllers/zone_details_controller.dart';
import 'package:dnet_buy/features/zones/views/widgets/ticket_type_list_item.dart';
import 'package:dnet_buy/shared/constants/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ZoneDetailsPage extends GetView<ZoneDetailsController> {
  const ZoneDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Obx(() => Text(controller.zone.value?.name ?? 'Chargement...')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: controller.goToAddTicketType,
        icon: const Icon(Icons.add),
        label: const Text('Forfait'),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        return RefreshIndicator(
          onRefresh: controller.fetchData,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildZoneInfoCard(context),
                const SizedBox(height: AppConstants.defaultPadding * 1.5),
                Text(
                  'Types de Tickets (Forfaits)',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: AppConstants.defaultPadding),
                _buildTicketTypesList(),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildZoneInfoCard(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          children: [
            ListTile(
              leading: const Icon(Icons.description_outlined),
              title: const Text('Description'),
              subtitle: Text(controller.zone.value?.description ?? 'N/A'),
            ),
            ListTile(
              leading: const Icon(Icons.router_outlined),
              title: const Text('Type de Routeur'),
              subtitle: Text(controller.zone.value?.routerType ?? 'N/A'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTicketTypesList() {
    if (controller.ticketTypes.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text(
            "Aucun type de ticket n'a été créé pour cette zone.",
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return ListView.builder(
      itemCount: controller.ticketTypes.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        final ticketType = controller.ticketTypes[index];
        return TicketTypeListItem(
          ticketType: ticketType,
          onTap: () => controller.goToTicketManagement(ticketType.id),
          onCopyLink: () => controller.copyPaymentLink(ticketType.id),
        );
      },
    );
  }
}
