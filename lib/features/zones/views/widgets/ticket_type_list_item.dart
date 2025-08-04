import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dnet_buy/features/zones/models/ticket_type_model.dart';

class TicketTypeListItem extends StatelessWidget {
  final TicketTypeModel ticketType;
  final VoidCallback onTap;
  final VoidCallback onCopyLink;

  const TicketTypeListItem({
    super.key,
    required this.ticketType,
    required this.onTap,
    required this.onCopyLink,
  });

  @override
  Widget build(BuildContext context) {
    final numberFormatter = NumberFormat.decimalPattern('fr_FR');
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      child: ListTile(
        onTap: onTap,
        leading: const Icon(Icons.confirmation_number_outlined, size: 32),
        title: Text(
          ticketType.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${numberFormatter.format(ticketType.price)} XAF - Validité: ${ticketType.validity}',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: ticketType.isActive
                    ? Colors.green.shade100
                    : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                ticketType.isActive ? 'Actif' : 'Inactif',
                style: TextStyle(
                  color: ticketType.isActive
                      ? Colors.green.shade800
                      : Colors.grey.shade700,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.link),
              tooltip: 'Copier le lien de paiement',
              onPressed: onCopyLink,
            ),
          ],
        ),
      ),
    );
  }
}
