import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:dnet_buy/features/portal/models/purchased_ticket_model.dart';

void showPurchasedTicketDetailsPopup(
    BuildContext context, PurchasedTicketModel ticket) {
  Get.defaultDialog(
    title: 'Détails de votre ticket',
    content: Column(
      children: [
        _buildInfoRow(context, 'Forfait', ticket.ticketTypeName),
        _buildInfoRow(context, 'Prix', '${ticket.price} XAF'),
        _buildInfoRow(
          context,
          'Date d\'achat',
          DateFormat('dd/MM/yyyy à HH:mm').format(ticket.purchaseDate),
        ),
        _buildInfoRow(
          context,
          'Identifiant',
          ticket.transactionId,
          canCopy: true,
        ),
        const Divider(height: 32),
        Card(
          color: Colors.blue.shade50,
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Identifiants de connexion',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade800,
                      ),
                ),
                const SizedBox(height: 16),
                _buildCredentialRow(
                  context,
                  'Nom d\'utilisateur',
                  ticket.username,
                ),
                const SizedBox(height: 8),
                _buildCredentialRow(
                  context,
                  'Mot de passe',
                  ticket.password,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _copyCredentials(context, ticket),
                    icon: const Icon(Icons.copy),
                    label: const Text('Copier les identifiants'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
    confirm: TextButton(
      onPressed: () => Get.back(),
      child: const Text('Fermer'),
    ),
  );
}

Widget _buildInfoRow(
  BuildContext context,
  String label,
  String value, {
  bool canCopy = false,
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8.0),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '$label:',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        Row(
          children: [
            Text(value),
            if (canCopy) ...[
              const SizedBox(width: 8),
              InkWell(
                onTap: () => _copyToClipboard(context, value),
                child: const Icon(
                  Icons.copy,
                  size: 18,
                  color: Colors.blue,
                ),
              ),
            ],
          ],
        ),
      ],
    ),
  );
}

Widget _buildCredentialRow(
  BuildContext context,
  String label,
  String value,
) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
        ),
      ),
      Text(
        value,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontFamily: 'monospace',
        ),
      ),
    ],
  );
}

void _copyToClipboard(BuildContext context, String text) {
  Clipboard.setData(ClipboardData(text: text));
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Copié dans le presse-papiers'),
      duration: Duration(seconds: 2),
    ),
  );
}

void _copyCredentials(BuildContext context, PurchasedTicketModel ticket) {
  final text =
      'Nom d\'utilisateur: ${ticket.username}\nMot de passe: ${ticket.password}';
  Clipboard.setData(ClipboardData(text: text));
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Identifiants copiés dans le presse-papiers'),
      duration: Duration(seconds: 2),
    ),
  );
}
