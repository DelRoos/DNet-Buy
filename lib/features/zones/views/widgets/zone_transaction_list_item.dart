import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dnet_buy/features/transactions/models/transaction_model.dart';

class ZoneTransactionListItem extends StatelessWidget {
  final TransactionModel transaction;
  final VoidCallback onTap;
  final VoidCallback? onRefresh;

  const ZoneTransactionListItem({
    super.key,
    required this.transaction,
    required this.onTap,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormatter = DateFormat('dd/MM HH:mm');
    final numberFormatter = NumberFormat.decimalPattern('fr_FR');

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 0),
      elevation: 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              // Icône de statut
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _getStatusColor().withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _getStatusColor().withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Icon(
                  _getStatusIcon(),
                  color: _getStatusColor(),
                  size: 20,
                ),
              ),

              const SizedBox(width: 12),

              // Contenu principal
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Première ligne : Montant et type de forfait
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${numberFormatter.format(transaction.amount)} ${transaction.currency}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        // Badge de statut
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor().withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _getStatusColor().withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            transaction.statusText,
                            style: TextStyle(
                              color: _getStatusColor(),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 4),

                    // Deuxième ligne : Nom du forfait
                    Text(
                      transaction.planName,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: 4),

                    // Troisième ligne : Client et date
                    Row(
                      children: [
                        Icon(
                          Icons.phone,
                          size: 12,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            transaction.buyerPhoneNumber,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.access_time,
                          size: 12,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          dateFormatter.format(transaction.createdAt),
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),

                    // Quatrième ligne : Informations supplémentaires (si pertinentes)
                    if (transaction.isManualSale ||
                        transaction.credentials != null ||
                        transaction.freemopayReference != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          // Indicateur de vente manuelle
                          if (transaction.isManualSale) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.blue.shade200),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.person,
                                    size: 10,
                                    color: Colors.blue.shade700,
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    'Manuel',
                                    style: TextStyle(
                                      color: Colors.blue.shade700,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                          ],

                          // Indicateur de credentials disponibles
                          if (transaction.credentials != null) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border:
                                    Border.all(color: Colors.green.shade200),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.vpn_key,
                                    size: 10,
                                    color: Colors.green.shade700,
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    transaction.credentials!.username,
                                    style: TextStyle(
                                      color: Colors.green.shade700,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // Actions
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Bouton refresh (si transaction en cours)
                  if (onRefresh != null &&
                      (transaction.status == TransactionStatus.pending ||
                          transaction.status == TransactionStatus.created)) ...[
                    IconButton(
                      onPressed: onRefresh,
                      icon: const Icon(Icons.refresh),
                      iconSize: 18,
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(
                        minWidth: 28,
                        minHeight: 28,
                      ),
                      tooltip: 'Actualiser',
                    ),
                  ],

                  // Flèche d'indication
                  Icon(
                    Icons.chevron_right,
                    color: Colors.grey.shade400,
                    size: 20,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor() {
    switch (transaction.status) {
      case TransactionStatus.completed:
        return Colors.green;
      case TransactionStatus.failed:
        return Colors.red;
      case TransactionStatus.expired:
        return Colors.orange;
      case TransactionStatus.pending:
        return Colors.blue;
      case TransactionStatus.created:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon() {
    switch (transaction.status) {
      case TransactionStatus.completed:
        return Icons.check_circle;
      case TransactionStatus.failed:
        return Icons.error;
      case TransactionStatus.expired:
        return Icons.access_time;
      case TransactionStatus.pending:
        return Icons.hourglass_empty;
      case TransactionStatus.created:
        return Icons.radio_button_unchecked;
    }
  }
}
