import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/models.dart' as models;

class DatabaseService {
  static Database? _database;
  static const String _databaseName = 'financeiro_pessoal.db';
  static const int _databaseVersion = 1;

  // Singleton pattern
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, _databaseName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Tabela de categorias
    await db.execute('''
      CREATE TABLE categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        icon TEXT NOT NULL,
        color TEXT NOT NULL,
        monthlyBudget REAL,
        isActive INTEGER NOT NULL DEFAULT 1,
        createdAt INTEGER NOT NULL,
        updatedAt INTEGER NOT NULL
      )
    ''');

    // Tabela de cartões de crédito
    await db.execute('''
      CREATE TABLE credit_cards (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        bank TEXT NOT NULL,
        creditLimit REAL NOT NULL,
        closingDay INTEGER NOT NULL,
        dueDay INTEGER NOT NULL,
        isActive INTEGER NOT NULL DEFAULT 1,
        createdAt INTEGER NOT NULL,
        updatedAt INTEGER NOT NULL
      )
    ''');

    // Tabela de meses financeiros
    await db.execute('''
      CREATE TABLE financial_months (
        id TEXT PRIMARY KEY,
        startDate INTEGER NOT NULL,
        endDate INTEGER NOT NULL,
        totalIncome REAL NOT NULL DEFAULT 0,
        totalExpenses REAL NOT NULL DEFAULT 0,
        budget REAL NOT NULL DEFAULT 0,
        remainingBudget REAL NOT NULL DEFAULT 0,
        isClosed INTEGER NOT NULL DEFAULT 0,
        createdAt INTEGER NOT NULL,
        updatedAt INTEGER NOT NULL
      )
    ''');

    // Tabela de transações
    await db.execute('''
      CREATE TABLE transactions (
        id TEXT PRIMARY KEY,
        description TEXT NOT NULL,
        amount REAL NOT NULL,
        type INTEGER NOT NULL,
        paymentMethod INTEGER NOT NULL,
        category TEXT NOT NULL,
        date INTEGER NOT NULL,
        recurrenceType INTEGER NOT NULL DEFAULT 0,
        installments INTEGER,
        currentInstallment INTEGER,
        parentTransactionId TEXT,
        isRefundable INTEGER NOT NULL DEFAULT 0,
        refundAmount REAL,
        isRefunded INTEGER NOT NULL DEFAULT 0,
        createdAt INTEGER NOT NULL,
        updatedAt INTEGER NOT NULL,
        FOREIGN KEY (parentTransactionId) REFERENCES transactions (id)
      )
    ''');

