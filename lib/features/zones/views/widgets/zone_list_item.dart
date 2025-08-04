import 'package:flutter/material.dart';
import 'package:dnet_buy/features/zones/models/zone_model.dart';

class ZoneListItem extends StatelessWidget {
  final ZoneModel zone;
  final VoidCallback onTap;

  const ZoneListItem({super.key, required this.zone, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      child: ListTile(
        onTap: onTap,
        leading: Icon(
          Icons.wifi,
          color: zone.isActive ? Theme.of(context).primaryColor : Colors.grey,
        ),
        title: Text(
          zone.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          zone.routerType,
          style: TextStyle(color: Colors.grey.shade600),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Indicateur de statut
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: zone.isActive
                    ? Colors.green.shade100
                    : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                zone.isActive ? 'Actif' : 'Inactif',
                style: TextStyle(
                  color: zone.isActive
                      ? Colors.green.shade800
                      : Colors.grey.shade700,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
