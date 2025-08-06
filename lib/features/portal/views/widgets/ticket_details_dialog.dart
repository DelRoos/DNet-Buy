import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:dnet_buy/features/portal/models/purchased_ticket_model.dart';

class TicketDetailsDialog extends StatelessWidget {
  final PurchasedTicketModel ticket;

  const TicketDetailsDialog({
    Key? key,
    required this.ticket,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isExpired = ticket.isExpired;

    return AlertDialog(
      title: Text(
        ticket.ticketTypeName,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Badge de statut (Actif/Expiré)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isExpired ? Colors.red.shade100 : Colors.green.shade100,
                borderRadius: BorderRadius.circular(50),
              ),
              child: Text(
                isExpired ? 'Expiré' : 'Actif',
                style: TextStyle(
                  color:
                      isExpired ? Colors.red.shade800 : Colors.green.shade800,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Section identifiants
            _buildSection(
              context,
              title: 'Identifiants de connexion',
              content: Column(
                children: [
                  _buildDetailRow(
                    context,
                    'Utilisateur',
                    ticket.username,
                    canCopy: true,
                  ),
                  const SizedBox(height: 8),
                  _buildDetailRow(
                    context,
                    'Mot de passe',
                    ticket.password,
                    canCopy: true,
                  ),
                ],
              ),
              actionLabel: 'Copier tout',
              onAction: () => _copyAllCredentials(context),
            ),
            const SizedBox(height: 16),

            // Section détails du ticket
            _buildSection(
              context,
              title: 'Détails du ticket',
              content: Column(
                children: [
                  _buildDetailRow(
                    context,
                    'Zone',
                    ticket.zoneName,
                  ),
                  const SizedBox(height: 8),
                  _buildDetailRow(
                    context,
                    'Prix',
                    '${ticket.price} XAF',
                  ),
                  const SizedBox(height: 8),
                  _buildDetailRow(
                    context,
                    'Acheté le',
                    DateFormat('dd/MM/yyyy à HH:mm')
                        .format(ticket.purchaseDate),
                  ),
                  const SizedBox(height: 8),
                  _buildDetailRow(
                    context,
                    'Expire le',
                    DateFormat('dd/MM/yyyy à HH:mm')
                        .format(ticket.expirationDate),
                    textColor: isExpired ? Colors.red : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Section information de transaction
            _buildSection(
              context,
              title: 'Information de transaction',
              content: Column(
                children: [
                  _buildDetailRow(
                    context,
                    'ID Transaction',
                    ticket.transactionId,
                    canCopy: true,
                  ),
                ],
              ),
              info:
                  'Conservez cet identifiant pour récupérer votre ticket ultérieurement',
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Fermer'),
        ),
      ],
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required Widget content,
    String? actionLabel,
    VoidCallback? onAction,
    String? info,
  }) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                if (actionLabel != null && onAction != null)
                  TextButton(
                    onPressed: onAction,
                    child: Text(actionLabel),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            content,
            if (info != null) ...[
              const SizedBox(height: 8),
              Text(
                info,
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  fontSize: 12,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    String label,
    String value, {
    bool canCopy = false,
    Color? textColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '$label:',
          style: const TextStyle(color: Colors.grey),
        ),
        Row(
          children: [
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: textColor,
              ),
            ),
            if (canCopy) ...[
              const SizedBox(width: 4),
              InkWell(
                onTap: () => _copyToClipboard(context, value, label),
                child: const Icon(
                  Icons.copy,
                  size: 16,
                  color: Colors.blue,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  void _copyToClipboard(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copié dans le presse-papiers'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _copyAllCredentials(BuildContext context) {
    final credentials =
        'Utilisateur: ${ticket.username}\nMot de passe: ${ticket.password}';
    Clipboard.setData(ClipboardData(text: credentials));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Identifiants copiés dans le presse-papiers'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
