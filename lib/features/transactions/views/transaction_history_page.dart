import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dnet_buy/features/transactions/controllers/transaction_history_controller.dart';
import 'package:dnet_buy/features/transactions/models/transaction_model.dart';
import 'package:dnet_buy/features/transactions/views/widgets/transaction_list_item.dart';
import 'package:dnet_buy/shared/constants/app_constants.dart';

class TransactionHistoryPage extends GetView<TransactionHistoryController> {
  const TransactionHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(TransactionHistoryController());

    return Scaffold(
      appBar: AppBar(title: const Text('Historique des Transactions')),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              if (controller.allTransactions.isEmpty) {
                return const Center(
                  child: Text("Aucune transaction à afficher."),
                );
              }
              if (controller.filteredTransactions.isEmpty) {
                return const Center(
                  child: Text("Aucune transaction ne correspond à ce filtre."),
                );
              }
              return RefreshIndicator(
                onRefresh: controller.fetchTransactions,
                child: ListView.builder(
                  padding: const EdgeInsets.all(AppConstants.defaultPadding),
                  itemCount: controller.filteredTransactions.length,
                  itemBuilder: (_, index) {
                    final transaction = controller.filteredTransactions[index];
                    return TransactionListItem(
                      transaction: transaction,
                      statusColor: controller.getStatusColor(
                        transaction.status,
                      ),
                      statusIcon: controller.getStatusIcon(transaction.status),
                    );
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Obx(
        () => SegmentedButton<TransactionStatus?>(
          segments: const [
            ButtonSegment(value: null, label: Text('Tous')),
            ButtonSegment(
              value: TransactionStatus.success,
              label: Text('Succès'),
              icon: Icon(Icons.check),
            ),
            ButtonSegment(
              value: TransactionStatus.failed,
              label: Text('Échecs'),
              icon: Icon(Icons.close),
            ),
          ],
          selected: {controller.activeFilter.value},
          onSelectionChanged: (newSelection) {
            controller.applyFilter(newSelection.first);
          },
        ),
      ),
    );
  }
}
