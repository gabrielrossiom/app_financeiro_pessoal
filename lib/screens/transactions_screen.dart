import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/providers.dart';
import '../models/models.dart' as models;
import '../utils/utils.dart';
import 'package:go_router/go_router.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final _searchController = TextEditingController();
  models.TransactionType? _selectedType;
  String? _selectedCategory;
  // Removido filtro de método de pagamento
  
  List<models.Transaction> _transactions = [];
  List<models.Category> _categories = [];
  bool _isLoading = true;
  models.FinancialMonth? _selectedMonth;

  @override
  void initState() {
    super.initState();
    final provider = context.read<FinanceProvider>();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await provider.loadFinancialMonth(DateTime.now());
      setState(() {
        _selectedMonth = provider.currentFinancialMonth;
      });
      if (_selectedMonth != null) {
        await _loadDataForMonth(_selectedMonth!);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    final provider = context.read<FinanceProvider>();
    final categories = await provider.getCategories();
    final transactions = await provider.getTransactions();
    
    setState(() {
      _categories = categories;
      _transactions = transactions;
      _isLoading = false;
    });
  }

  Future<void> _loadDataForMonth(models.FinancialMonth month) async {
    setState(() => _isLoading = true);
    final provider = context.read<FinanceProvider>();
    await provider.loadFinancialMonth(month.startDate);
    final categories = await provider.getCategories();
    final transactions = await provider.getFilteredTransactions();
    setState(() {
      _categories = categories;
      _transactions = transactions;
      _isLoading = false;
    });
  }

  void _goToPreviousMonth() {
    if (_selectedMonth == null) return;
    final prevMonth = _selectedMonth!.previousMonth;
    setState(() {
      _selectedMonth = prevMonth;
    });
    _loadDataForMonth(prevMonth);
  }

  void _goToNextMonth() {
    if (_selectedMonth == null) return;
    final nextMonth = _selectedMonth!.nextMonth;
    setState(() {
      _selectedMonth = nextMonth;
    });
    _loadDataForMonth(nextMonth);
  }

  Future<void> _applyFilters() async {
    setState(() => _isLoading = true);
    
    final provider = context.read<FinanceProvider>();
    final transactions = await provider.getFilteredTransactions(
      type: _selectedType,
      category: _selectedCategory,
    );
    
    setState(() {
      _transactions = transactions;
      _isLoading = false;
    });
  }

  void _clearFilters() {
    setState(() {
      _selectedType = null;
      _selectedCategory = null;
      _searchController.clear();
    });
    _loadData();
  }

  List<models.Transaction> _getFilteredTransactions() {
    if (_searchController.text.isEmpty) {
      return _transactions;
    }
    
    return _transactions.where((transaction) {
      return transaction.description.toLowerCase().contains(
        _searchController.text.toLowerCase(),
      );
    }).toList();
  }

  void _showTransactionDetails(models.Transaction transaction) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _TransactionDetailsSheet(transaction: transaction),
    );
  }

  Future<void> _deleteTransaction(models.Transaction transaction) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar exclusão'),
        content: Text('Tem certeza que deseja excluir "${transaction.description}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final provider = context.read<FinanceProvider>();
        await provider.deleteTransaction(transaction.id);
        await _loadData();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Transação excluída com sucesso!')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao excluir: $e')),
          );
        }
      }
    }
  }

  models.Category? _findCategory(String? id) {
    try {
      return _categories.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredTransactions = _getFilteredTransactions();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transações'),
      ),
      body: Column(
        children: [
          // Campo de busca e filtros
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Buscar',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          // Navegação de meses financeiros centralizada
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: _goToPreviousMonth,
                ),
                Text(
                  _selectedMonth == null
                    ? ''
                    : DateFormat('dd/MM/yyyy').format(_selectedMonth!.startDate) +
                      ' a ' +
                      DateFormat('dd/MM/yyyy').format(_selectedMonth!.endDate),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: _goToNextMonth,
                ),
              ],
            ),
          ),

          // Filtros ativos
          if (_selectedType != null || _selectedCategory != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          if (_selectedType != null)
                            Chip(
                              label: Text(_selectedType!.displayName),
                              onDeleted: () {
                                setState(() => _selectedType = null);
                                _applyFilters();
                              },
                            ),
                          if (_selectedCategory != null)
                            Chip(
                              label: Text(_categories
                                  .firstWhere((c) => c.id == _selectedCategory)
                                  .name),
                              onDeleted: () {
                                setState(() => _selectedCategory = null);
                                _applyFilters();
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _clearFilters,
                    child: const Text('Limpar'),
                  ),
                ],
              ),
            ),

          // Lista de transações
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredTransactions.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.receipt_long, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'Nenhuma transação encontrada',
                              style: TextStyle(fontSize: 18, color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredTransactions.length,
                        itemBuilder: (context, index) {
                          final transaction = filteredTransactions[index];
                          final models.Category? category = _findCategory(transaction.category);

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Color(int.parse(category?.color.replaceAll('#', '0xFF') ?? '0xFF9E9E9E')),
                                child: Text(
                                  category?.icon ??
                                    (transaction.type == models.TransactionType.incomeAccount ? '💰' :
                                     transaction.type == models.TransactionType.creditCardPayment ? '💳' :
                                     '❓'),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              title: Text(
                                transaction.description,
                                style: const TextStyle(fontWeight: FontWeight.w500),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (category != null)
                                  Text(
                                      '${category.name} • ${transaction.type.displayName}',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                  Text(
                                    DateFormat('dd/MM/yyyy').format(transaction.date),
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                  if (transaction.installments != null && transaction.installments! > 1)
                                    Text(
                                      '${transaction.currentInstallment}/${transaction.installments} parcelas',
                                      style: TextStyle(
                                        color: Colors.orange[700],
                                        fontSize: 12,
                                      ),
                                    ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    Formatters.formatCurrency(transaction.amount),
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: transaction.type == models.TransactionType.incomeAccount
                                          ? Colors.green[700]
                                          : Colors.red[700],
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  PopupMenuButton<String>(
                                    icon: const Icon(Icons.more_vert, size: 20),
                                    padding: EdgeInsets.zero,
                                    onSelected: (value) async {
                                      if (value == 'edit') {
                                        context.go('/add-transaction', extra: transaction);
                                      } else if (value == 'delete') {
                                        final confirm = await showDialog<bool>(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: const Text('Excluir transação'),
                                            content: const Text('Tem certeza que deseja excluir esta transação?'),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.of(context).pop(false),
                                                child: const Text('Cancelar'),
                                              ),
                                              TextButton(
                                                onPressed: () => Navigator.of(context).pop(true),
                                                child: const Text('Excluir'),
                                              ),
                                            ],
                                          ),
                                        );
                                        if (confirm == true) {
                                          await _deleteTransaction(transaction);
                                          await _loadDataForMonth(_selectedMonth!);
                                        }
                                      }
                                    },
                                    itemBuilder: (context) => [
                                      const PopupMenuItem(
                                        value: 'edit',
                                        child: ListTile(
                                          leading: Icon(Icons.edit, size: 18),
                                          title: Text('Editar'),
                                        ),
                                      ),
                                      const PopupMenuItem(
                                        value: 'delete',
                                        child: ListTile(
                                          leading: Icon(Icons.delete, size: 18),
                                          title: Text('Excluir'),
                                        ),
                                      ),
                                    ],
                                    ),
                                ],
                              ),
                              onTap: () => _showTransactionDetails(transaction),
                              onLongPress: () => _deleteTransaction(transaction),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),

    );
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _FilterBottomSheet(
        selectedType: _selectedType,
        selectedCategory: _selectedCategory,
        categories: _categories,
        onApply: (type, category) {
          setState(() {
            _selectedType = type;
            _selectedCategory = category;
          });
          _applyFilters();
          Navigator.of(context).pop();
        },
      ),
    );
  }
}

