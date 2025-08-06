import 'package:flutter/material.dart';
import 'package:dnet_buy/features/zones/models/ticket_type_model.dart';

class TicketCard extends StatelessWidget {
  final TicketTypeModel ticketType;
  final VoidCallback onBuy;

  const TicketCard({
    Key? key,
    required this.ticketType,
    required this.onBuy,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final color = _getTicketColor(ticketType);
    final isOutOfStock = ticketType.ticketsAvailable <= 0;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withOpacity(0.3), width: 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: isOutOfStock ? null : onBuy,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: isOutOfStock ? Colors.grey.shade100 : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      ticketType.name,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isOutOfStock ? Colors.grey : color,
                          ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: (isOutOfStock ? Colors.grey : color)
                          .withOpacity(0.15),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Text(
                      '${ticketType.price} XAF',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isOutOfStock ? Colors.grey : color,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                ticketType.description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isOutOfStock ? Colors.grey : null,
                    ),
              ),
              const SizedBox(height: 16),

              // Caractéristiques du forfait
              _buildFeatureRow(
                context,
                Icons.timer_outlined,
                'Validité: ${_formatValidity(ticketType.validityHours)}',
                isOutOfStock,
                color,
              ),

              if (ticketType.metadata != null &&
                  ticketType.metadata!.containsKey('speedLimit'))
                _buildFeatureRow(
                  context,
                  Icons.speed,
                  'Vitesse: ${ticketType.metadata!['speedLimit']}',
                  isOutOfStock,
                  color,
                ),

              const SizedBox(height: 16),

              // Indicateur de stock et bouton d'achat
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Indicateur de stock
                  Text(
                    isOutOfStock
                        ? 'Épuisé'
                        : '${ticketType.ticketsAvailable} disponible${ticketType.ticketsAvailable > 1 ? 's' : ''}',
                    style: TextStyle(
                      color: isOutOfStock ? Colors.red : Colors.green,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  // Bouton d'achat
                  ElevatedButton(
                    onPressed: isOutOfStock ? null : onBuy,
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: color,
                      disabledBackgroundColor: Colors.grey.shade300,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                    child: const Text('Acheter'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureRow(
    BuildContext context,
    IconData icon,
    String text,
    bool isDisabled,
    Color activeColor,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: isDisabled ? Colors.grey : activeColor,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isDisabled ? Colors.grey : activeColor,
            ),
          ),
        ],
      ),
    );
  }

  Color _getTicketColor(TicketTypeModel ticket) {
    // Définir la couleur en fonction des métadonnées ou du prix
    if (ticket.metadata != null && ticket.metadata!.containsKey('color')) {
      final color = ticket.metadata!['color'] as String;
      switch (color) {
        case 'blue':
          return Colors.blue;
        case 'green':
          return Colors.green;
        case 'orange':
          return Colors.orange;
        case 'purple':
          return Colors.purple;
        case 'red':
          return Colors.red;
        default:
          return Colors.blueAccent;
      }
    }

    // Couleur basée sur le prix si aucune métadonnée de couleur n'est définie
    if (ticket.price <= 500) {
      return Colors.green;
    } else if (ticket.price <= 1000) {
      return Colors.blue;
    } else if (ticket.price <= 2000) {
      return Colors.orange;
    } else {
      return Colors.purple;
    }
  }

  String _formatValidity(int hours) {
    if (hours < 1) {
      return '${hours * 60} minutes';
    } else if (hours == 1) {
      return '1 heure';
    } else if (hours < 24) {
      return '$hours heures';
    } else if (hours == 24) {
      return '1 jour';
    } else if (hours < 168) {
      // 7 jours
      final days = hours ~/ 24;
      return '$days jour${days > 1 ? 's' : ''}';
    } else if (hours == 168) {
      // 1 semaine
      return '1 semaine';
    } else if (hours < 720) {
      // 30 jours
      final weeks = hours ~/ 168;
      return '$weeks semaine${weeks > 1 ? 's' : ''}';
    } else if (hours <= 744) {
      // ~31 jours
      return '1 mois';
    } else {
      final months = hours ~/ 720;
      return '$months mois';
    }
  }
}
