import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/providers.dart';
import '../utils/utils.dart';
import '../models/models.dart' as models;
import '../widgets/widgets.dart';
import 'package:uuid/uuid.dart';
import '../screens/settings_screen.dart';

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
    _checkInitialSetup();
  }

  Future<void> _checkInitialSetup() async {
    final provider = context.read<FinanceProvider>();
    
    // Aguardar a inicialização do provider
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Verificar se precisa de configuração inicial
    if (provider.needsInitialSetup) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          barrierDismissible: false,
          barrierColor: Colors.black54,
          builder: (context) => WillPopScope(
            onWillPop: () async => false,
            child: Dialog(
              child: const InitialSetupModal(),
            ),
          ),
        );
      });
    }
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
    
    // Se precisa de configuração inicial, mostrar tela de carregamento
    if (provider.needsInitialSetup) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Controle Financeiro'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
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
              // Card de gastos com cartão de crédito
              Consumer<FinanceProvider>(
                builder: (context, provider, child) {
                  final invoices = provider.getInvoicesForCurrentMonth();
                  
                  if (invoices.isEmpty) {
                    return const Card(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(child: Text('Nenhuma fatura encontrada para este mês.')),
                      ),
                    );
                  }
                  
                  return _CreditCardBillCarousel(
                    invoices: invoices,
                    provider: provider,
                  );
                },
              ),
              const SizedBox(height: 24),
              // Gastos por categoria
              _buildExpensesByCategory(),
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
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        if (snapshot.hasError) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(child: Text('Erro: ${snapshot.error}')),
            ),
          );
        }

        final expensesByCategory = snapshot.data ?? {};
        if (expensesByCategory.isEmpty) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: Text('Nenhum gasto registrado neste período.')),
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
}

class _CreditCardBillCarousel extends StatefulWidget {
  final List<models.CreditCardInvoice> invoices;
  final FinanceProvider provider;
  const _CreditCardBillCarousel({required this.invoices, required this.provider});

  @override
  State<_CreditCardBillCarousel> createState() => _CreditCardBillCarouselState();
}

class _CreditCardBillCarouselState extends State<_CreditCardBillCarousel> {
  int _currentPage = 0;
  final PageController _controller = PageController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 220,
          child: PageView.builder(
            controller: _controller,
            itemCount: widget.invoices.length,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemBuilder: (context, index) {
              final invoice = widget.invoices[index];
              
              return CreditCardBillCard(
                invoice: invoice,
                isLoading: false,
                onViewTransactions: () {
                  _showTransactionsModal(invoice);
                },
                onCloseBill: invoice.status == models.InvoiceStatus.aberta
                    ? () async {
                        await widget.provider.closeCreditCardInvoice(invoice.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Fatura fechada com sucesso!')),
                        );
                      }
                    : null,
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            widget.invoices.length,
            (index) => Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _currentPage == index ? Theme.of(context).colorScheme.primary : Colors.grey[400],
              ),
            ),
          ),
        ),
      ],
    );
  }



  void _showTransactionsModal(models.CreditCardInvoice invoice) {
    // Calcular o valor da fatura baseado nas transações
    final transactions = widget.provider.transactions.where((t) =>
      t.type == models.TransactionType.creditCardPurchase &&
      t.date.isAfter(invoice.startDate.subtract(const Duration(days: 1))) &&
      t.date.isBefore(invoice.endDate.add(const Duration(days: 1)))
    ).toList();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
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
                      '${invoice.startDate.day.toString().padLeft(2, '0')}/${invoice.startDate.month.toString().padLeft(2, '0')}/${invoice.startDate.year} a '
                      '${invoice.endDate.day.toString().padLeft(2, '0')}/${invoice.endDate.month.toString().padLeft(2, '0')}/${invoice.endDate.year}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: transactions.isEmpty
                    ? const Center(child: Text('Nenhuma transação encontrada.'))
                    : ListView.builder(
                        controller: scrollController,
                        itemCount: transactions.length,
                        itemBuilder: (context, idx) {
                          final t = transactions[idx];
                          return ListTile(
                            title: Text(t.description),
                            subtitle: Text('${t.date.day.toString().padLeft(2, '0')}/${t.date.month.toString().padLeft(2, '0')}/${t.date.year}'),
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
  }
} 