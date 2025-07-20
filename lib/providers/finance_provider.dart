import 'package:flutter/foundation.dart';
import '../models/models.dart' as models;
import '../services/services.dart';

class FinanceProvider with ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  
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
      // Inserir transação principal
      await _databaseService.insertTransaction(transaction);
      
      // Se for parcelada, criar as parcelas
      if (transaction.installments != null && transaction.installments! > 1) {
        final installments = transaction.createInstallments();
        await _databaseService.insertTransactions(installments);
      }
      
      // Se for recorrente mensal, criar próxima recorrência
      if (transaction.recurrenceType == models.RecurrenceType.monthly) {
        final nextRecurrence = transaction.createNextRecurrence();
        if (nextRecurrence != null) {
          await _databaseService.insertTransaction(nextRecurrence);
        }
      }
      
      // Recarregar transações e atualizar totais do mês financeiro
      await _loadTransactions();
      await _updateFinancialMonthTotals();
      
      // Recarregar o mês financeiro do banco para garantir dados atualizados
      await _loadCurrentFinancialMonth();
      
      _error = null;
    } catch (e) {
      _error = 'Erro ao adicionar transação: $e';
      rethrow; // Re-throw para que a UI possa mostrar o erro
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
    models.PaymentMethod? paymentMethod,
  }) async {
    if (_currentFinancialMonth == null) return [];
    
    final transactions = await _databaseService.getTransactions(
      startDate: _currentFinancialMonth!.startDate,
      endDate: _currentFinancialMonth!.endDate,
      type: type,
      category: category,
      paymentMethod: paymentMethod,
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
} 