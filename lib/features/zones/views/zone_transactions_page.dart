import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dnet_buy/features/zones/controllers/zone_transactions_controller.dart';
import 'package:dnet_buy/features/zones/views/widgets/zone_transaction_list_item.dart';
import 'package:dnet_buy/features/transactions/models/transaction_model.dart';

class ZoneTransactionsPage extends GetView<ZoneTransactionsController> {
  const ZoneTransactionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // Filtres et statistiques
          _buildFiltersSection(),

          // Liste des transactions
          Expanded(
            child: _buildTransactionsList(),
          ),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Transactions'),
          Text(
            controller.zoneName,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.normal,
            ),
          ),
        ],
      ),
      actions: [
        // Recherche
        IconButton(
          onPressed: _showSearchDialog,
          icon: const Icon(Icons.search),
          tooltip: 'Rechercher',
        ),
        // Menu d'actions
        PopupMenuButton<String>(
          onSelected: _handleMenuAction,
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'refresh',
              child: ListTile(
                leading: Icon(Icons.refresh),
                title: Text('Actualiser'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'clear_filters',
              child: ListTile(
                leading: Icon(Icons.clear_all),
                title: Text('Effacer les filtres'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'export',
              child: ListTile(
                leading: Icon(Icons.file_download),
                title: Text('Exporter'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFiltersSection() {
    return Container(
      color: Colors.grey.shade50,
      child: Column(
        children: [
          // Ligne de filtres
          _buildFiltersRow(),

          // Statistiques générales et filtrées
          Obx(() => _buildStatsRow()),
        ],
      ),
    );
  }

  Widget _buildFiltersRow() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Filtre statut
          Expanded(
            flex: 2,
            child: _buildStatusFilter(),
          ),
          const SizedBox(width: 12),

          // Filtre date
          Expanded(
            flex: 3,
            child: _buildDateFilter(),
          ),
          const SizedBox(width: 12),

          // Bouton effacer filtres
          _buildClearFiltersButton(),
        ],
      ),
    );
  }

  Widget _buildStatusFilter() {
    return Obx(() => Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
            color: Colors.white,
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<TransactionStatus?>(
              value: controller.selectedStatus.value,
              onChanged: controller.filterByStatus,
              isExpanded: true,
              hint: const Text('Statut'),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('Tous les statuts'),
                ),
                ...TransactionStatus.values.map((status) => DropdownMenuItem(
                      value: status,
                      child: Row(
                        children: [
                          Icon(
                            _getStatusIcon(status),
                            size: 16,
                            color: _getStatusColor(status),
                          ),
                          const SizedBox(width: 8),
                          Text(_getStatusText(status)),
                        ],
                      ),
                    )),
              ],
            ),
          ),
        ));
  }

  Widget _buildDateFilter() {
    return Obx(() => InkWell(
          onTap: _showDateFilterDialog,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
              color: Colors.white,
            ),
            child: Row(
              children: [
                Icon(Icons.date_range, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    controller
                        .formatDateRange(controller.selectedDateRange.value),
                    style: TextStyle(
                      color: controller.selectedDateRange.value != null
                          ? Colors.black87
                          : Colors.grey.shade600,
                    ),
                  ),
                ),
                if (controller.selectedDateRange.value != null)
                  Icon(Icons.close, size: 16, color: Colors.grey.shade600),
              ],
            ),
          ),
        ));
  }

  Widget _buildClearFiltersButton() {
    return Obx(() {
      final hasFilters = controller.selectedStatus.value != null ||
          controller.selectedDateRange.value != null ||
          controller.searchQuery.value.isNotEmpty;

      return AnimatedOpacity(
        opacity: hasFilters ? 1.0 : 0.3,
        duration: const Duration(milliseconds: 200),
        child: IconButton(
          onPressed: hasFilters ? controller.clearFilters : null,
          icon: const Icon(Icons.filter_alt_off),
          tooltip: 'Effacer les filtres',
          style: IconButton.styleFrom(
            backgroundColor:
                hasFilters ? Colors.red.shade50 : Colors.grey.shade100,
            foregroundColor:
                hasFilters ? Colors.red.shade600 : Colors.grey.shade400,
          ),
        ),
      );
    });
  }

  Widget _buildStatsRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Row(
        children: [
          // Nombre total (général)
          Expanded(
            child: _buildStatItem(
              'Total général',
              '${controller.generalStats.value.totalCount}',
              Icons.receipt_long,
              Colors.blue,
            ),
          ),

          Container(
            width: 1,
            height: 30,
            color: Colors.grey.shade300,
          ),

          // Résultats filtrés
          Expanded(
            child: _buildStatItem(
              'Filtrés',
              '${controller.filteredStats.value.filteredCount}',
              Icons.filter_list,
              Colors.orange,
            ),
          ),

          Container(
            width: 1,
            height: 30,
            color: Colors.grey.shade300,
          ),

          // Montant total général
          Expanded(
            child: _buildStatItem(
              'Revenus',
              controller
                  .formatAmount(controller.generalStats.value.totalAmount),
              Icons.payments,
              Colors.green,
            ),
          ),

          Container(
            width: 1,
            height: 30,
            color: Colors.grey.shade300,
          ),

          // Répartition par statut (générale)
          Expanded(
            flex: 2,
            child: _buildStatusStats(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
      String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusStats() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildStatusStat(TransactionStatus.completed, Colors.green),
        _buildStatusStat(TransactionStatus.failed, Colors.red),
        _buildStatusStat(TransactionStatus.pending, Colors.blue),
      ],
    );
  }

  Widget _buildStatusStat(TransactionStatus status, Color color) {
    final count = controller.generalStats.value.statusCounts[status] ?? 0;

    return Column(
      children: [
        Icon(
          _getStatusIcon(status),
          size: 14,
          color: color,
        ),
        const SizedBox(height: 2),
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionsList() {
    return Obx(() {
      if (controller.isLoading.value && controller.transactions.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }

      if (controller.transactions.isEmpty) {
        return _buildEmptyState();
      }

      return RefreshIndicator(
        onRefresh: controller.refreshTransactions,
        child: ListView.builder(
          controller: controller.scrollController,
          padding: const EdgeInsets.all(16),
          itemCount: controller.transactions.length +
              (controller.isLoadingMore.value ? 1 : 0),
          itemBuilder: (context, index) {
            // Indicateur de chargement automatique en bas
            if (index == controller.transactions.length) {
              return controller.isLoadingMore.value
                  ? const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : const SizedBox.shrink();
            }

            final transaction = controller.transactions[index];
            return ZoneTransactionListItem(
              transaction: transaction,
              onTap: () => controller.showTransactionDetails(transaction),
              onRefresh: () => controller.refreshTransaction(transaction),
            );
          },
        ),
      );
    });
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Aucune transaction',
            style: Get.textTheme.headlineSmall?.copyWith(
              color: Colors.grey.shade600,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _getEmptyStateMessage(),
            style: Get.textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          if (_hasActiveFilters()) ...[
            ElevatedButton.icon(
              onPressed: controller.clearFilters,
              icon: const Icon(Icons.clear_all),
              label: const Text('Effacer les filtres'),
            ),
          ] else ...[
            ElevatedButton.icon(
              onPressed: controller.refreshTransactions,
              icon: const Icon(Icons.refresh),
              label: const Text('Actualiser'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return Obx(() => FloatingActionButton(
          onPressed: controller.isRefreshing.value
              ? null
              : controller.refreshTransactions,
          child: controller.isRefreshing.value
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.refresh),
        ));
  }

  // Méthodes utilitaires
  Color _getStatusColor(TransactionStatus status) {
    switch (status) {
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

  IconData _getStatusIcon(TransactionStatus status) {
    switch (status) {
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

  String _getStatusText(TransactionStatus status) {
    switch (status) {
      case TransactionStatus.created:
        return 'Créées';
      case TransactionStatus.pending:
        return 'En attente';
      case TransactionStatus.completed:
        return 'Terminées';
      case TransactionStatus.failed:
        return 'Échouées';
      case TransactionStatus.expired:
        return 'Expirées';
    }
  }

  String _getEmptyStateMessage() {
    if (controller.selectedStatus.value != null ||
        controller.selectedDateRange.value != null ||
        controller.searchQuery.value.isNotEmpty) {
      return 'Aucune transaction ne correspond aux filtres sélectionnés';
    }
    return 'Aucune transaction trouvée pour cette zone';
  }

  bool _hasActiveFilters() {
    return controller.selectedStatus.value != null ||
        controller.selectedDateRange.value != null ||
        controller.searchQuery.value.isNotEmpty;
  }

  void _showSearchDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('Rechercher'),
        content: TextField(
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Téléphone, ID, référence...',
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: controller.search,
          controller: TextEditingController(text: controller.searchQuery.value),
        ),
        actions: [
          TextButton(
            onPressed: () {
              controller.search('');
              Get.back();
            },
            child: const Text('Effacer'),
          ),
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _showDateFilterDialog() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filtrer par date',
              style: Get.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            // Raccourcis de dates
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: controller.getDateShortcuts().map<Widget>((shortcut) {
                return FilterChip(
                  label: Text(shortcut['label']),
                  selected: controller.selectedDateRange.value != null &&
                      _isDateRangeEqual(controller.selectedDateRange.value!,
                          shortcut['range']),
                  onSelected: (_) {
                    controller.filterByDateRange(shortcut['range']);
                    Get.back();
                  },
                );
              }).toList(),
            ),

            const SizedBox(height: 16),

            // Sélection personnalisée
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _showCustomDatePicker,
                    icon: const Icon(Icons.calendar_today),
                    label: const Text('Période personnalisée'),
                  ),
                ),
                const SizedBox(width: 12),
                if (controller.selectedDateRange.value != null)
                  ElevatedButton(
                    onPressed: () {
                      controller.filterByDateRange(null);
                      Get.back();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade50,
                      foregroundColor: Colors.red.shade700,
                    ),
                    child: const Text('Effacer'),
                  ),
              ],
            ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Get.back(),
                child: const Text('Fermer'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showCustomDatePicker() async {
    final picked = await showDateRangePicker(
      context: Get.context!,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      initialDateRange: controller.selectedDateRange.value,
    );

    if (picked != null) {
      controller.filterByDateRange(picked);
      Get.back();
    }
  }

  bool _isDateRangeEqual(DateTimeRange range1, DateTimeRange range2) {
    return range1.start.year == range2.start.year &&
        range1.start.month == range2.start.month &&
        range1.start.day == range2.start.day &&
        range1.end.year == range2.end.year &&
        range1.end.month == range2.end.month &&
        range1.end.day == range2.end.day;
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'refresh':
        controller.refreshTransactions();
        break;
      case 'clear_filters':
        controller.clearFilters();
        break;
      case 'export':
        // TODO: Implémenter l'export
        Get.snackbar(
          'À venir',
          'Fonctionnalité d\'export en cours de développement',
          snackPosition: SnackPosition.BOTTOM,
        );
        break;
    }
  }
}
