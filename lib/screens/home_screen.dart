import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
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
                  // Resumo do mês
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
                  
                  // Gastos por categoria
                  _buildExpensesByCategory(),
                  const SizedBox(height: 24),
                  
                  // Transações recentes
                  _buildRecentTransactions(),
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
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios, size: 16),
                      onPressed: () => _selectPreviousMonth(),
                    ),
                    Text(
                      '${DateFormat('dd/MM/yyyy').format(currentMonth.startDate)} a ${DateFormat('dd/MM/yyyy').format(currentMonth.endDate)}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.arrow_forward_ios, size: 16),
                      onPressed: () => _selectNextMonth(),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _isMonthOpen(currentMonth) ? Colors.green : Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _isMonthOpen(currentMonth) ? 'ABERTO' : 'FECHADO',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (currentMonth.budget != null && currentMonth.budget! > 0) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getBudgetColor(currentMonth),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_getBudgetPercentage(currentMonth)}% do orçamento',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpensesByCategory() {
    return FutureBuilder<Map<String, double>>(
      future: context.read<FinanceProvider>().getExpensesByCategory(),
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
              child: Center(
                child: Text(
                  'Erro ao carregar dados: ${snapshot.error}',
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ),
          );
        }

        final expensesByCategory = snapshot.data ?? {};
        
        if (expensesByCategory.isEmpty) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: Text('Nenhuma despesa registrada neste mês'),
              ),
            ),
          );
        }

        return CategorySummaryCard(
          expensesByCategory: expensesByCategory,
          categories: context.read<FinanceProvider>().categories,
        );
      },
    );
  }

  Widget _buildRecentTransactions() {
    return RecentTransactionsCard(
      transactions: context.read<FinanceProvider>().transactions.take(5).toList(),
    );
  }

  // Métodos para seleção de mês
  Future<void> _selectMonth() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: context.read<FinanceProvider>().currentFinancialMonth?.startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('pt', 'BR'),
    );
    
    if (picked != null) {
      await context.read<FinanceProvider>().loadFinancialMonth(picked);
    }
  }

  Future<void> _selectPreviousMonth() async {
    final currentMonth = context.read<FinanceProvider>().currentFinancialMonth;
    if (currentMonth != null) {
      final previousMonth = currentMonth.previousMonth;
      await context.read<FinanceProvider>().loadFinancialMonth(previousMonth.startDate);
    }
  }

  Future<void> _selectNextMonth() async {
    final currentMonth = context.read<FinanceProvider>().currentFinancialMonth;
    if (currentMonth != null) {
      final nextMonth = currentMonth.nextMonth;
      if (nextMonth.startDate.isBefore(DateTime.now())) {
        await context.read<FinanceProvider>().loadFinancialMonth(nextMonth.startDate);
      }
    }
  }

  Color _getBudgetColor(models.FinancialMonth month) {
    if (month.isBudgetExceeded) {
      return Colors.red;
    } else if (month.isNearBudgetLimit) {
      return Colors.orange;
    } else {
      return Colors.green;
    }
  }

  double _getBudgetPercentage(models.FinancialMonth month) {
    if (month.budget != null && month.budget! > 0) {
      return (month.budgetUsagePercentage * 100).toDouble();
    }
    return 0.0;
  }

  bool _isMonthOpen(models.FinancialMonth month) {
    final now = DateTime.now();
    
    // Se o mês foi explicitamente fechado, está fechado
    if (month.isClosed) {
      return false;
    }
    
    // Se a data atual está dentro do período do mês financeiro, está aberto
    if (month.containsDate(now)) {
      return true;
    }
    
    // Se a data atual é posterior ao fim do mês financeiro, está fechado
    if (now.isAfter(month.endDate)) {
      return false;
    }
    
    // Se a data atual é anterior ao início do mês financeiro, está fechado
    if (now.isBefore(month.startDate)) {
      return false;
    }
    
    return true;
  }
} 