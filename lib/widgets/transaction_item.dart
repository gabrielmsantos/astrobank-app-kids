import 'package:flutter/material.dart';
import '../models/transaction_model.dart';
import '../theme/app_colors.dart';

class TransactionItem extends StatelessWidget {
  final Transaction transaction;
  final VoidCallback? onTap;
  final bool isLast;

  const TransactionItem({
    super.key,
    required this.transaction,
    this.onTap,
    this.isLast = false,
  });

  Color _getTransactionColor() {
    final isDebit = transaction.nature.toLowerCase() == 'debit';
    return isDebit ? Colors.red : AppColors.successGreen;
  }

  bool _isDebit() {
    return transaction.nature.toLowerCase() == 'debit';
  }

  String _formatAmount() {
    try {
      // Get absolute value for display
      final amountValue = double.parse(transaction.value).abs();
      final absoluteAmount = amountValue.toStringAsFixed(2);
      
      // Debits show as negative (-$XX.XX), Credits show as positive (+$XX.XX)
      if (_isDebit()) {
        return '-\$${absoluteAmount}';
      } else {
        return '+\$${absoluteAmount}';
      }
    } catch (e) {
      // Fallback
      if (_isDebit()) {
        return '-\$${transaction.value}';
      } else {
        return '+\$${transaction.value}';
      }
    }
  }

  IconData _getTransactionIcon() {
    switch (transaction.type.toLowerCase()) {
      case 'deposit':
        return Icons.arrow_downward;
      case 'withdraw':
        return Icons.arrow_upward;
      case 'transfer':
        return Icons.swap_horiz;
      case 'purchase':
        return Icons.shopping_bag;
      case 'payment':
        return Icons.payment;
      case 'fee':
        return Icons.receipt;
      default:
        return Icons.attach_money;
    }
  }

  Widget _getCreditDebitFlag() {
    final isCredit = transaction.nature.toLowerCase() == 'credit';
    final flagText = isCredit ? 'C' : 'D';
    final flagColor = isCredit ? Colors.green : Colors.red;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: flagColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        flagText,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : Border(
                  bottom: BorderSide(
                    color: AppColors.borderGray.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _getTransactionColor().withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _getTransactionIcon(),
                color: _getTransactionColor(),
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textDark,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        transaction.formattedDate,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textGray,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _getCreditDebitFlag(),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              _formatAmount(),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: _getTransactionColor(),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
