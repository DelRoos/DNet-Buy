// lib/features/zones/views/widgets/zone_stats_overview.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ZoneStatsOverview extends StatelessWidget {
  final Map<String, dynamic> stats;

  const ZoneStatsOverview({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Statistiques rapides',
              style: Get.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Première ligne - Forfaits
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Forfaits',
                    stats['totalTicketTypes']?.toString() ?? '0',
                    Icons.receipt_long,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Actifs',
                    stats['activeTicketTypes']?.toString() ?? '0',
                    Icons.check_circle,
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Inactifs',
                    stats['inactiveTicketTypes']?.toString() ?? '0',
                    Icons.pause_circle,
                    Colors.orange,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Deuxième ligne - Tickets et Revenus
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Vendus',
                    stats['totalTicketsSold']?.toString() ?? '0',
                    Icons.sell,
                    Colors.purple,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Stock',
                    stats['totalTicketsAvailable']?.toString() ?? '0',
                    Icons.inventory,
                    Colors.indigo,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Revenus',
                    '${stats['totalRevenue'] ?? 0} F',
                    Icons.attach_money,
                    Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Get.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Get.textTheme.bodySmall?.copyWith(
              color: Colors.grey.shade700,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}