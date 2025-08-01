import 'package:flutter/material.dart';

class CreditCardBillCard extends StatelessWidget {
  final double amount;
  final DateTime startDate;
  final DateTime endDate;
  final VoidCallback? onCloseBill;
  final VoidCallback onViewTransactions;
  final bool isLoading;
  final String status; // 'FECHADA', 'ABERTA', 'PREVISAO'

  const CreditCardBillCard({
    super.key,
    required this.amount,
    required this.startDate,
    required this.endDate,
    this.onCloseBill,
    required this.onViewTransactions,
    this.isLoading = false,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isClosed = status == 'FECHADA';
    final isPrevisao = status == 'PREVISAO';
    final isAberta = status == 'ABERTA';
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Gastos com cartão de crédito',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isPrevisao
                        ? Colors.blue[100]
                        : isClosed
                            ? Colors.grey[300]
                            : Colors.green[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: isPrevisao
                          ? Colors.blue[800]
                          : isClosed
                              ? Colors.grey[800]
                              : Colors.green[800],
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'R\$ ${amount.toStringAsFixed(2)}',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: amount == 0 ? Colors.grey : Colors.red[700],
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Período: ${startDate.day.toString().padLeft(2, '0')}/${startDate.month.toString().padLeft(2, '0')}/${startDate.year} a ${endDate.day.toString().padLeft(2, '0')}/${endDate.month.toString().padLeft(2, '0')}/${endDate.year}',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.7)),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: onViewTransactions,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.colorScheme.primary,
                    side: BorderSide(color: theme.colorScheme.primary),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Ver transações'),
                ),
                const SizedBox(width: 8),
                if (isAberta && onCloseBill != null)
                ElevatedButton(
                  onPressed: isLoading ? null : onCloseBill,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[700],
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Fechar Fatura', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
} 