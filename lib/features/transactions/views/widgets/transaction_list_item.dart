import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dnet_buy/features/transactions/models/transaction_model.dart';

class TransactionListItem extends StatelessWidget {
  final TransactionModel transaction;
  final Color statusColor;
  final IconData statusIcon;

  const TransactionListItem({
    super.key,
    required this.transaction,
    required this.statusColor,
    required this.statusIcon,
  });

  @override
  Widget build(BuildContext context) {
    final numberFormatter = NumberFormat.decimalPattern('fr_FR');
    final dateFormatter = DateFormat('dd/MM/yy HH:mm');

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      child: ListTile(
        leading: Icon(statusIcon, color: statusColor, size: 32),
        title: Text(
          '${numberFormatter.format(transaction.amount)} XAF - ${transaction.ticketTypeName}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Client: ${transaction.buyerPhoneNumber}'),
            Text('Date: ${dateFormatter.format(transaction.transactionDate)}'),
          ],
        ),
        trailing: transaction.status == TransactionStatus.success
            ? Text(
                transaction.ticketUsername,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              )
            : null,
        isThreeLine: true,
      ),
    );
  }
}
