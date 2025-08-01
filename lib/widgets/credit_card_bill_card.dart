import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/models.dart';
import '../utils/formatters.dart';

class CreditCardBillCard extends StatelessWidget {
  final CreditCardInvoice invoice;
  final VoidCallback? onViewTransactions;
  final VoidCallback? onCloseBill;
  final bool isLoading;

  const CreditCardBillCard({
    super.key,
    required this.invoice,
    this.onViewTransactions,
    this.onCloseBill,
    this.isLoading = false,
  });

  Color _getStatusColor(InvoiceStatus status) {
    switch (status) {
      case InvoiceStatus.aberta:
        return Colors.green;
      case InvoiceStatus.fechada:
        return Colors.grey;
      case InvoiceStatus.prevista:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isClosed = invoice.status == InvoiceStatus.fechada;
    final isPrevisao = invoice.status == InvoiceStatus.prevista;
    final isAberta = invoice.status == InvoiceStatus.aberta;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Cartão de Crédito',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(invoice.status),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    invoice.status.name.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'R\$ ${invoice.amount.toStringAsFixed(2)}',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: invoice.amount == 0 ? Colors.grey : Colors.red[700],
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Período: ${invoice.startDate.day.toString().padLeft(2, '0')}/${invoice.startDate.month.toString().padLeft(2, '0')}/${invoice.startDate.year} a ${invoice.endDate.day.toString().padLeft(2, '0')}/${invoice.endDate.month.toString().padLeft(2, '0')}/${invoice.endDate.year}',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.7)),
            ),
            const SizedBox(height: 10),
            
            // Botões de ação superiores
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onViewTransactions,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.primary,
                      side: BorderSide(color: theme.colorScheme.primary),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Ver transações', style: TextStyle(fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: isAberta && onCloseBill != null
                      ? ElevatedButton(
                          onPressed: isLoading ? null : onCloseBill,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red[700],
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: isLoading
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Text('Fechar Fatura', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        )
                      : isClosed
                          ? ElevatedButton(
                              onPressed: () => context.go('/add-transaction/creditCardPayment'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text('Pagar Fatura', style: TextStyle(fontSize: 12)),
                            )
                          : const SizedBox.shrink(),
                ),
              ],
            ),
            const SizedBox(height: 6),
            
            // Botão de nova compra com destaque
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => context.go('/add-transaction/creditCardPurchase'),
                icon: const Icon(Icons.shopping_cart, size: 18),
                label: const Text('Nova Compra no Cartão', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 