class _FilterBottomSheet extends StatefulWidget {
  final models.TransactionType? selectedType;
  final String? selectedCategory;
  final List<models.Category> categories;
  final Function(models.TransactionType?, String?) onApply;

  const _FilterBottomSheet({
    required this.selectedType,
    required this.selectedCategory,
    required this.categories,
    required this.onApply,
  });

  @override
  State<_FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<_FilterBottomSheet> {
  late models.TransactionType? _selectedType;
  late String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.selectedType;
    _selectedCategory = widget.selectedCategory;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Filtros',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Tipo de transação
          const Text('Tipo', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              FilterChip(
                label: const Text('Todas'),
                selected: _selectedType == null,
                onSelected: (selected) {
                  setState(() => _selectedType = null);
                },
              ),
              ...models.TransactionType.values.map((type) => FilterChip(
                label: Text(type.displayName),
                selected: _selectedType == type,
                onSelected: (selected) {
                  setState(() => _selectedType = selected ? type : null);
                },
              )),
            ],
          ),
          const SizedBox(height: 16),

          // Categoria
          const Text('Categoria', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedCategory,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Todas as categorias',
            ),
            items: [
              const DropdownMenuItem(value: null, child: Text('Todas as categorias')),
              ...widget.categories.map((category) => DropdownMenuItem(
                value: category.id,
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Color(int.parse(category.color.replaceAll('#', '0xFF'))),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(category.name),
                  ],
                ),
              )),
            ],
            onChanged: (value) {
              setState(() => _selectedCategory = value);
            },
          ),
          const SizedBox(height: 24),

          // Botões
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _selectedType = null;
                      _selectedCategory = null;
                    });
                  },
                  child: const Text('Limpar'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    widget.onApply(_selectedType, _selectedCategory);
                  },
                  child: const Text('Aplicar'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _TransactionDetailsSheet extends StatelessWidget {
  final models.Transaction transaction;

  const _TransactionDetailsSheet({required this.transaction});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                transaction.description,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          _DetailRow('Valor', Formatters.formatCurrency(transaction.amount)),
          _DetailRow('Tipo', transaction.type.displayName),
          _DetailRow('Categoria', transaction.category ?? '-'),
          _DetailRow('Data', DateFormat('dd/MM/yyyy').format(transaction.date)),
          if (transaction.recurrenceType != models.RecurrenceType.unica)
            _DetailRow('Recorrência', transaction.recurrenceType?.displayName ?? '-'),
          if (transaction.installments != null && transaction.installments! > 1) ...[
            _DetailRow('Parcelas', '${transaction.currentInstallment}/${transaction.installments}'),
            _DetailRow('Valor da parcela', Formatters.formatCurrency(transaction.amount / transaction.installments!)),
          ],
          
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
} 