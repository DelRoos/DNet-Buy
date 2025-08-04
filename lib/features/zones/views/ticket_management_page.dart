import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dnet_buy/features/dashboard/views/widgets/stat_card.dart';
import 'package:dnet_buy/features/zones/controllers/ticket_management_controller.dart';
import 'package:dnet_buy/features/zones/views/widgets/ticket_list_item.dart';
import 'package:dnet_buy/shared/constants/app_constants.dart';
import 'package:dnet_buy/shared/widgets/custom_button.dart';

class TicketManagementPage extends GetView<TicketManagementController> {
  const TicketManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Obx(
          () =>
              Text(controller.ticketType.value?.name ?? 'Gestion des tickets'),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatsGrid(),
              const SizedBox(height: AppConstants.defaultPadding * 1.5),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.defaultPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Importer des Tickets',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Uploadez ici le fichier CSV généré depuis votre serveur Mikhmon.',
                      ),
                      const SizedBox(height: 16),
                      Obx(
                        () => CustomButton(
                          text: 'Choisir un fichier CSV',
                          icon: Icons.upload_file,
                          isLoading: controller.isUploading.value,
                          onPressed: controller.pickAndUploadCsv,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppConstants.defaultPadding * 1.5),
              Text(
                'Tickets Importés',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppConstants.defaultPadding / 2),
              ListView.builder(
                itemCount: controller.tickets.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (_, index) {
                  final ticket = controller.tickets[index];
                  return TicketListItem(
                    ticket: ticket,
                    ticketValidity:
                        controller.ticketType.value?.validity ?? '0 Heures',
                  );
                },
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildStatsGrid() {
    // Calcul simulé des stats
    final total = controller.tickets.length;
    final sold = controller.tickets.where((t) => t.status == 'sold').length;
    final available = total - sold;

    return GridView.count(
      crossAxisCount: 3,
      crossAxisSpacing: AppConstants.defaultPadding / 2,
      mainAxisSpacing: AppConstants.defaultPadding / 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        StatCard(
          icon: Icons.all_inclusive,
          value: total.toString(),
          label: 'Total',
          color: Colors.blue,
        ),
        StatCard(
          icon: Icons.lock_outline,
          value: sold.toString(),
          label: 'Vendus',
          color: Colors.orange,
        ),
        StatCard(
          icon: Icons.check_circle_outline,
          value: available.toString(),
          label: 'Disponibles',
          color: Colors.green,
        ),
      ],
    );
  }
}
