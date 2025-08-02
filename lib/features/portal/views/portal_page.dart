import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:dnet_buy/features/portal/controllers/portal_controller.dart';
import 'package:dnet_buy/features/portal/views/widgets/payment_popup.dart';
import 'package:dnet_buy/features/portal/views/widgets/purchased_ticket_details_popup.dart';
import 'package:dnet_buy/features/portal/views/widgets/ticket_card.dart';

class PortalPage extends GetView<PortalController> {
  const PortalPage({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(PortalController());

    return Scaffold(
      appBar: AppBar(title: const Text('DNet - Forfaits WiFi')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Choisissez votre forfait',
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              return ListView.separated(
                itemCount: controller.ticketTypes.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final ticketType = controller.ticketTypes[index];
                  return TicketCard(
                    ticketType: ticketType,
                    onBuy: () => showPaymentPopup(context, ticketType),
                  );
                },
              );
            }),
            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),
            Text(
              'Mes tickets récents',
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildPurchasedTicketsList(context),
          ],
        ),
      ),
    );
  }

  Widget _buildPurchasedTicketsList(BuildContext context) {
    return Obx(() {
      if (controller.purchasedTickets.isEmpty) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 32.0),
            child: Text("Vous n'avez aucun ticket récent."),
          ),
        );
      }
      return ListView.builder(
        itemCount: controller.purchasedTickets.length,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemBuilder: (_, index) {
          final ticket = controller.purchasedTickets[index];
          return Card(
            elevation: 2,
            child: ListTile(
              onTap: () => showPurchasedTicketDetailsPopup(context, ticket),
              leading: const Icon(Icons.receipt_long, color: Colors.blueAccent),
              title: Text(
                ticket.ticketTypeName,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                'Acheté le ${DateFormat('dd/MM/yy HH:mm').format(ticket.purchaseDate)}',
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${ticket.price} XAF',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
          );
        },
      );
    });
  }
}
