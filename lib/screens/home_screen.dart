import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/providers.dart';
import '../utils/utils.dart';
import '../models/models.dart' as models;
import '../widgets/balance_card.dart';
import '../widgets/category_summary_card.dart';
import '../widgets/recent_transactions_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Carregar dados quando a tela for criada
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FinanceProvider>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Controle Financeiro'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // TODO: Implementar notificações
            },
          ),
        ],
      ),
      body: Consumer<FinanceProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Erro ao carregar dados',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    provider.error!,
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.initialize(),
                    child: const Text('Tentar Novamente'),
                  ),
                ],
              ),
            );
          }

          final currentMonth = provider.currentFinancialMonth;
          if (currentMonth == null) {
            return const Center(
              child: Text('Nenhum mês financeiro encontrado'),
            );
          }

          return RefreshIndicator(
            onRefresh: () => provider.initialize(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Cabeçalho do mês
                  _buildMonthHeader(currentMonth),
                  const SizedBox(height: 24),
                  
                  // Card de saldo
                  BalanceCard(
                    totalIncome: currentMonth.totalIncome,
                    totalExpenses: currentMonth.totalExpenses,
                    balance: currentMonth.balance,
                    budget: currentMonth.budget,
                    remainingBudget: currentMonth.remainingBudget,
                  ),
                  const SizedBox(height: 24),
                  
                  // Resumo por categoria
                  _buildCategorySummary(provider),
                  const SizedBox(height: 24),
                  
                  // Transações recentes
                  RecentTransactionsCard(
                    transactions: provider.transactions.take(5).toList(),
                  ),
                  const SizedBox(height: 24),
                  
                  // Ações rápidas
                  _buildQuickActions(context),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMonthHeader(models.FinancialMonth currentMonth) {
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
                  'Mês Financeiro',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () {
                    // TODO: Implementar seletor de mês
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              Formatters.formatFinancialMonthPeriod(
                currentMonth.startDate,
                currentMonth.endDate,
              ),
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  currentMonth.isClosed ? Icons.lock : Icons.lock_open,
                  size: 16,
                  color: currentMonth.isClosed ? Colors.red : Colors.green,
                ),
                const SizedBox(width: 4),
                Text(
                  currentMonth.isClosed ? 'Mês Fechado' : 'Mês Aberto',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: currentMonth.isClosed ? Colors.red : Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySummary(FinanceProvider provider) {
    return FutureBuilder<Map<String, double>>(
      future: provider.getExpensesByCategory(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        if (snapshot.hasError) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Erro ao carregar categorias: ${snapshot.error}'),
            ),
          );
        }

        final expensesByCategory = snapshot.data ?? {};
        
        if (expensesByCategory.isEmpty) {
          return Card(
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Nenhuma despesa registrada neste mês'),
            ),
          );
        }

        return CategorySummaryCard(
          expensesByCategory: expensesByCategory,
          categories: provider.categories,
        );
      },
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ações Rápidas',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(context, '/add-transaction');
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Nova Transação'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(context, '/categories');
                    },
                    icon: const Icon(Icons.category),
                    label: const Text('Categorias'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(context, '/reports');
                    },
                    icon: const Icon(Icons.bar_chart),
                    label: const Text('Relatórios'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(context, '/settings');
                    },
                    icon: const Icon(Icons.settings),
                    label: const Text('Configurações'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
} 