import 'package:dnet_buy/features/dashboard/controllers/dashboard_controller.dart';
import 'package:dnet_buy/features/dashboard/views/widgets/action_list_tile.dart';
import 'package:dnet_buy/features/dashboard/views/widgets/stat_card.dart';
import 'package:dnet_buy/shared/constants/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class DashboardPage extends GetView<DashboardController> {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(DashboardController());

    final numberFormatter = NumberFormat.decimalPattern('fr_FR');

    return Scaffold(
      appBar: AppBar(
        title: Image.asset('assets/images/logo.png', height: 35),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Se déconnecter',
            onPressed: () => controller.logout(),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        return RefreshIndicator(
          onRefresh: () => controller.fetchDashboardData(),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Bonjour,', style: Theme.of(context).textTheme.titleLarge),
                Obx(
                  () => Text(
                    controller.userName,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                const SizedBox(height: AppConstants.defaultPadding),
                GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: AppConstants.defaultPadding,
                  mainAxisSpacing: AppConstants.defaultPadding,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    StatCard(
                      icon: Icons.monetization_on,
                      value:
                          '${numberFormatter.format(controller.totalRevenue.value)} XAF',
                      label: 'Revenu Total',
                      color: Colors.green,
                    ),
                    StatCard(
                      icon: Icons.receipt_long,
                      value: numberFormatter.format(
                        controller.ticketsSoldToday.value,
                      ),
                      label: 'Tickets Vendus (jour)',
                      color: Colors.blue,
                    ),
                    StatCard(
                      icon: Icons.wifi,
                      value: controller.activeZones.value.toString(),
                      label: 'Zones Actives',
                      color: Colors.orange,
                    ),
                    StatCard(
                      icon: Icons.confirmation_number,
                      value: numberFormatter.format(
                        controller.availableTickets.value,
                      ),
                      label: 'Tickets Disponibles',
                      color: Colors.purple,
                    ),
                  ],
                ),
                const SizedBox(height: AppConstants.defaultPadding * 2),
                Text(
                  'Actions Rapides',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: AppConstants.defaultPadding / 2),
                ActionListTile(
                  icon: Icons.router,
                  title: 'Gérer mes Zones WiFi',
                  subtitle: 'Créer et configurer vos hotspots',
                  onTap: () => Get.toNamed('/dashboard/zones'),
                ),
                ActionListTile(
                  icon: Icons.history,
                  title: 'Historique des Transactions',
                  subtitle: 'Consulter toutes les ventes',
                  onTap: () => Get.toNamed('/dashboard/transactions'),
                ),
                ActionListTile(
                  icon: Icons.settings,
                  title: 'Paramètres du Compte',
                  subtitle: 'Gérer vos informations et clés API',
                  onTap: () => Get.toNamed('/dashboard/settings'),
                ),

                ActionListTile(
                  icon: Icons.search,
                  title: 'Tickets par téléphone',
                  subtitle: 'voir les tickets associés à un numéro',
                  onTap: () => Get.toNamed('/user-tickets'),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}
