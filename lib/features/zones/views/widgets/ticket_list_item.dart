import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:dnet_buy/features/zones/models/ticket_model.dart'; // Importer le package pour le formatage

class TicketListItem extends StatelessWidget {
  final TicketModel ticket;
  final String ticketValidity;

  const TicketListItem({
    super.key,
    required this.ticket,
    required this.ticketValidity,
  });

  @override
  Widget build(BuildContext context) {
    bool isSold = ticket.status == 'sold';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      child: ExpansionTile(
        leading: Icon(
          isSold ? Icons.lock_outline : Icons.vpn_key_outlined,
          color:
              isSold ? Colors.orange.shade700 : Theme.of(context).primaryColor,
        ),
        title: Text(
          ticket.username,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          isSold
              ? 'Vendu le ${DateFormat('dd/MM/yy HH:mm').format(ticket.soldAt!)}'
              : ticket.password,
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isSold ? Colors.orange.shade100 : Colors.green.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            isSold ? 'Vendu' : 'Disponible',
            style: TextStyle(
              color: isSold ? Colors.orange.shade800 : Colors.green.shade800,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        children: isSold
            ? _buildSoldTicketDetails(context)
            : _buildAvailableTicketActions(context),
      ),
    );
  }

  List<Widget> _buildSoldTicketDetails(BuildContext context) {
    final endDate = ticket.firstUsedAt?.add(const Duration(hours: 24));

    return [
      const Divider(height: 1),
      _buildDetailRow(
        context,
        Icons.shopping_cart_outlined,
        'Acheté par',
        ticket.buyerPhoneNumber ?? 'N/A',
      ),
      _buildDetailRow(
        context,
        Icons.play_circle_outline,
        'Début d\'utilisation',
        ticket.firstUsedAt != null
            ? DateFormat('le dd/MM/yyyy à HH:mm').format(ticket.firstUsedAt!)
            : 'Jamais utilisé',
      ),
      _buildDetailRow(
        context,
        Icons.timer_off_outlined,
        'Expire le',
        endDate != null
            ? DateFormat('le dd/MM/yyyy à HH:mm').format(endDate)
            : 'N/A',
      ),
      _buildDetailRow(
        context,
        Icons.receipt_long_outlined,
        'Réf. Paiement',
        ticket.paymentReference ?? 'N/A',
        canCopy: true,
      ),
    ];
  }

  List<Widget> _buildAvailableTicketActions(BuildContext context) {
    return [
      const Divider(height: 1),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Identifiants:', style: Theme.of(context).textTheme.bodySmall),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              icon: const Icon(Icons.copy, size: 16),
              label: const Text('Copier'),
              onPressed: () {
                final credentials =
                    'Username: ${ticket.username}\nPassword: ${ticket.password}';
                Clipboard.setData(ClipboardData(text: credentials));
                Get.snackbar(
                  'Copié !',
                  'Les identifiants ont été copiés dans le presse-papiers.',
                );
              },
            ),
          ],
        ),
      ),
    ];
  }

  // Widget helper pour créer une ligne de détail
  Widget _buildDetailRow(
    BuildContext context,
    IconData icon,
    String label,
    String value, {
    bool canCopy = false,
  }) {
    return ListTile(
      dense: true,
      leading: Icon(
        icon,
        size: 20,
        color: Theme.of(context).textTheme.bodySmall?.color,
      ),
      title: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        value,
        style: Theme.of(
          context,
        ).textTheme.bodyLarge?.copyWith(fontFamily: 'monospace'),
      ),
      trailing: canCopy
          ? IconButton(
              icon: const Icon(Icons.copy, size: 18),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: value));
                Get.snackbar(
                  'Copié !',
                  '$label copié dans le presse-papiers.',
                );
              },
            )
          : null,
    );
  }
}
