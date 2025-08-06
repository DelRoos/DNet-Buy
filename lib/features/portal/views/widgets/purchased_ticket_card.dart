import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:dnet_buy/features/portal/models/purchased_ticket_model.dart';
import 'package:dnet_buy/features/portal/views/widgets/ticket_details_dialog.dart';

class PurchasedTicketCard extends StatelessWidget {
  final PurchasedTicketModel ticket;

  const PurchasedTicketCard({
    Key? key,
    required this.ticket,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isExpired = ticket.isExpired;

    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: isExpired ? Colors.grey.shade300 : Colors.blue.shade200,
          width: 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => _showTicketDetails(context),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icône de ticket
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isExpired
                          ? Colors.grey.shade100
                          : Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.confirmation_number,
                      color: isExpired ? Colors.grey : Colors.blue,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Informations du ticket
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ticket.ticketTypeName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: isExpired ? Colors.grey : null,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Acheté le ${DateFormat('dd/MM/yyyy à HH:mm').format(ticket.purchaseDate)}',
                          style: TextStyle(
                            fontSize: 13,
                            color:
                                isExpired ? Colors.grey : Colors.grey.shade700,
                          ),
                        ),
                        if (isExpired)
                          const Text(
                            'Expiré',
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.w500,
                              fontSize: 13,
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Prix et flèche
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${ticket.price} XAF',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isExpired ? Colors.grey : Colors.blue,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Icon(
                        Icons.arrow_forward_ios,
                        size: 14,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                ],
              ),

              // Actions rapides pour le ticket
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Bouton de copie des identifiants
                    OutlinedButton.icon(
                      onPressed: () => _copyCredentials(context),
                      icon: const Icon(Icons.copy, size: 16),
                      label: const Text('Copier identifiants'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTicketDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => TicketDetailsDialog(ticket: ticket),
    );
  }

  void _copyCredentials(BuildContext context) {
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
