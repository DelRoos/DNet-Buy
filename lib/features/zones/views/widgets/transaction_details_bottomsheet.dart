import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:dnet_buy/features/transactions/models/transaction_model.dart';

class TransactionDetailsBottomSheet extends StatelessWidget {
  final TransactionModel transaction;
  final VoidCallback? onCancelReservation;
  final VoidCallback? onRefresh;

  const TransactionDetailsBottomSheet({
    super.key,
    required this.transaction,
    this.onCancelReservation,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
        minHeight: MediaQuery.of(context).size.height * 0.6,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          _buildHandle(),

          // Header
          _buildHeader(),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                  if (_shouldShowPaymentInfo()) ...[
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
                          _buildInfoRow(
                              'Message', transaction.providerMessage!),
                      ],
                    ),
                  ],

                  // Credentials (si disponibles)
                  if (transaction.hasCredentials) ...[
                    const SizedBox(height: 20),
                    _buildCredentialsSection(),
                  ],

                  // Actions disponibles
                  if (_hasAvailableActions()) ...[
                    const SizedBox(height: 20),
                    _buildActionsSection(),
                  ],

                  // Informations techniques
                  if (_shouldShowTechnicalInfo()) ...[
                    const SizedBox(height: 20),
                    _buildSection(
                      'Informations Techniques',
                      Icons.settings,
                      [
                        if (transaction.externalId != null)
                          _buildInfoRow('ID Externe', transaction.externalId!),
                        if (transaction.reservedTicketId != null)
                          _buildInfoRow('ID Ticket Réservé',
                              transaction.reservedTicketId!),
                      ],
                    ),
                  ],

                  // Espacement pour les actions flottantes
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),

          // Actions du bas
          _buildBottomActions(),
        ],
      ),
    );
  }

  Widget _buildHandle() {
    return Container(
      margin: const EdgeInsets.only(top: 12, bottom: 8),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Détails de la Transaction',
                  style: Get.textTheme.titleLarge?.copyWith(
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
          if (onRefresh != null)
            IconButton(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh),
              tooltip: 'Actualiser',
            ),
          IconButton(
            onPressed: () => Get.back(),
            icon: const Icon(Icons.close),
            tooltip: 'Fermer',
          ),
        ],
      ),
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

  Widget _buildActionsSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.settings, color: Colors.blue.shade700, size: 20),
              const SizedBox(width: 8),
              Text(
                'Actions disponibles',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Bouton annuler réservation
          if (_canCancelReservation()) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _confirmCancelReservation(),
                icon: const Icon(Icons.cancel_outlined),
                label: const Text('Annuler la réservation'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade600,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Cette action libérera le ticket pour d\'autres clients',
              style: TextStyle(
                color: Colors.orange.shade700,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Row(
        children: [
          if (transaction.hasCredentials)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _copyCredentials,
                icon: const Icon(Icons.copy),
                label: const Text('Copier credentials'),
              ),
            ),
          if (transaction.hasCredentials && _canCancelReservation())
            const SizedBox(width: 12),
          if (_canCancelReservation())
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _confirmCancelReservation(),
                icon: const Icon(Icons.cancel_outlined),
                label: const Text('Annuler réservation'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade600,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Méthodes utilitaires
  bool _shouldShowPaymentInfo() {
    return transaction.freemopayReference != null ||
        transaction.isManualSale ||
        transaction.provider != 'freemopay';
  }

  bool _shouldShowTechnicalInfo() {
    return transaction.externalId != null ||
        transaction.reservedTicketId != null;
  }

  bool _hasAvailableActions() {
    return _canCancelReservation();
  }

  bool _canCancelReservation() {
    return (transaction.status == TransactionStatus.pending ||
            transaction.status == TransactionStatus.created) &&
        onCancelReservation != null;
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

  void _confirmCancelReservation() {
    Get.dialog(
      AlertDialog(
        title: const Text('Annuler la réservation'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Êtes-vous sûr de vouloir annuler cette réservation ?'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Montant: ${transaction.formattedAmount}'),
                  Text('Client: ${transaction.buyerPhoneNumber}'),
                  Text('Forfait: ${transaction.planName}'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Le ticket sera libéré et pourra être vendu à un autre client.',
              style: TextStyle(
                color: Colors.orange.shade700,
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              onCancelReservation?.call();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade600,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }
}
