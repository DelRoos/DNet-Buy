// lib/features/zones/views/widgets/zone_list_item.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dnet_buy/features/zones/models/zone_model.dart';

class ZoneListItem extends StatelessWidget {
  final ZoneModel zone;
  final VoidCallback onTap;
  final Function(bool) onToggleStatus;
  final VoidCallback onDelete;

  const ZoneListItem({
    super.key,
    required this.zone,
    required this.onTap,
    required this.onToggleStatus,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête avec nom et statut
              Row(
                children: [
                  Icon(
                    Icons.wifi,
                    color: zone.isActive 
                        ? Get.theme.primaryColor 
                        : Colors.grey.shade400,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          zone.name,
                          style: Get.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          zone.routerType,
                          style: Get.textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusChip(),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Description
              Text(
                zone.description,
                style: Get.textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade700,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              
              const SizedBox(height: 8),
              
              // Tags si disponibles
              if (zone.tags != null && zone.tags!.isNotEmpty)
                Wrap(
                  spacing: 6.0,
                  runSpacing: 4.0,
                  children: zone.tags!.take(3).map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Get.theme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        tag,
                        style: TextStyle(
                          fontSize: 10,
                          color: Get.theme.primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              
              const SizedBox(height: 12),
              
              // Actions en bas
              Row(
                children: [
                  Text(
                    'Créée le ${zone.formattedCreationDate}',
                    style: Get.textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade500,
                    ),
                  ),
                  const Spacer(),
                  _buildActionButtons(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: zone.isActive 
            ? Colors.green.shade100 
            : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: zone.isActive 
                  ? Colors.green.shade600 
                  : Colors.grey.shade500,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            zone.statusText,
            style: TextStyle(
              color: zone.isActive 
                  ? Colors.green.shade800 
                  : Colors.grey.shade700,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Bouton toggle statut
        IconButton(
          icon: Icon(
            zone.isActive ? Icons.pause_circle : Icons.play_circle,
            color: zone.isActive ? Colors.orange : Colors.green,
          ),
          onPressed: () => onToggleStatus(!zone.isActive),
          tooltip: zone.isActive ? 'Désactiver' : 'Activer',
        ),
        
        // Bouton supprimer
        IconButton(
          icon: Icon(
            Icons.delete_outline,
            color: Colors.red.shade400,
          ),
          onPressed: onDelete,
          tooltip: 'Supprimer',
        ),
        
        // Bouton détails
        Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.grey.shade400,
        ),
      ],
    );
  }
}