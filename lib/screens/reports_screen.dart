import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../providers/providers.dart';
import '../models/models.dart' as models;
import '../utils/utils.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  DateTime _selectedMonth = DateTime.now();
  bool _isLoading = true;
  
  // Dados dos relatórios
  Map<String, double> _expensesByCategory = {};
  List<models.Transaction> _monthlyTransactions = [];
  double _totalIncome = 0;
  double _totalExpenses = 0;
  double _balance = 0;

  @override
  void initState() {
    super.initState();
    // Carregar dados após o build inicial
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadReportData();
    });
  }

  Future<void> _loadReportData() async {
    setState(() => _isLoading = true);
    
    try {
      final provider = context.read<FinanceProvider>();
      
      // Carregar mês financeiro selecionado
      await provider.loadFinancialMonth(_selectedMonth);
      
      // Obter dados do mês
      final currentMonth = provider.currentFinancialMonth;
      if (currentMonth != null) {
        _totalIncome = currentMonth.totalIncome;
        _totalExpenses = currentMonth.totalExpenses;
        _balance = _totalIncome - _totalExpenses;
        
        // Obter gastos por categoria
        _expensesByCategory = await provider.getExpensesByCategory();
        
        // Obter transações do mês
        _monthlyTransactions = await provider.getFilteredTransactions();
      }
      
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar relatórios: $e')),
        );
      }
    }
  }

  Future<void> _selectMonth() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('pt', 'BR'),
    );
    
    if (picked != null && picked != _selectedMonth) {
      setState(() => _selectedMonth = picked);
      await _loadReportData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Relatórios'),
        actions: [
          IconButton(
            onPressed: _selectMonth,
            icon: const Icon(Icons.calendar_today),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadReportData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Cabeçalho do mês
                  _buildMonthHeader(),
                  const SizedBox(height: 24),
                  
                  // Resumo financeiro
                  _buildFinancialSummary(),
                  const SizedBox(height: 24),
                  
                  // Gráfico de gastos por categoria
                  if (_expensesByCategory.isNotEmpty) ...[
                    _buildExpensesByCategoryChart(),
                    const SizedBox(height: 24),
                  ],
                  
                  // Lista de categorias com valores
                  if (_expensesByCategory.isNotEmpty) ...[
                    _buildCategoryBreakdown(),
                    const SizedBox(height: 24),
                  ],
                  
                  // Transações do mês
                  _buildMonthlyTransactions(),
                ],
              ),
            ),
    );
  }

  Widget _buildMonthHeader() {
    final monthName = DateFormat('MMMM yyyy', 'pt_BR').format(_selectedMonth);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.analytics, size: 32, color: Colors.blue),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Relatório de $monthName',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Mês Financeiro',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: _selectMonth,
              icon: const Icon(Icons.edit_calendar),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialSummary() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Resumo Financeiro',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    'Receitas',
                    Formatters.formatCurrency(_totalIncome),
                    Colors.green,
                    Icons.trending_up,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryCard(
                    'Despesas',
                    Formatters.formatCurrency(_totalExpenses),
                    Colors.red,
                    Icons.trending_down,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildSummaryCard(
              'Saldo',
              Formatters.formatCurrency(_balance),
              _balance >= 0 ? Colors.blue : Colors.orange,
              _balance >= 0 ? Icons.account_balance_wallet : Icons.warning,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpensesByCategoryChart() {
    if (_expensesByCategory.isEmpty) {
      return const SizedBox.shrink();
    }

    final totalExpenses = _expensesByCategory.values.reduce((a, b) => a + b);
    final sections = _expensesByCategory.entries.map((entry) {
      final percentage = (entry.value / totalExpenses) * 100;
      return PieChartSectionData(
        color: _getCategoryColor(entry.key),
        value: entry.value,
        title: '${percentage.toStringAsFixed(1)}%',
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Gastos por Categoria',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: sections,
                  centerSpaceRadius: 40,
                  sectionsSpace: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryBreakdown() {
    if (_expensesByCategory.isEmpty) {
      return const SizedBox.shrink();
    }

    final totalExpenses = _expensesByCategory.values.reduce((a, b) => a + b);
    final sortedCategories = _expensesByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Detalhamento por Categoria',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...sortedCategories.map((entry) {
              final percentage = (entry.value / totalExpenses) * 100;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: _getCategoryColor(entry.key),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.key,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          Text(
                            '${percentage.toStringAsFixed(1)}% do total',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      Formatters.formatCurrency(entry.value),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyTransactions() {
    if (_monthlyTransactions.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(Icons.receipt_long, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'Nenhuma transação neste mês',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Agrupar transações por dia
    final groupedTransactions = <DateTime, List<models.Transaction>>{};
    for (final transaction in _monthlyTransactions) {
      final date = DateTime(transaction.date.year, transaction.date.month, transaction.date.day);
      groupedTransactions.putIfAbsent(date, () => []).add(transaction);
    }

    final sortedDates = groupedTransactions.keys.toList()..sort((a, b) => b.compareTo(a));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Transações do Mês',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${_monthlyTransactions.length} transações',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...sortedDates.take(5).map((date) {
              final transactions = groupedTransactions[date]!;
              final dayTotal = transactions.fold<double>(
                0,
                (sum, t) => sum + (t.type == models.TransactionType.income ? t.amount : -t.amount),
              );

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        DateFormat('dd/MM/yyyy').format(date),
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      Text(
                        Formatters.formatCurrency(dayTotal.abs()),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: dayTotal >= 0 ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...transactions.take(3).map((transaction) => Padding(
                    padding: const EdgeInsets.only(left: 16, bottom: 4),
                    child: Row(
                      children: [
                        Icon(
                          transaction.type == models.TransactionType.income
                              ? Icons.trending_up
                              : Icons.trending_down,
                          size: 16,
                          color: transaction.type == models.TransactionType.income
                              ? Colors.green
                              : Colors.red,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            transaction.description,
                            style: const TextStyle(fontSize: 14),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          Formatters.formatCurrency(transaction.amount),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: transaction.type == models.TransactionType.income
                                ? Colors.green
                                : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  )),
                  if (transactions.length > 3)
                    Padding(
                      padding: const EdgeInsets.only(left: 16, top: 4),
                      child: Text(
                        '+${transactions.length - 3} mais',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                ],
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor(String categoryName) {
    // Cores padrão para categorias
    final colors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
      Colors.cyan,
      Colors.amber,
    ];

    // Gerar cor baseada no nome da categoria
    int hash = categoryName.hashCode;
    return colors[hash.abs() % colors.length];
  }
} 