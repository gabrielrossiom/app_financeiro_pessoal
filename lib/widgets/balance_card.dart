import 'package:flutter/material.dart';
import '../utils/utils.dart';

class BalanceCard extends StatelessWidget {
  final double totalIncome;
  final double totalExpenses;
  final double balance;
  final double budget;
  final double remainingBudget;

  const BalanceCard({
    super.key,
    required this.totalIncome,
    required this.totalExpenses,
    required this.balance,
    required this.budget,
    required this.remainingBudget,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPositive = balance >= 0;
    final budgetUsage = budget > 0 ? (totalExpenses / budget) * 100 : 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Resumo do Mês',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Icon(
                  isPositive ? Icons.trending_up : Icons.trending_down,
                  color: isPositive ? Colors.green : Colors.red,
                  size: 24,
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Saldo principal
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Saldo',
                  style: theme.textTheme.titleMedium,
                ),
                Text(
                  Formatters.formatBalance(balance),
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isPositive ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Receitas e Despesas
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    context,
                    'Receitas',
                    Formatters.formatCurrency(totalIncome),
                    Colors.green,
                    Icons.arrow_upward,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildInfoItem(
                    context,
                    'Despesas',
                    Formatters.formatCurrency(totalExpenses),
                    Colors.red,
                    Icons.arrow_downward,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Barra de progresso do orçamento
            if (budget > 0) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Orçamento',
                    style: theme.textTheme.titleMedium,
                  ),
                  Text(
                    '${budgetUsage.toDouble().toStringAsFixed(1)}%',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: _getBudgetColor(budgetUsage.toDouble()),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: (budgetUsage / 100).toDouble(),
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(
                  _getBudgetColor(budgetUsage.toDouble()),
                ),
                minHeight: 8,
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Gasto: ${Formatters.formatCurrency(totalExpenses)}',
                    style: theme.textTheme.bodySmall,
                  ),
                  Text(
                    'Restante: ${Formatters.formatCurrency(remainingBudget)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: remainingBudget >= 0 ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(
    BuildContext context,
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 4),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Color _getBudgetColor(num usage) {
    if (usage >= 100) {
      return Colors.red;
    } else if (usage >= 80) {
      return Colors.orange;
    } else {
      return Colors.green;
    }
  }
} 