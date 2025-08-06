// lib/features/zones/views/widgets/ticket_type_list_item.dart
// Simplifier cette classe pour éviter les erreurs

import 'package:flutter/material.dart';
import 'package:dnet_buy/features/zones/models/ticket_type_model.dart';
import 'package:dnet_buy/shared/utils/format_utils.dart';

class TicketTypeListItem extends StatelessWidget {
  final TicketTypeModel ticketType;
  final Function()? onTap;
  final Function(bool)? onToggleStatus;
  final Function()? onDelete;
  final Function()? onEdit;

  const TicketTypeListItem({
    super.key,
    required this.ticketType,
    this.onTap,
    this.onToggleStatus,
    this.onDelete,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: ticketType.isActive
              ? Colors.green.withOpacity(0.3)
              : Colors.orange.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const Divider(height: 24),
              _buildDetails(),
              const SizedBox(height: 8),
              _buildActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                ticketType.name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                ticketType.statusText,
                style: TextStyle(
                  fontSize: 12,
                  color: ticketType.isActive ? Colors.green : Colors.orange,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            FormatUtils.formatCurrency(ticketType.price.toDouble()),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          ticketType.description,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: [
            _buildDetailItem(
              Icons.calendar_today,
              'Validité: ${ticketType.validityHours} ${ticketType.validityHours > 1 ? 'jours' : 'jour'}',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDetailItem(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey.shade600),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        IconButton(
          icon: Icon(
            ticketType.isActive
                ? Icons.pause_circle_outline
                : Icons.play_circle_outline,
            color: ticketType.isActive ? Colors.orange : Colors.green,
          ),
          onPressed: onToggleStatus != null
              ? () => onToggleStatus!(!ticketType.isActive)
              : null,
          tooltip: ticketType.isActive ? 'Désactiver' : 'Activer',
        ),
        IconButton(
          icon: const Icon(Icons.edit_outlined, color: Colors.blue),
          onPressed: onEdit,
          tooltip: 'Modifier',
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          onPressed: onDelete,
          tooltip: 'Supprimer',
        ),
      ],
    );
  }
}
