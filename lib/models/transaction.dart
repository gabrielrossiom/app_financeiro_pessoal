import 'package:uuid/uuid.dart';

enum TransactionType {
  expenseAccount,    // Despesa em conta
  incomeAccount,     // Receita em conta
  creditCardPayment, // Pagamento de fatura de cartão
  creditCardPurchase // Compra em cartão de crédito
}

extension TransactionTypeExtension on TransactionType {
  String get displayName {
    switch (this) {
      case TransactionType.expenseAccount:
        return 'Despesa em conta';
      case TransactionType.incomeAccount:
        return 'Receita em conta';
      case TransactionType.creditCardPayment:
        return 'Pagamento de fatura de cartão';
      case TransactionType.creditCardPurchase:
        return 'Compra em cartão de crédito';
    }
  }
}

enum RecurrenceType {
  unica,        // Única
  recorrente,   // Recorrente
  parcelada,    // Parcelada (apenas para compra em cartão)
}

extension RecurrenceTypeExtension on RecurrenceType {
  String get displayName {
    switch (this) {
      case RecurrenceType.unica:
        return 'Única';
      case RecurrenceType.recorrente:
        return 'Recorrente';
      case RecurrenceType.parcelada:
        return 'Parcelada';
    }
  }
}

class Transaction {
  final String id;
  final String description;
  final double amount;
  final TransactionType type;
  final String? category; // Só para despesa em conta e compra em cartão
  final DateTime date;
  final RecurrenceType? recurrenceType; // Só para tipos que usam recorrência
  final int? installments; // Só para compra em cartão parcelada
  final int? currentInstallment;
  final String? parentTransactionId; // Para parcelamentos
  final DateTime createdAt;
  final DateTime updatedAt;

  Transaction({
    String? id,
    required this.description,
    required this.amount,
    required this.type,
    this.category,
    required this.date,
    this.recurrenceType,
    this.installments,
    this.currentInstallment,
    this.parentTransactionId,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? const Uuid().v4(),
    createdAt = createdAt ?? DateTime.now(),
    updatedAt = updatedAt ?? DateTime.now();

  // Construtores de fábrica para cada tipo
  factory Transaction.expenseAccount({
    required String description,
    required double amount,
    required String category,
    required DateTime date,
    required RecurrenceType recurrenceType, // unica ou recorrente
  }) {
    return Transaction(
      description: description,
      amount: amount,
      type: TransactionType.expenseAccount,
      category: category,
      date: date,
      recurrenceType: recurrenceType,
    );
  }

  factory Transaction.incomeAccount({
    required String description,
    required double amount,
    required DateTime date,
    required RecurrenceType recurrenceType, // unica ou recorrente
  }) {
    return Transaction(
      description: description,
      amount: amount,
      type: TransactionType.incomeAccount,
      date: date,
      recurrenceType: recurrenceType,
    );
  }

  factory Transaction.creditCardPayment({
    required String description,
    required double amount,
    required DateTime date,
  }) {
    return Transaction(
      description: description,
      amount: amount,
      type: TransactionType.creditCardPayment,
      date: date,
    );
    }

  factory Transaction.creditCardPurchase({
    required String description,
    required double amount,
    required String category,
    required DateTime date,
    required RecurrenceType recurrenceType, // unica, recorrente ou parcelada
    int? installments,
  }) {
    return Transaction(
      description: description,
      amount: amount,
      type: TransactionType.creditCardPurchase,
      category: category,
      date: date,
      recurrenceType: recurrenceType,
      installments: recurrenceType == RecurrenceType.parcelada ? installments : null,
      currentInstallment: recurrenceType == RecurrenceType.parcelada ? 1 : null,
    );
  }

  // Métodos auxiliares e serialização
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'description': description,
      'amount': amount,
      'type': type.index,
      'category': category,
      'date': date.millisecondsSinceEpoch,
      'recurrenceType': recurrenceType?.index,
      'installments': installments,
      'currentInstallment': currentInstallment,
      'parentTransactionId': parentTransactionId,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'],
      description: map['description'],
      amount: map['amount'],
      type: TransactionType.values[map['type']],
      category: map['category'],
      date: DateTime.fromMillisecondsSinceEpoch(map['date']),
      recurrenceType: map['recurrenceType'] != null ? RecurrenceType.values[map['recurrenceType']] : null,
      installments: map['installments'],
      currentInstallment: map['currentInstallment'],
      parentTransactionId: map['parentTransactionId'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt']),
    );
  }

  Transaction copyWith({
    String? id,
    String? description,
    double? amount,
    TransactionType? type,
    String? category,
    DateTime? date,
    RecurrenceType? recurrenceType,
    int? installments,
    int? currentInstallment,
    String? parentTransactionId,
  }) {
    return Transaction(
      id: id ?? this.id,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      category: category ?? this.category,
      date: date ?? this.date,
      recurrenceType: recurrenceType ?? this.recurrenceType,
      installments: installments ?? this.installments,
      currentInstallment: currentInstallment ?? this.currentInstallment,
      parentTransactionId: parentTransactionId ?? this.parentTransactionId,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
} 