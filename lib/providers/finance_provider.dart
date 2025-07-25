import 'package:flutter/foundation.dart';
import '../models/models.dart' as models;
import '../services/services.dart';
import 'package:uuid/uuid.dart';

class FinanceProvider with ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();

  // Função auxiliar para criar datas válidas ao somar meses
  DateTime _safeDate(int year, int month, int day) {
    final lastDay = DateTime(year, month + 1, 0).day;
    return DateTime(year, month, day > lastDay ? lastDay : day);
  }
  
  // Estado atual
  List<models.Transaction> _transactions = [];
  List<models.Category> _categories = [];
  List<models.CreditCard> _creditCards = [];
  final List<models.FinancialMonth> _financialMonths = [];
  models.FinancialMonth? _currentFinancialMonth;
  bool _isLoading = false;
  String? _error;

  // Getters
  List<models.Transaction> get transactions => _transactions;
  List<models.Category> get categories => _categories;
  List<models.CreditCard> get creditCards => _creditCards;
  List<models.FinancialMonth> get financialMonths => _financialMonths;
  models.FinancialMonth? get currentFinancialMonth => _currentFinancialMonth;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Inicialização
  Future<void> initialize() async {
    _setLoading(true);
    try {
      await _loadCategories();
      await _loadCreditCards();
      await _loadCurrentFinancialMonth();
      await _loadTransactions();
      _error = null;
    } catch (e) {
      _error = 'Erro ao inicializar: $e';
    } finally {
      _setLoading(false);
    }
  }

  // Carregar categorias
  Future<void> _loadCategories() async {
    _categories = await _databaseService.getCategories();
    notifyListeners();
  }

  // Carregar cartões de crédito
  Future<void> _loadCreditCards() async {
    _creditCards = await _databaseService.getCreditCards();
    notifyListeners();
  }

  // Carregar mês financeiro atual
  Future<void> _loadCurrentFinancialMonth() async {
    _currentFinancialMonth = await _databaseService.getFinancialMonthByDate(DateTime.now());
    
    if (_currentFinancialMonth == null) {
      // Criar novo mês financeiro se não existir
      _currentFinancialMonth = models.FinancialMonth.currentMonth;
      await _databaseService.insertFinancialMonth(_currentFinancialMonth!);
    }
    
    notifyListeners();
  }

  // Carregar transações
  Future<void> _loadTransactions() async {
    try {
      // Carregar todas as transações do mês atual
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
      
      final transactions = await _databaseService.getTransactions(
        startDate: startOfMonth,
        endDate: endOfMonth,
      );
      
      _transactions = transactions;
      notifyListeners();
    } catch (e) {
      _error = 'Erro ao carregar transações: $e';
      notifyListeners();
    }
  }

  // Adicionar transação
  Future<void> addTransaction(models.Transaction transaction) async {
    _setLoading(true);
    try {
      final List<models.Transaction> toInsert = [];
      final now = DateTime.now();
      // Lógica para recorrência mensal até dezembro
      if ((transaction.type == models.TransactionType.expenseAccount ||
           transaction.type == models.TransactionType.incomeAccount ||
           transaction.type == models.TransactionType.creditCardPurchase)
          && transaction.recurrenceType == models.RecurrenceType.recorrente) {
        // Cria uma transação para cada mês até dezembro
        DateTime data = transaction.date;
        while (data.year == now.year && data.month <= 12) {
          toInsert.add(transaction.copyWith(id: Uuid().v4(), date: data));
          data = _safeDate(data.year, data.month + 1, data.day);
        }
      }
      // Lógica para compra parcelada
      else if (transaction.type == models.TransactionType.creditCardPurchase && transaction.recurrenceType == models.RecurrenceType.parcelada && transaction.installments != null && transaction.installments! > 1) {
        final valorParcela = transaction.amount / transaction.installments!;
        for (int i = 0; i < transaction.installments!; i++) {
          final parcelaDate = _safeDate(transaction.date.year, transaction.date.month + i, transaction.date.day);
          toInsert.add(transaction.copyWith(
            id: Uuid().v4(),
            amount: valorParcela,
            date: parcelaDate,
            currentInstallment: i + 1,
            parentTransactionId: transaction.id,
          ));
        }
      }
      // Caso padrão: transação única ou compra em cartão não parcelada
      else {
        toInsert.add(transaction);
      }
      // Inserir todas as transações
      for (final t in toInsert) {
        await _databaseService.insertTransaction(t);
      }
      // Recarregar transações e atualizar totais do mês financeiro
      await _loadTransactions();
      await _updateFinancialMonthTotals();
      await _loadCurrentFinancialMonth();
      _error = null;
    } catch (e) {
      _error = 'Erro ao adicionar transação: $e';
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // Atualizar transação
  Future<void> updateTransaction(models.Transaction transaction) async {
    _setLoading(true);
    try {
      await _databaseService.updateTransaction(transaction);
      await _loadTransactions();
      await _updateFinancialMonthTotals();
      await _loadCurrentFinancialMonth();
      _error = null;
    } catch (e) {
      _error = 'Erro ao atualizar transação: $e';
    } finally {
      _setLoading(false);
    }
  }

  // Excluir transação
  Future<void> deleteTransaction(String id) async {
    _setLoading(true);
    try {
      await _databaseService.deleteTransaction(id);
      await _loadTransactions();
      await _updateFinancialMonthTotals();
      await _loadCurrentFinancialMonth();
      _error = null;
    } catch (e) {
      _error = 'Erro ao excluir transação: $e';
    } finally {
      _setLoading(false);
    }
  }

  // Adicionar categoria
  Future<void> addCategory(models.Category category) async {
    _setLoading(true);
    try {
      await _databaseService.insertCategory(category);
      await _loadCategories();
      _error = null;
    } catch (e) {
      _error = 'Erro ao adicionar categoria: $e';
    } finally {
      _setLoading(false);
    }
  }

  // Atualizar categoria
  Future<void> updateCategory(models.Category category) async {
    _setLoading(true);
    try {
      await _databaseService.updateCategory(category);
      await _loadCategories();
      _error = null;
    } catch (e) {
      _error = 'Erro ao atualizar categoria: $e';
    } finally {
      _setLoading(false);
    }
  }

  // Excluir categoria
  Future<void> deleteCategory(String id) async {
    _setLoading(true);
    try {
      await _databaseService.deleteCategory(id);
      await _loadCategories();
      _error = null;
    } catch (e) {
      _error = 'Erro ao excluir categoria: $e';
    } finally {
      _setLoading(false);
    }
  }

  // Adicionar cartão de crédito
  Future<void> addCreditCard(models.CreditCard creditCard) async {
    _setLoading(true);
    try {
      await _databaseService.insertCreditCard(creditCard);
      await _loadCreditCards();
      _error = null;
    } catch (e) {
      _error = 'Erro ao adicionar cartão: $e';
    } finally {
      _setLoading(false);
    }
  }

  // Atualizar cartão de crédito
  Future<void> updateCreditCard(models.CreditCard creditCard) async {
    _setLoading(true);
    try {
      await _databaseService.updateCreditCard(creditCard);
      await _loadCreditCards();
      _error = null;
    } catch (e) {
      _error = 'Erro ao atualizar cartão: $e';
    } finally {
      _setLoading(false);
    }
  }

  // Carregar mês financeiro específico
  Future<void> loadFinancialMonth(DateTime date) async {
    _setLoading(true);
    try {
      _currentFinancialMonth = await _databaseService.getFinancialMonthByDate(date);
      
      if (_currentFinancialMonth == null) {
        _currentFinancialMonth = models.FinancialMonth.fromDate(date);
        await _databaseService.insertFinancialMonth(_currentFinancialMonth!);
      }
      
      await _loadTransactions();
      _error = null;
    } catch (e) {
      _error = 'Erro ao carregar mês financeiro: $e';
    } finally {
      _setLoading(false);
    }
  }

  // Atualizar totais do mês financeiro
  Future<void> _updateFinancialMonthTotals() async {
    if (_currentFinancialMonth == null) return;

    try {
      // Calcular totais baseados nas transações do período
      final totalIncome = await _databaseService.getTotalIncome(
        _currentFinancialMonth!.startDate,
        _currentFinancialMonth!.endDate,
      );
      
      final totalExpenses = await _databaseService.getTotalExpenses(
        _currentFinancialMonth!.startDate,
        _currentFinancialMonth!.endDate,
      );

      // Atualizar o mês financeiro com os novos totais
      final updatedMonth = _currentFinancialMonth!.updateTotals(
        totalIncome: totalIncome,
        totalExpenses: totalExpenses,
      );

      // Salvar no banco de dados
      await _databaseService.updateFinancialMonth(updatedMonth);
      
      // Recarregar o mês financeiro do banco para garantir dados atualizados
      _currentFinancialMonth = await _databaseService.getFinancialMonthByDate(updatedMonth.startDate);
      
      // Notificar os listeners para atualizar a UI
      notifyListeners();
    } catch (e) {
      _error = 'Erro ao atualizar totais: $e';
      notifyListeners();
    }
  }

  // Obter gastos por categoria
  Future<Map<String, double>> getExpensesByCategory() async {
    if (_currentFinancialMonth == null) return {};
    
    return await _databaseService.getExpensesByCategory(
      _currentFinancialMonth!.startDate,
      _currentFinancialMonth!.endDate,
    );
  }

  // Obter transações filtradas
  Future<List<models.Transaction>> getFilteredTransactions({
    models.TransactionType? type,
    String? category,
  }) async {
    if (_currentFinancialMonth == null) return [];
    
    final transactions = await _databaseService.getTransactions(
      startDate: _currentFinancialMonth!.startDate,
      endDate: _currentFinancialMonth!.endDate,
      type: type,
      category: category,
    );
    return transactions;
  }

  // Obter todas as transações
  Future<List<models.Transaction>> getTransactions() async {
    return await _databaseService.getTransactions();
  }

  // Obter todas as categorias
  Future<List<models.Category>> getCategories() async {
    return await _databaseService.getCategories();
  }

  // Obter categoria por nome
  models.Category? getCategoryByName(String name) {
    try {
      return _categories.firstWhere((category) => category.name == name);
    } catch (e) {
      return null;
    }
  }

  // Obter cartão por nome
  models.CreditCard? getCreditCardByName(String name) {
    try {
      return _creditCards.firstWhere((card) => card.name == name);
    } catch (e) {
      return null;
    }
  }

  // Limpar erro
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Definir loading
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Fechar conexões
  @override
  Future<void> dispose() async {
    await _databaseService.close();
    super.dispose();
  }

  // Fechar fatura do cartão de crédito
  Future<void> closeCreditCardInvoice(String creditCardId) async {
    await _databaseService.insertCreditCardClosing(creditCardId, DateTime.now());
    notifyListeners();
  }

  // Obter período da fatura em aberto
  Future<Map<String, DateTime>> getCurrentCreditCardInvoicePeriod(String creditCardId) async {
    return await _databaseService.getCurrentInvoicePeriod(creditCardId);
  }

  // Obter transações do cartão de crédito da fatura em aberto
  Future<List<models.Transaction>> getCurrentCreditCardInvoiceTransactions(String creditCardId) async {
    final period = await getCurrentCreditCardInvoicePeriod(creditCardId);
    return await _databaseService.getTransactions(
      startDate: period['start'],
      endDate: period['end'],
      type: models.TransactionType.creditCardPurchase,
    );
  }

  // Fechar fatura global do cartão de crédito (sem cartão)
  Future<void> closeGlobalCreditCardInvoice() async {
    final db = await _databaseService.database;
    await db.insert('credit_card_closings', {
      'id': const Uuid().v4(),
      'creditCardId': null,
      'closingDate': DateTime.now().millisecondsSinceEpoch,
    });
    notifyListeners();
  }

  // Obter período da fatura global (último fechamento até agora)
  Future<Map<String, DateTime>> getCurrentGlobalCreditCardInvoicePeriod() async {
    final db = await _databaseService.database;
    final result = await db.query(
      'credit_card_closings',
      orderBy: 'closingDate DESC',
      limit: 1,
    );
    final now = DateTime.now();
    if (result.isEmpty) {
      // Se nunca fechou, considerar desde o início do app
      return {'start': DateTime(now.year, now.month, 1), 'end': now};
    }
    final lastClosing = DateTime.fromMillisecondsSinceEpoch(result.first['closingDate'] as int);
    return {'start': lastClosing.add(const Duration(days: 1)), 'end': now};
  }

  // Obter período e status da fatura do cartão para um mês financeiro
  Future<Map<String, dynamic>> getCreditCardInvoiceForFinancialMonth(DateTime financialMonthStart, DateTime financialMonthEnd) async {
    final db = await _databaseService.database;
    // Buscar todos os fechamentos ordenados
    final closings = await db.query(
      'credit_card_closings',
      orderBy: 'closingDate ASC',
    );
    DateTime? lastClosingBeforeMonth;
    DateTime? closingInMonth;
    for (final row in closings) {
      final closingDate = DateTime.fromMillisecondsSinceEpoch(row['closingDate'] as int);
      if (closingDate.isBefore(financialMonthStart)) {
        lastClosingBeforeMonth = closingDate;
      } else if (closingDate.isAfter(financialMonthStart.subtract(const Duration(days: 1))) && closingDate.isBefore(financialMonthEnd.add(const Duration(days: 1)))) {
        closingInMonth = closingDate;
        break;
      }
    }
    // Se houve fechamento dentro do mês financeiro, a fatura está fechada
    if (closingInMonth != null) {
      // Período: do último fechamento antes do mês até o fechamento dentro do mês
      final start = (lastClosingBeforeMonth != null) ? lastClosingBeforeMonth.add(const Duration(days: 1)) : financialMonthStart;
      final end = closingInMonth;
      final txs = _transactions.where((t) =>
        t.type == models.TransactionType.creditCardPurchase &&
        t.date.isAfter(start.subtract(const Duration(days: 1))) &&
        t.date.isBefore(end.add(const Duration(days: 1)))
      ).toList();
      return {
        'status': 'FECHADA',
        'start': start,
        'end': end,
        'transactions': txs,
      };
    } else {
      // Fatura em aberto: do último fechamento até o fim do mês financeiro
      final start = (lastClosingBeforeMonth != null) ? lastClosingBeforeMonth.add(const Duration(days: 1)) : financialMonthStart;
      final end = financialMonthEnd;
      final txs = _transactions.where((t) =>
        t.type == models.TransactionType.creditCardPurchase &&
        t.date.isAfter(start.subtract(const Duration(days: 1))) &&
        t.date.isBefore(end.add(const Duration(days: 1)))
      ).toList();
      return {
        'status': 'ABERTA',
        'start': start,
        'end': end,
        'transactions': txs,
      };
    }
  }
} 