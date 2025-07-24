import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/providers.dart';
import '../utils/utils.dart';
import '../models/models.dart' as models;
import '../widgets/balance_card.dart';
import '../widgets/category_summary_card.dart';
import '../widgets/recent_transactions_card.dart';
import '../widgets/credit_card_bill_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  models.FinancialMonth? _selectedMonth;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentMonth();
  }

  Future<void> _loadCurrentMonth() async {
    final provider = context.read<FinanceProvider>();
    await provider.loadFinancialMonth(DateTime.now());
    setState(() {
      _selectedMonth = provider.currentFinancialMonth;
      _isLoading = false;
    });
  }

  Future<void> _loadMonth(models.FinancialMonth month) async {
    setState(() => _isLoading = true);
    final provider = context.read<FinanceProvider>();
    await provider.loadFinancialMonth(month.startDate);
    setState(() {
      _selectedMonth = provider.currentFinancialMonth;
      _isLoading = false;
    });
  }

  void _goToPreviousMonth() {
    if (_selectedMonth == null) return;
    final prevMonth = _selectedMonth!.previousMonth;
    _loadMonth(prevMonth);
  }

  void _goToNextMonth() {
    if (_selectedMonth == null) return;
    final nextMonth = _selectedMonth!.nextMonth;
    _loadMonth(nextMonth);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FinanceProvider>();
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final currentMonth = _selectedMonth;
    if (currentMonth == null) {
      return const Scaffold(
        body: Center(child: Text('Nenhum mês financeiro encontrado')),
      );
    }

    // Calcular período da fatura (igual ao mês financeiro)
    final billStart = currentMonth.startDate;
    final billEnd = currentMonth.endDate;

    // Calcular valor da fatura em aberto (soma das compras no cartão no período)
    final creditCardPurchases = provider.transactions.where((t) =>
      t.type == models.TransactionType.creditCardPurchase &&
      t.date.isAfter(billStart.subtract(const Duration(days: 1))) &&
      t.date.isBefore(billEnd.add(const Duration(days: 1)))
    );
    final billAmount = creditCardPurchases.fold<double>(0, (sum, t) => sum + t.amount);

    void closeBill() {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Funcionalidade de fechamento de fatura será implementada futuramente.')),
      );
    }

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
      body: RefreshIndicator(
        onRefresh: _loadCurrentMonth,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Card de seleção de período
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        onPressed: _goToPreviousMonth,
                      ),
                      Text(
                        '${DateFormat('dd/MM/yyyy').format(currentMonth.startDate)} a ${DateFormat('dd/MM/yyyy').format(currentMonth.endDate)}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: _goToNextMonth,
                      ),
                    ],
                  ),
                ),
              ),
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
              // Card de gastos com cartão de crédito (agora depois do resumo do mês)
              CreditCardBillCard(
                amount: billAmount,
                startDate: billStart,
                endDate: billEnd,
                onCloseBill: closeBill,
                onViewTransactions: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                    builder: (context) {
                      final faturaTransacoes = provider.transactions.where((t) =>
                        t.type == models.TransactionType.creditCardPurchase &&
                        t.date.isAfter(billStart.subtract(const Duration(days: 1))) &&
                        t.date.isBefore(billEnd.add(const Duration(days: 1)))
                      ).toList();
                      return DraggableScrollableSheet(
                        expand: false,
                        initialChildSize: 0.7,
                        minChildSize: 0.3,
                        maxChildSize: 0.95,
                        builder: (context, scrollController) => Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Transações da Fatura',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    '${DateFormat('dd/MM/yyyy').format(billStart)} a ${DateFormat('dd/MM/yyyy').format(billEnd)}',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: faturaTransacoes.isEmpty
                                ? const Center(child: Text('Nenhuma transação encontrada.'))
                                : ListView.builder(
                                    controller: scrollController,
                                    itemCount: faturaTransacoes.length,
                                    itemBuilder: (context, index) {
                                      final t = faturaTransacoes[index];
                                      return ListTile(
                                        title: Text(t.description),
                                        subtitle: Text(DateFormat('dd/MM/yyyy').format(t.date)),
                                        trailing: Text(
                                          'R\$ ${t.amount.toStringAsFixed(2)}',
                                          style: TextStyle(
                                            color: Colors.red[700],
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 24),
              // Gastos por categoria
              _buildExpensesByCategory(),
              const SizedBox(height: 24),
              // Transações recentes
              RecentTransactionsCard(transactions: provider.transactions),
            ],
          ),
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