import 'package:flutter/material.dart';
import 'package:dnet_buy/features/zones/models/ticket_type_model.dart';

class TicketCard extends StatelessWidget {
  final TicketTypeModel ticketType;
  final VoidCallback onBuy;

  const TicketCard({super.key, required this.ticketType, required this.onBuy});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              ticketType.name,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              ticketType.description,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${ticketType.price} XAF',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  'Validité : ${ticketType.validity}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onBuy,
              child: const Text('Acheter ce forfait'),
            ),
          ],
        ),
      ),
    );
  }
}
