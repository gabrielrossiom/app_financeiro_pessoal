import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/providers.dart';
import '../models/models.dart' as models;
import '../utils/utils.dart';
import 'package:go_router/go_router.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  
  models.TransactionType _selectedType = models.TransactionType.expenseAccount;
  models.RecurrenceType? _selectedRecurrence;
  String? _selectedCategory;
  DateTime _selectedDate = DateTime.now();
  int _installments = 1;
  models.Transaction? _editingTransaction;

  List<models.Category> _categories = [];

  @override
  void initState() {
    super.initState();
    _loadCategories();
    // Detectar se está editando
    Future.microtask(() {
      final args = GoRouter.of(context).routerDelegate.currentConfiguration.extra;
      if (args is models.Transaction) {
        setState(() {
          _editingTransaction = args;
          _descriptionController.text = args.description;
          _amountController.text = args.amount.toStringAsFixed(2);
          _selectedType = args.type;
          _selectedCategory = args.category;
          _selectedDate = args.date;
          _selectedRecurrence = args.recurrenceType;
          _installments = args.installments ?? 1;
        });
      }
    });
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final provider = context.read<FinanceProvider>();
      final categories = await provider.getCategories();
      setState(() {
        _categories = categories;
        if (_categories.isNotEmpty && _selectedCategory == null) {
          _selectedCategory = _categories.first.id;
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar categorias: $e')),
        );
      }
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('pt', 'BR'),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _saveTransaction() async {
    if (!_formKey.currentState!.validate()) return;
    // Validação de categoria só para tipos que exigem
    if ((_selectedType == models.TransactionType.expenseAccount || _selectedType == models.TransactionType.creditCardPurchase) && _selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione uma categoria')),
      );
      return;
    }

    try {
      final amount = double.parse(_amountController.text.replaceAll(',', '.'));
      final provider = context.read<FinanceProvider>();
      models.Transaction transaction;
      // Criação conforme o tipo
      if (_selectedType == models.TransactionType.expenseAccount) {
        transaction = models.Transaction.expenseAccount(
          description: _descriptionController.text.trim(),
          amount: amount,
          category: _selectedCategory!,
          date: _selectedDate,
          recurrenceType: _selectedRecurrence!,
        );
      } else if (_selectedType == models.TransactionType.incomeAccount) {
        transaction = models.Transaction.incomeAccount(
          description: _descriptionController.text.trim(),
          amount: amount,
          date: _selectedDate,
          recurrenceType: _selectedRecurrence!,
        );
      } else if (_selectedType == models.TransactionType.creditCardPayment) {
        transaction = models.Transaction.creditCardPayment(
          description: _descriptionController.text.trim(),
          amount: amount,
          date: _selectedDate,
        );
      } else if (_selectedType == models.TransactionType.creditCardPurchase) {
        transaction = models.Transaction.creditCardPurchase(
          description: _descriptionController.text.trim(),
          amount: amount,
          category: _selectedCategory!,
          date: _selectedDate,
          recurrenceType: _selectedRecurrence!,
          installments: _selectedRecurrence == models.RecurrenceType.parcelada ? _installments : null,
        );
      } else {
        throw Exception('Tipo de transação inválido');
      }

      if (_editingTransaction != null) {
        // Atualizar transação existente
        final updated = transaction.copyWith(id: _editingTransaction!.id);
        await provider.updateTransaction(updated);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Transação atualizada com sucesso!')),
          );
          context.go('/transactions');
        }
        return;
      }

      await provider.addTransaction(transaction);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transação adicionada com sucesso!')),
        );
        context.go('/transactions');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar transação: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nova Transação'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Tipo de transação
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tipo de Transação',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      children: [
                        ChoiceChip(
                          label: Text(models.TransactionType.expenseAccount.displayName),
                          selected: _selectedType == models.TransactionType.expenseAccount,
                          onSelected: (_) {
                            setState(() {
                              _selectedType = models.TransactionType.expenseAccount;
                              _selectedRecurrence = null;
                            });
                          },
                        ),
                        ChoiceChip(
                          label: Text(models.TransactionType.incomeAccount.displayName),
                          selected: _selectedType == models.TransactionType.incomeAccount,
                          onSelected: (_) {
                            setState(() {
                              _selectedType = models.TransactionType.incomeAccount;
                              _selectedRecurrence = null;
                            });
                          },
                        ),
                        ChoiceChip(
                          label: Text(models.TransactionType.creditCardPayment.displayName),
                          selected: _selectedType == models.TransactionType.creditCardPayment,
                          onSelected: (_) {
                            setState(() {
                              _selectedType = models.TransactionType.creditCardPayment;
                              _selectedRecurrence = null;
                            });
                          },
                        ),
                        ChoiceChip(
                          label: Text(models.TransactionType.creditCardPurchase.displayName),
                          selected: _selectedType == models.TransactionType.creditCardPurchase,
                          onSelected: (_) {
                            setState(() {
                              _selectedType = models.TransactionType.creditCardPurchase;
                              _selectedRecurrence = null;
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Descrição
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Descrição',
                prefixIcon: Icon(Icons.description, size: 20),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Digite uma descrição';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Valor
            TextFormField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Valor',
                prefixIcon: Icon(Icons.attach_money, size: 20),
                prefixText: 'R\$ ',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Digite um valor';
                }
                final amount = double.tryParse(value.replaceAll(',', '.'));
                if (amount == null || amount <= 0) {
                  return 'Digite um valor válido';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Categoria (apenas para despesa em conta e compra em cartão)
            if (_selectedType == models.TransactionType.expenseAccount || _selectedType == models.TransactionType.creditCardPurchase) ...[
              const Text('Categoria', style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              Container(
                height: 48,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: _categories.map((category) {
                    return DropdownMenuItem(
                      value: category.id,
                      child: Row(
                        children: [
                          Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: Color(int.parse(category.color.replaceAll('#', '0xFF'))),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(category.name),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCategory = value;
                    });
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Data
            const Text('Data', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Container(
              height: 48,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: InkWell(
                onTap: _selectDate,
                borderRadius: BorderRadius.circular(8),
                child: Row(
                  children: [
                    const SizedBox(width: 12),
                    const Icon(Icons.calendar_today, size: 20),
                    const SizedBox(width: 12),
                    Text(
                      DateFormat('dd/MM/yyyy').format(_selectedDate),
                      style: const TextStyle(fontSize: 16),
                    ),
                    const Spacer(),
                    const Icon(Icons.arrow_drop_down, size: 20),
                    const SizedBox(width: 12),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Recorrência (só exibe se não estiver editando)
            if (_editingTransaction == null) ...[
              if ((_selectedType == models.TransactionType.expenseAccount ||
                  _selectedType == models.TransactionType.incomeAccount) &&
                  _selectedType != models.TransactionType.creditCardPurchase) ...[
                const Text('Recorrência', style: TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                DropdownButtonFormField<models.RecurrenceType>(
                  value: _selectedRecurrence,
                  items: models.RecurrenceType.values
                      .where((r) => r != models.RecurrenceType.parcelada)
                      .map((recurrence) => DropdownMenuItem(
                            value: recurrence,
                            child: Text(recurrence.displayName),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedRecurrence = value;
                    });
                  },
                  decoration: const InputDecoration(
                    labelText: 'Recorrência',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null) {
                      return 'Selecione a recorrência';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
              ],
              if (_selectedType == models.TransactionType.creditCardPurchase) ...[
                const Text('Recorrência', style: TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                DropdownButtonFormField<models.RecurrenceType>(
                  value: _selectedRecurrence,
                  items: models.RecurrenceType.values
                      .map((recurrence) => DropdownMenuItem(
                            value: recurrence,
                            child: Text(recurrence.displayName),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedRecurrence = value;
                    });
                  },
                  decoration: const InputDecoration(
                    labelText: 'Recorrência',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null) {
                      return 'Selecione a recorrência';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
              ],
            ],

            // Parcelas (apenas se for compra em cartão e recorrência parcelada)
            if (_selectedType == models.TransactionType.creditCardPurchase && _selectedRecurrence == models.RecurrenceType.parcelada) ...[
              const Text('Parcelas', style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              TextFormField(
                initialValue: '1',
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Número de parcelas',
                  prefixIcon: Icon(Icons.credit_card, size: 20),
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  _installments = int.tryParse(value) ?? 1;
                },
              ),
              const SizedBox(height: 16),
            ],

            const SizedBox(height: 32),

            // Botão salvar
            ElevatedButton(
              onPressed: _saveTransaction,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                'Salvar Transação',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 