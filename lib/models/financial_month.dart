import 'package:uuid/uuid.dart';

class FinancialMonth {
  final String id;
  final DateTime startDate; // Dia 20 do mês
  final DateTime endDate; // Dia 19 do mês seguinte
  final double totalIncome;
  final double totalExpenses;
  final double budget;
  final double remainingBudget;
  final bool isClosed;
  final DateTime createdAt;
  final DateTime updatedAt;

  FinancialMonth({
    String? id,
    required this.startDate,
    required this.endDate,
    this.totalIncome = 0,
    this.totalExpenses = 0,
    this.budget = 0,
    this.remainingBudget = 0,
    this.isClosed = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : 
    id = id ?? const Uuid().v4(),
    createdAt = createdAt ?? DateTime.now(),
    updatedAt = updatedAt ?? DateTime.now();

  // Construtor para criar um mês financeiro baseado em uma data
  factory FinancialMonth.fromDate(DateTime date) {
    DateTime startDate;
    DateTime endDate;

    if (date.day >= 20) {
      // Se a data for dia 20 ou depois, o mês financeiro começa no dia 20 do mês atual
      startDate = DateTime(date.year, date.month, 20);
      endDate = DateTime(date.year, date.month + 1, 19);
    } else {
      // Se a data for antes do dia 20, o mês financeiro começou no dia 20 do mês anterior
      startDate = DateTime(date.year, date.month - 1, 20);
      endDate = DateTime(date.year, date.month, 19);
    }

    return FinancialMonth(
      startDate: startDate,
      endDate: endDate,
    );
  }

  // Método para obter o mês financeiro atual
  static FinancialMonth get currentMonth {
    return FinancialMonth.fromDate(DateTime.now());
  }

  // Método para obter o próximo mês financeiro
  FinancialMonth get nextMonth {
    return FinancialMonth(
      startDate: endDate.add(const Duration(days: 1)),
      endDate: DateTime(endDate.year, endDate.month + 1, 19),
    );
  }

  // Método para obter o mês financeiro anterior
  FinancialMonth get previousMonth {
    return FinancialMonth(
      startDate: DateTime(startDate.year, startDate.month - 1, 20),
      endDate: startDate.subtract(const Duration(days: 1)),
    );
  }

  // Método para verificar se uma data pertence a este mês financeiro
  bool containsDate(DateTime date) {
    return date.isAfter(startDate.subtract(const Duration(days: 1))) && 
           date.isBefore(endDate.add(const Duration(days: 1)));
  }

  // Método para calcular o saldo restante
  double get balance {
    return totalIncome - totalExpenses;
  }

  // Método para calcular o percentual de uso do orçamento
  double get budgetUsagePercentage {
    if (budget == 0) return 0;
    return (totalExpenses / budget) * 100;
  }

  // Método para verificar se o orçamento foi excedido
  bool get isBudgetExceeded {
    return totalExpenses > budget;
  }

  // Método para verificar se está próximo do limite do orçamento (80%)
  bool get isNearBudgetLimit {
    return budgetUsagePercentage >= 80 && !isBudgetExceeded;
  }

  // Método para atualizar totais
  FinancialMonth updateTotals({
    double? totalIncome,
    double? totalExpenses,
    double? budget,
  }) {
    final newTotalIncome = totalIncome ?? this.totalIncome;
    final newTotalExpenses = totalExpenses ?? this.totalExpenses;
    final newBudget = budget ?? this.budget;
    final newRemainingBudget = newBudget - newTotalExpenses;

    return FinancialMonth(
      id: id,
      startDate: startDate,
      endDate: endDate,
      totalIncome: newTotalIncome,
      totalExpenses: newTotalExpenses,
      budget: newBudget,
      remainingBudget: newRemainingBudget,
      isClosed: isClosed,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  // Método para fechar o mês
  FinancialMonth closeMonth() {
    return FinancialMonth(
      id: id,
      startDate: startDate,
      endDate: endDate,
      totalIncome: totalIncome,
      totalExpenses: totalExpenses,
      budget: budget,
      remainingBudget: remainingBudget,
      isClosed: true,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  // Método para copiar com alterações
  FinancialMonth copyWith({
    DateTime? startDate,
    DateTime? endDate,
    double? totalIncome,
    double? totalExpenses,
    double? budget,
    double? remainingBudget,
    bool? isClosed,
  }) {
    return FinancialMonth(
      id: id,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      totalIncome: totalIncome ?? this.totalIncome,
      totalExpenses: totalExpenses ?? this.totalExpenses,
      budget: budget ?? this.budget,
      remainingBudget: remainingBudget ?? this.remainingBudget,
      isClosed: isClosed ?? this.isClosed,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  // Conversão para Map (para banco de dados)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'startDate': startDate.millisecondsSinceEpoch,
      'endDate': endDate.millisecondsSinceEpoch,
      'totalIncome': totalIncome,
      'totalExpenses': totalExpenses,
      'budget': budget,
      'remainingBudget': remainingBudget,
      'isClosed': isClosed ? 1 : 0,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  // Criação a partir de Map (do banco de dados)
  factory FinancialMonth.fromMap(Map<String, dynamic> map) {
    return FinancialMonth(
      id: map['id'],
      startDate: DateTime.fromMillisecondsSinceEpoch(map['startDate']),
      endDate: DateTime.fromMillisecondsSinceEpoch(map['endDate']),
      totalIncome: map['totalIncome'],
      totalExpenses: map['totalExpenses'],
      budget: map['budget'],
      remainingBudget: map['remainingBudget'],
      isClosed: map['isClosed'] == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt']),
    );
  }
} 