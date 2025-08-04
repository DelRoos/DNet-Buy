import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:dnet_buy/features/portal/models/purchased_ticket_model.dart';

void showPurchasedTicketDetailsPopup(
  BuildContext context,
  PurchasedTicketModel ticket,
) {
  Get.defaultDialog(
    title: 'Détails de votre ticket',
    titleStyle: const TextStyle(fontWeight: FontWeight.bold),
    content: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          ticket.ticketTypeName,
          style: Theme.of(context).textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
        Text(
          'Acheté le ${DateFormat('dd/MM/yyyy à HH:mm').format(ticket.purchaseDate)}',
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        Card(
          elevation: 2,
          color: Theme.of(context).primaryColor.withOpacity(0.1),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildCredentialRow('Utilisateur', ticket.username),
                const Divider(),
                _buildCredentialRow('Mot de passe', ticket.password),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Utilisez ces identifiants pour vous connecter au portail WiFi.',
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    ),
    confirm: ElevatedButton(
      onPressed: () => Get.back(),
      child: const Text('Fermer'),
    ),
  );
}

Widget _buildCredentialRow(String label, String value) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      IconButton(
        icon: const Icon(Icons.copy, size: 20),
        tooltip: 'Copier $label',
        onPressed: () {
          Clipboard.setData(ClipboardData(text: value));
          Get.rawSnackbar(
            message: '$label copié !',
            snackPosition: SnackPosition.BOTTOM,
            borderRadius: 8,
            margin: const EdgeInsets.all(10),
          );
        },
      ),
    ],
  );
}
