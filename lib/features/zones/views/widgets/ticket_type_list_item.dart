// lib/features/zones/views/widgets/ticket_type_list_item.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dnet_buy/features/zones/models/ticket_type_model.dart';

class TicketTypeListItem extends StatelessWidget {
  final TicketTypeModel ticketType;
  final VoidCallback onTap;
  final VoidCallback onCopyLink;
  final Function(bool) onToggleStatus;
  final VoidCallback onDelete;

  const TicketTypeListItem({
    super.key,
    required this.ticketType,
    required this.onTap,
    required this.onCopyLink,
    required this.onToggleStatus,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête avec nom, prix et statut
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ticketType.name,
                          style: Get.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          ticketType.formattedPrice,
                          style: Get.textTheme.titleMedium?.copyWith(
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusChip(),
                  const SizedBox(width: 8),
                  _buildStockChip(),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Description
              Text(
                ticketType.description,
                style: Get.textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade700,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              
              const SizedBox(height: 12),
              
              // Informations détaillées
              Row(
                children: [
                  _buildInfoChip(
                    Icons.schedule,
                    ticketType.validity,
                    Colors.blue,
                  ),
                  const SizedBox(width: 8),
                  _buildInfoChip(
                    Icons.repeat,
                    '${ticketType.nbMaxUtilisations}x',
                    Colors.purple,
                  ),
                  const SizedBox(width: 8),
                  _buildInfoChip(
                    Icons.calendar_today,
                    '${ticketType.expirationAfterCreation}j',
                    Colors.orange,
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Statistiques rapides
              Row(
                children: [
                  _buildStatChip('Générés', ticketType.totalTicketsGenerated),
                  const SizedBox(width: 12),
                  _buildStatChip('Vendus', ticketType.ticketsSold),
                  const SizedBox(width: 12),
                  _buildStatChip('Dispo', ticketType.ticketsAvailable),
                  const Spacer(),
                  Text(
                    'Rev: ${(ticketType.ticketsSold * ticketType.price)} F',
                    style: Get.textTheme.bodySmall?.copyWith(
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Actions
              Row(
                children: [
                  // Bouton copier lien
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onCopyLink,
                      icon: const Icon(Icons.link, size: 16),
                      label: const Text('Copier lien'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 8),
                  
                  // Bouton toggle statut
                  IconButton(
                    icon: Icon(
                      ticketType.isActive ? Icons.pause_circle : Icons.play_circle,
                      color: ticketType.isActive ? Colors.orange : Colors.green,
                    ),
                    onPressed: () => onToggleStatus(!ticketType.isActive),
                    tooltip: ticketType.isActive ? 'Désactiver' : 'Activer',
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: ticketType.isActive 
            ? Colors.green.shade100 
            : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(10),
     ),
     child: Row(
       mainAxisSize: MainAxisSize.min,
       children: [
         Container(
           width: 6,
           height: 6,
           decoration: BoxDecoration(
             color: ticketType.isActive 
                 ? Colors.green.shade600 
                 : Colors.grey.shade500,
             shape: BoxShape.circle,
           ),
         ),
         const SizedBox(width: 4),
         Text(
           ticketType.statusText,
           style: TextStyle(
             color: ticketType.isActive 
                 ? Colors.green.shade800 
                 : Colors.grey.shade700,
             fontSize: 10,
             fontWeight: FontWeight.bold,
           ),
         ),
       ],
     ),
   );
 }

 Widget _buildStockChip() {
   Color color;
   String text;
   
   if (ticketType.ticketsAvailable == 0) {
     color = Colors.red;
     text = 'Épuisé';
   } else if (ticketType.ticketsAvailable < 10) {
     color = Colors.orange;
     text = 'Faible';
   } else {
     color = Colors.green;
     text = 'Stock OK';
   }

   return Container(
     padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
     decoration: BoxDecoration(
       color: color.withOpacity(0.1),
       borderRadius: BorderRadius.circular(10),
     ),
     child: Text(
       text,
       style: TextStyle(
         color: color.withOpacity(0.7),
         fontSize: 10,
         fontWeight: FontWeight.bold,
       ),
     ),
   );
 }

 Widget _buildInfoChip(IconData icon, String text, Color color) {
   return Container(
     padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
     decoration: BoxDecoration(
       color: color.withOpacity(0.1),
       borderRadius: BorderRadius.circular(8),
     ),
     child: Row(
       mainAxisSize: MainAxisSize.min,
       children: [
         Icon(icon, size: 12, color: color),
         const SizedBox(width: 4),
         Text(
           text,
           style: TextStyle(
             fontSize: 10,
             color: color.withOpacity(0.7),
             fontWeight: FontWeight.w500,
           ),
         ),
       ],
     ),
   );
 }

 Widget _buildStatChip(String label, int value) {
   return Column(
     children: [
       Text(
         value.toString(),
         style: Get.textTheme.bodySmall?.copyWith(
           fontWeight: FontWeight.bold,
           color: Colors.grey.shade800,
         ),
       ),
       Text(
         label,
         style: Get.textTheme.bodySmall?.copyWith(
           fontSize: 10,
           color: Colors.grey.shade600,
         ),
       ),
     ],
   );
 }
}