    // Inserir categorias padrão
    await _insertDefaultCategories(db);
  }

  Future<void> _insertDefaultCategories(Database db) async {
    final defaultCategories = models.Category.defaultCategories;
    
    for (final category in defaultCategories) {
      await db.insert('categories', category.toMap());
    }
  }

  // Métodos para Categorias
  Future<List<models.Category>> getCategories() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('categories');
    return List.generate(maps.length, (i) => models.Category.fromMap(maps[i]));
  }

  Future<models.Category> insertCategory(models.Category category) async {
    final db = await database;
    await db.insert('categories', category.toMap());
    return category;
  }

  Future<int> updateCategory(models.Category category) async {
    final db = await database;
    return await db.update(
      'categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  Future<int> deleteCategory(String id) async {
    final db = await database;
    return await db.delete(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Métodos para Cartões de Crédito
  Future<List<models.CreditCard>> getCreditCards() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('credit_cards');
    return List.generate(maps.length, (i) => models.CreditCard.fromMap(maps[i]));
  }

  Future<models.CreditCard> insertCreditCard(models.CreditCard creditCard) async {
    final db = await database;
    await db.insert('credit_cards', creditCard.toMap());
    return creditCard;
  }

  Future<int> updateCreditCard(models.CreditCard creditCard) async {
    final db = await database;
    return await db.update(
      'credit_cards',
      creditCard.toMap(),
      where: 'id = ?',
      whereArgs: [creditCard.id],
    );
  }

  Future<int> deleteCreditCard(String id) async {
    final db = await database;
    return await db.delete(
      'credit_cards',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Métodos para Meses Financeiros
  Future<List<models.FinancialMonth>> getFinancialMonths() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'financial_months',
      orderBy: 'startDate DESC',
    );
    return List.generate(maps.length, (i) => models.FinancialMonth.fromMap(maps[i]));
  }

  Future<models.FinancialMonth?> getFinancialMonthByDate(DateTime date) async {
    final db = await database;
    final financialMonth = models.FinancialMonth.fromDate(date);
    
    final List<Map<String, dynamic>> maps = await db.query(
      'financial_months',
      where: 'startDate = ? AND endDate = ?',
      whereArgs: [
        financialMonth.startDate.millisecondsSinceEpoch,
        financialMonth.endDate.millisecondsSinceEpoch,
      ],
    );

    if (maps.isEmpty) return null;
    return models.FinancialMonth.fromMap(maps.first);
  }

  Future<models.FinancialMonth> insertFinancialMonth(models.FinancialMonth financialMonth) async {
    final db = await database;
    await db.insert('financial_months', financialMonth.toMap());
    return financialMonth;
  }

  Future<int> updateFinancialMonth(models.FinancialMonth financialMonth) async {
    final db = await database;
    return await db.update(
      'financial_months',
      financialMonth.toMap(),
      where: 'id = ?',
      whereArgs: [financialMonth.id],
    );
  }

  // Métodos para Transações
  Future<List<models.Transaction>> getTransactions({
    DateTime? startDate,
    DateTime? endDate,
    models.TransactionType? type,
    String? category,
    models.PaymentMethod? paymentMethod,
  }) async {
    final db = await database;
    
    String whereClause = '';
    List<dynamic> whereArgs = [];

    if (startDate != null && endDate != null) {
      whereClause += 'date >= ? AND date <= ?';
      whereArgs.addAll([
        startDate.millisecondsSinceEpoch,
        endDate.millisecondsSinceEpoch,
      ]);
    }

    if (type != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'type = ?';
      whereArgs.add(type.index);
    }

    if (category != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'category = ?';
      whereArgs.add(category);
    }

    if (paymentMethod != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'paymentMethod = ?';
      whereArgs.add(paymentMethod.index);
    }

    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where: whereClause.isEmpty ? null : whereClause,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'date DESC',
    );

    return List.generate(maps.length, (i) => models.Transaction.fromMap(maps[i]));
  }

  Future<List<models.Transaction>> getTransactionsByFinancialMonth(models.FinancialMonth financialMonth) async {
    return await getTransactions(
      startDate: financialMonth.startDate,
      endDate: financialMonth.endDate,
    );
  }

  Future<models.Transaction> insertTransaction(models.Transaction transaction) async {
    final db = await database;
    await db.insert('transactions', transaction.toMap());
    return transaction;
  }

  Future<List<models.Transaction>> insertTransactions(List<models.Transaction> transactions) async {
    final db = await database;
    final batch = db.batch();
    
    for (final transaction in transactions) {
      batch.insert('transactions', transaction.toMap());
    }
    
    await batch.commit();
    return transactions;
  }

  Future<int> updateTransaction(models.Transaction transaction) async {
    final db = await database;
    return await db.update(
      'transactions',
      transaction.toMap(),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }

  Future<int> deleteTransaction(String id) async {
    final db = await database;
    return await db.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Métodos de consulta agregada
  Future<Map<String, double>> getExpensesByCategory(DateTime startDate, DateTime endDate) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT c.name as category_name, SUM(t.amount) as total
      FROM transactions t
      INNER JOIN categories c ON t.category = c.id
      WHERE t.type = ? AND t.date >= ? AND t.date <= ?
      GROUP BY c.id, c.name
      ORDER BY total DESC
    ''', [
      models.TransactionType.expense.index,
      startDate.millisecondsSinceEpoch,
      endDate.millisecondsSinceEpoch,
    ]);

    final Map<String, double> result = {};
    for (final map in maps) {
      result[map['category_name']] = map['total'];
    }
    return result;
  }

  Future<double> getTotalIncome(DateTime startDate, DateTime endDate) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT SUM(amount) as total
      FROM transactions
      WHERE type = ? AND date >= ? AND date <= ?
    ''', [
      models.TransactionType.income.index,
      startDate.millisecondsSinceEpoch,
      endDate.millisecondsSinceEpoch,
    ]);

    return maps.first['total'] ?? 0.0;
  }

  Future<double> getTotalExpenses(DateTime startDate, DateTime endDate) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT SUM(amount) as total
      FROM transactions
      WHERE type = ? AND date >= ? AND date <= ?
    ''', [
      models.TransactionType.expense.index,
      startDate.millisecondsSinceEpoch,
      endDate.millisecondsSinceEpoch,
    ]);

    return maps.first['total'] ?? 0.0;
  }

  // Fechar conexão com o banco
  Future<void> close() async {
    final db = await database;
    await db.close();
  }
} 