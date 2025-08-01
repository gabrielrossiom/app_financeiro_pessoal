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
  models.AppSettings? _appSettings;
  List<models.CreditCardInvoice> _creditCardInvoices = [];
  bool _isLoading = false;
  String? _error;
  bool _needsInitialSetup = false;

  // Getters
  List<models.Transaction> get transactions => _transactions;
  List<models.Category> get categories => _categories;
  List<models.CreditCard> get creditCards => _creditCards;
  List<models.FinancialMonth> get financialMonths => _financialMonths;
  models.FinancialMonth? get currentFinancialMonth => _currentFinancialMonth;
  models.AppSettings? get appSettings => _appSettings;
  List<models.CreditCardInvoice> get creditCardInvoices => _creditCardInvoices;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get needsInitialSetup => _needsInitialSetup;

  // Inicialização
  Future<void> initialize() async {
    _setLoading(true);
    try {
      await _loadAppSettings();
      
      // Verificar se precisa de configuração inicial
      if (_appSettings == null) {
        _needsInitialSetup = true;
        notifyListeners();
        return;
      }
      
      await _loadCategories();
      await _loadCreditCards();
      await _loadCurrentFinancialMonth();
      await _loadTransactions();
      await _loadCreditCardInvoices();
      await _ensureCreditCardInvoices();
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
      // Carregar todas as transações, sem limitar por data
      final transactions = await _databaseService.getTransactions();
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
      await _updateInvoiceAmounts();
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
      await _updateInvoiceAmounts();
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
      await _updateInvoiceAmounts();
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

  // Métodos para Configurações do App
  Future<void> _loadAppSettings() async {
    _appSettings = await _databaseService.getAppSettings();
    notifyListeners();
  }

  Future<void> saveInitialSettings(int closingDay) async {
    final now = DateTime.now();
    final settings = models.AppSettings(
      id: const Uuid().v4(),
      creditCardClosingDay: closingDay,
      createdAt: now,
      updatedAt: now,
    );
    
    await _databaseService.insertAppSettings(settings);
    _appSettings = settings;
    _needsInitialSetup = false;
    
    // Criar faturas iniciais
    await _createInitialInvoices(closingDay);
    
    // Carregar dados após configuração inicial
    await _loadCategories();
    await _loadCreditCards();
    await _loadCurrentFinancialMonth();
    await _loadTransactions();
    
    notifyListeners();
  }

  Future<void> _createInitialInvoices(int closingDay) async {
    final now = DateTime.now();
    final invoices = <models.CreditCardInvoice>[];
    
    // Criar a primeira fatura como ABERTA
    final firstInvoice = models.CreditCardInvoice.fromClosingDay(now, closingDay, isFirstInvoice: true);
    invoices.add(firstInvoice);
    
    // Criar 29 faturas PREVISTA adicionais
    DateTime currentStart = firstInvoice.endDate.add(const Duration(days: 1));
    for (int i = 0; i < 29; i++) {
      final nextInvoice = models.CreditCardInvoice.fromStartDate(currentStart, closingDay);
      invoices.add(nextInvoice);
      currentStart = nextInvoice.endDate.add(const Duration(days: 1));
    }
    
    // Salvar todas as faturas
    for (final invoice in invoices) {
      await _databaseService.insertCreditCardInvoice(invoice);
    }
    
    _creditCardInvoices = invoices;
    notifyListeners();
  }

  Future<void> _loadCreditCardInvoices() async {
    _creditCardInvoices = await _databaseService.getCreditCardInvoices();
    notifyListeners();
  }

  Future<void> _ensureCreditCardInvoices() async {
    if (_appSettings == null) return;
    
    final count = await _databaseService.getCreditCardInvoicesCount();
    if (count < 30) {
      // Criar faturas adicionais se necessário
      await _createAdditionalInvoices();
    }
  }

  Future<void> _createAdditionalInvoices() async {
    if (_creditCardInvoices.isEmpty) return;
    
    final now = DateTime.now();
    final invoices = <models.CreditCardInvoice>[];
    
    // Pegar a última fatura como referência
    final lastInvoice = _creditCardInvoices.last;
    DateTime currentStart = lastInvoice.endDate.add(const Duration(days: 1));
    
    // Criar faturas até ter 30 no total
    final neededCount = 30 - _creditCardInvoices.length;
    for (int i = 0; i < neededCount; i++) {
      final nextInvoice = models.CreditCardInvoice.fromStartDate(currentStart, _appSettings!.creditCardClosingDay);
      invoices.add(nextInvoice);
      currentStart = nextInvoice.endDate.add(const Duration(days: 1));
    }
    
    // Salvar as novas faturas
    for (final invoice in invoices) {
      await _databaseService.insertCreditCardInvoice(invoice);
    }
    
    _creditCardInvoices.addAll(invoices);
    notifyListeners();
  }

  Future<void> closeCreditCardInvoice(String invoiceId) async {
    final invoiceIndex = _creditCardInvoices.indexWhere((i) => i.id == invoiceId);
    if (invoiceIndex == -1) return;
    
    final invoice = _creditCardInvoices[invoiceIndex];
    if (invoice.status != models.InvoiceStatus.aberta) return;
    
    final now = DateTime.now();
    final closingDate = now.subtract(const Duration(days: 1));
    
    // Atualizar a fatura atual para FECHADA
    final updatedInvoice = invoice.close(closingDate);
    
    await _databaseService.updateCreditCardInvoice(updatedInvoice);
    _creditCardInvoices[invoiceIndex] = updatedInvoice;
    
    // Atualizar a próxima fatura para ABERTA
    if (invoiceIndex + 1 < _creditCardInvoices.length) {
      final nextInvoice = _creditCardInvoices[invoiceIndex + 1];
      final updatedNextInvoice = nextInvoice.open(closingDate.add(const Duration(days: 1)));
      
      await _databaseService.updateCreditCardInvoice(updatedNextInvoice);
      _creditCardInvoices[invoiceIndex + 1] = updatedNextInvoice;
    }
    
    notifyListeners();
  }

  // Método para obter faturas que se sobrepõem ao mês financeiro atual
  List<models.CreditCardInvoice> getInvoicesForCurrentMonth() {
    if (_currentFinancialMonth == null) return [];
    
    return _creditCardInvoices.where((invoice) {
      return invoice.overlapsWithPeriod(_currentFinancialMonth!.startDate, _currentFinancialMonth!.endDate);
    }).toList();
  }

  // Método para atualizar os valores das faturas baseado nas transações
  Future<void> _updateInvoiceAmounts() async {
    for (int i = 0; i < _creditCardInvoices.length; i++) {
      final invoice = _creditCardInvoices[i];
      
      // Calcular o valor da fatura baseado nas transações
      final transactions = _transactions.where((t) =>
        t.type == models.TransactionType.creditCardPurchase &&
        invoice.containsDate(t.date)
      ).toList();
      
      final amount = transactions.fold(0.0, (sum, t) => sum + t.amount);
      
      if (amount != invoice.amount) {
        final updatedInvoice = invoice.updateAmount(amount);
        await _databaseService.updateCreditCardInvoice(updatedInvoice);
        _creditCardInvoices[i] = updatedInvoice;
      }
    }
    
    notifyListeners();
  }

  // Método público para verificar se há configurações
  Future<bool> hasAppSettings() async {
    return await _databaseService.hasAppSettings();
  }

  // Método público para limpar todos os dados do banco de dados (apenas para testes)
  Future<void> deleteAllData() async {
    await _databaseService.deleteAllData();
    _needsInitialSetup = true;
    _appSettings = null;
    _creditCardInvoices = [];
    notifyListeners();
  }
} 