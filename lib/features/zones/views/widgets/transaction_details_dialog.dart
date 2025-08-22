import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:dnet_buy/features/transactions/models/transaction_model.dart';

class TransactionDetailsDialog extends StatelessWidget {
  final TransactionModel transaction;

  const TransactionDetailsDialog({
    super.key,
    required this.transaction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête
              _buildHeader(),

              const SizedBox(height: 24),

              // Badge de statut
              _buildStatusBadge(),

              const SizedBox(height: 24),

              // Informations principales
              _buildSection(
                'Informations Générales',
                Icons.info_outline,
                [
                  _buildInfoRow('ID Transaction', transaction.id,
                      copyable: true),
                  _buildInfoRow('Montant', transaction.formattedAmount),
                  _buildInfoRow('Forfait', transaction.planName),
                  _buildInfoRow('Durée', transaction.ticketTypeName),
                  _buildInfoRow('Client', transaction.buyerPhoneNumber,
                      copyable: true),
                  _buildInfoRow(
                      'Date création',
                      DateFormat('dd/MM/yyyy à HH:mm')
                          .format(transaction.createdAt)),
                  if (transaction.completedAt != null)
                    _buildInfoRow(
                        'Date completion',
                        DateFormat('dd/MM/yyyy à HH:mm')
                            .format(transaction.completedAt!)),
                ],
              ),

              // Informations de paiement
              if (transaction.freemopayReference != null ||
                  transaction.isManualSale ||
                  transaction.provider != 'freemopay') ...[
                const SizedBox(height: 20),
                _buildSection(
                  'Informations de Paiement',
                  Icons.payment,
                  [
                    _buildInfoRow('Fournisseur', _getProviderText()),
                    if (transaction.freemopayReference != null)
                      _buildInfoRow('Référence Freemopay',
                          transaction.freemopayReference!,
                          copyable: true),
                    if (transaction.isManualSale) ...[
                      _buildInfoRow('Type de vente', 'Vente manuelle'),
                      if (transaction.saleDescription != null)
                        _buildInfoRow(
                            'Description', transaction.saleDescription!),
                    ],
                    if (transaction.providerMessage != null)
                      _buildInfoRow('Message', transaction.providerMessage!),
                  ],
                ),
              ],

              // Credentials (si disponibles)
              if (transaction.hasCredentials) ...[
                const SizedBox(height: 20),
                _buildCredentialsSection(),
              ],

              // Informations techniques (si pertinentes)
              if (transaction.externalId != null ||
                  transaction.reservedTicketId != null) ...[
                const SizedBox(height: 20),
                _buildSection(
                  'Informations Techniques',
                  Icons.settings,
                  [
                    if (transaction.externalId != null)
                      _buildInfoRow('ID Externe', transaction.externalId!),
                    if (transaction.reservedTicketId != null)
                      _buildInfoRow(
                          'ID Ticket Réservé', transaction.reservedTicketId!),
                  ],
                ),
              ],

              const SizedBox(height: 32),

              // Actions
              _buildActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Détails de la Transaction',
                style: Get.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'ID: ${transaction.id.substring(0, 8)}...',
                style: Get.textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => Get.back(),
          icon: const Icon(Icons.close),
          style: IconButton.styleFrom(
            backgroundColor: Colors.grey.shade100,
            foregroundColor: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: _getStatusColor().withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _getStatusColor()),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_getStatusIcon(), size: 18, color: _getStatusColor()),
          const SizedBox(width: 8),
          Text(
            transaction.statusText,
            style: TextStyle(
              color: _getStatusColor(),
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, IconData icon, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.grey.shade700, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool copyable = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ),
                if (copyable) ...[
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () => _copyToClipboard(value, label),
                    child: Icon(
                      Icons.copy,
                      size: 16,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCredentialsSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.vpn_key, color: Colors.green.shade700, size: 20),
              const SizedBox(width: 8),
              Text(
                'Identifiants WiFi',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade700,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildCredentialRow(
              'Nom d\'utilisateur', transaction.credentials!.username),
          const SizedBox(height: 12),
          _buildCredentialRow(
              'Mot de passe', transaction.credentials!.password),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _copyCredentials,
              icon: const Icon(Icons.copy),
              label: const Text('Copier les identifiants'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCredentialRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.green.shade700,
            fontSize: 14,
          ),
        ),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.green.shade300),
              ),
              child: Text(
                value,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: () => _copyToClipboard(value, label),
              child: Icon(
                Icons.copy,
                size: 16,
                color: Colors.green.shade600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (transaction.hasCredentials)
          TextButton.icon(
            onPressed: _copyCredentials,
            icon: const Icon(Icons.copy),
            label: const Text('Copier credentials'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.green.shade600,
            ),
          ),
        const SizedBox(width: 12),
        ElevatedButton(
          onPressed: () => Get.back(),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey.shade600,
            foregroundColor: Colors.white,
          ),
          child: const Text('Fermer'),
        ),
      ],
    );
  }

  String _getProviderText() {
    if (transaction.isManualSale) {
      return 'Vente manuelle';
    }
    switch (transaction.provider) {
      case 'freemopay':
        return 'Freemopay';
      default:
        return transaction.provider.toUpperCase();
    }
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

  void _copyToClipboard(String value, String label) {
    Clipboard.setData(ClipboardData(text: value));
    Get.snackbar(
      'Copié',
      '$label copié dans le presse-papier',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green.shade100,
      colorText: Colors.green.shade800,
      duration: const Duration(seconds: 2),
    );
  }

  void _copyCredentials() {
    if (!transaction.hasCredentials) return;

    final credentials =
        'Nom d\'utilisateur: ${transaction.credentials!.username}\n'
        'Mot de passe: ${transaction.credentials!.password}';

    Clipboard.setData(ClipboardData(text: credentials));
    Get.snackbar(
      'Copié',
      'Identifiants copiés dans le presse-papier',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green.shade100,
      colorText: Colors.green.shade800,
      duration: const Duration(seconds: 2),
    );
  }
}
