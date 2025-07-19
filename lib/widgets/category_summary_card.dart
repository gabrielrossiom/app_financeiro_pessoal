import 'package:flutter/material.dart';
import '../models/models.dart' as models;
import '../utils/utils.dart';

class CategorySummaryCard extends StatelessWidget {
  final Map<String, double> expensesByCategory;
  final List<models.Category> categories;

  const CategorySummaryCard({
    super.key,
    required this.expensesByCategory,
    required this.categories,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalExpenses = expensesByCategory.values.fold(0.0, (sum, value) => sum + value);
    
    // Ordenar categorias por valor gasto (maior para menor)
    final sortedCategories = expensesByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Gastos por Categoria',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  Formatters.formatCurrency(totalExpenses),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Lista de categorias
            ...sortedCategories.take(5).map((entry) {
              final categoryName = entry.key;
              final amount = entry.value;
              final percentage = totalExpenses > 0 ? (amount / totalExpenses) * 100.0 : 0.0;
              
              // Encontrar a categoria correspondente
              final category = categories.firstWhere(
                (cat) => cat.name == categoryName,
                orElse: () => models.Category(
                  name: categoryName,
                  icon: '📁',
                  color: '#9E9E9E',
                ),
              );

              return _buildCategoryItem(
                context,
                category,
                amount,
                percentage,
                totalExpenses,
              );
            }),
            
            // Mostrar "ver mais" se houver mais de 5 categorias
            if (sortedCategories.length > 5) ...[
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: () {
                    // TODO: Navegar para tela de relatórios detalhados
                  },
                  child: Text(
                    'Ver mais ${sortedCategories.length - 5} categorias',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryItem(
    BuildContext context,
    models.Category category,
    double amount,
    double percentage,
    double totalExpenses,
  ) {
    final theme = Theme.of(context);
    final color = _parseColor(category.color);
    
    // Calcular se está próximo ou excedeu o orçamento
    final budget = category.monthlyBudget ?? 0;
    final budgetUsage = budget > 0 ? (amount / budget) * 100.0 : 0.0;
    final isOverBudget = budgetUsage > 100;
    final isNearBudget = budgetUsage >= 80 && budgetUsage <= 100;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          // Ícone da categoria
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                category.icon,
                style: const TextStyle(fontSize: 20),
              ),
            ),
          ),
          const SizedBox(width: 12),
          
          // Informações da categoria
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        category.name,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (budget > 0) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isOverBudget 
                            ? Colors.red.withValues(alpha: 0.1)
                            : isNearBudget 
                              ? Colors.orange.withValues(alpha: 0.1)
                              : Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${budgetUsage.toStringAsFixed(0)}%',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isOverBudget 
                              ? Colors.red 
                              : isNearBudget 
                                ? Colors.orange 
                                : Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Expanded(
                      child: LinearProgressIndicator(
                        value: (percentage / 100.0).toDouble(),
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                        minHeight: 4,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      Formatters.formatPercentage(percentage),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          
          // Valor
          Text(
            Formatters.formatCurrency(amount),
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Color _parseColor(String hexColor) {
    try {
      hexColor = hexColor.replaceAll('#', '');
      if (hexColor.length == 6) {
        hexColor = 'FF$hexColor';
      }
      return Color(int.parse(hexColor, radix: 16));
    } catch (e) {
      return Colors.grey;
    }
  }
} 