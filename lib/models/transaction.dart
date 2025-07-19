import 'package:uuid/uuid.dart';

enum TransactionType {
  income,    // Receita
  expense,   // Despesa
}

extension TransactionTypeExtension on TransactionType {
  String get displayName {
    switch (this) {
      case TransactionType.income:
        return 'Receita';
      case TransactionType.expense:
        return 'Despesa';
    }
  }
}

enum PaymentMethod {
  creditCard,    // Cartão de Crédito
  debitCard,     // Cartão de Débito
  pix,           // Pix
  cash,          // Dinheiro
  bankTransfer,  // Transferência Bancária
}

extension PaymentMethodExtension on PaymentMethod {
  String get displayName {
    switch (this) {
      case PaymentMethod.creditCard:
        return 'Cartão de Crédito';
      case PaymentMethod.debitCard:
        return 'Cartão de Débito';
      case PaymentMethod.pix:
        return 'Pix';
      case PaymentMethod.cash:
        return 'Dinheiro';
      case PaymentMethod.bankTransfer:
        return 'Transferência Bancária';
    }
  }
}

enum RecurrenceType {
  none,       // Única
  monthly,    // Mensal
  installment, // Parcelada
}

extension RecurrenceTypeExtension on RecurrenceType {
  String get displayName {
    switch (this) {
      case RecurrenceType.none:
        return 'Única';
      case RecurrenceType.monthly:
        return 'Mensal';
      case RecurrenceType.installment:
        return 'Parcelada';
    }
  }
}

class Transaction {
  final String id;
  final String description;
  final double amount;
  final TransactionType type;
  final PaymentMethod paymentMethod;
  final String category;
  final DateTime date;
  final RecurrenceType recurrenceType;
  final int? installments;
  final int? currentInstallment;
  final String? parentTransactionId; // Para parcelamentos
  final bool isRefundable;
  final double? refundAmount;
  final bool isRefunded;
  final DateTime createdAt;
  final DateTime updatedAt;

  Transaction({
    String? id,
    required this.description,
    required this.amount,
    required this.type,
    required this.paymentMethod,
    required this.category,
    required this.date,
    this.recurrenceType = RecurrenceType.none,
    this.installments,
    this.currentInstallment,
    this.parentTransactionId,
    this.isRefundable = false,
    this.refundAmount,
    this.isRefunded = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : 
    id = id ?? const Uuid().v4(),
    createdAt = createdAt ?? DateTime.now(),
    updatedAt = updatedAt ?? DateTime.now();

  // Construtor para criar uma nova transação
  factory Transaction.create({
    required String description,
    required double amount,
    required TransactionType type,
    required PaymentMethod paymentMethod,
    required String category,
    required DateTime date,
    RecurrenceType recurrenceType = RecurrenceType.none,
    int? installments,
    bool isRefundable = false,
  }) {
    return Transaction(
      description: description,
      amount: amount,
      type: type,
      paymentMethod: paymentMethod,
      category: category,
      date: date,
      recurrenceType: recurrenceType,
      installments: installments,
      currentInstallment: installments != null ? 1 : null,
      isRefundable: isRefundable,
    );
  }

  // Método para criar parcelas de uma transação
  List<Transaction> createInstallments() {
    if (installments == null || installments! <= 1) {
      return [this];
    }

    final monthlyAmount = amount / installments!;
    final installmentsList = <Transaction>[];

    for (int i = 0; i < installments!; i++) {
      final installmentDate = DateTime(date.year, date.month + i, date.day);
      
      installmentsList.add(Transaction(
        description: '$description (${i + 1}/$installments)',
        amount: monthlyAmount,
        type: type,
        paymentMethod: paymentMethod,
        category: category,
        date: installmentDate,
        recurrenceType: RecurrenceType.installment,
        installments: installments,
        currentInstallment: i + 1,
        parentTransactionId: id,
        isRefundable: isRefundable,
        refundAmount: refundAmount != null ? refundAmount! / installments! : null,
      ));
    }

    return installmentsList;
  }

  // Método para criar próxima recorrência mensal
  Transaction? createNextRecurrence() {
    if (recurrenceType != RecurrenceType.monthly) {
      return null;
    }

    final nextDate = DateTime(date.year, date.month + 1, date.day);
    
    return Transaction(
      description: description,
      amount: amount,
      type: type,
      paymentMethod: paymentMethod,
      category: category,
      date: nextDate,
      recurrenceType: recurrenceType,
      isRefundable: isRefundable,
      refundAmount: refundAmount,
    );
  }

  // Método para verificar se a transação pertence ao mês financeiro
  bool belongsToFinancialMonth(DateTime monthStart) {
    final monthEnd = DateTime(monthStart.year, monthStart.month + 1, 19);
    return date.isAfter(monthStart.subtract(const Duration(days: 1))) && 
           date.isBefore(monthEnd.add(const Duration(days: 1)));
  }

  // Método para obter o mês financeiro da transação
  DateTime getFinancialMonth() {
    if (date.day >= 20) {
      return DateTime(date.year, date.month, 20);
    } else {
      return DateTime(date.year, date.month - 1, 20);
    }
  }

  // Método para copiar com alterações
  Transaction copyWith({
    String? description,
    double? amount,
    TransactionType? type,
    PaymentMethod? paymentMethod,
    String? category,
    DateTime? date,
    RecurrenceType? recurrenceType,
    int? installments,
    int? currentInstallment,
    String? parentTransactionId,
    bool? isRefundable,
    double? refundAmount,
    bool? isRefunded,
  }) {
    return Transaction(
      id: id,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      category: category ?? this.category,
      date: date ?? this.date,
      recurrenceType: recurrenceType ?? this.recurrenceType,
      installments: installments ?? this.installments,
      currentInstallment: currentInstallment ?? this.currentInstallment,
      parentTransactionId: parentTransactionId ?? this.parentTransactionId,
      isRefundable: isRefundable ?? this.isRefundable,
      refundAmount: refundAmount ?? this.refundAmount,
      isRefunded: isRefunded ?? this.isRefunded,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  // Conversão para Map (para banco de dados)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'description': description,
      'amount': amount,
      'type': type.index,
      'paymentMethod': paymentMethod.index,
      'category': category,
      'date': date.millisecondsSinceEpoch,
      'recurrenceType': recurrenceType.index,
      'installments': installments,
      'currentInstallment': currentInstallment,
      'parentTransactionId': parentTransactionId,
      'isRefundable': isRefundable ? 1 : 0,
      'refundAmount': refundAmount,
      'isRefunded': isRefunded ? 1 : 0,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  // Criação a partir de Map (do banco de dados)
  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'],
      description: map['description'],
      amount: map['amount'],
      type: TransactionType.values[map['type']],
      paymentMethod: PaymentMethod.values[map['paymentMethod']],
      category: map['category'],
      date: DateTime.fromMillisecondsSinceEpoch(map['date']),
      recurrenceType: RecurrenceType.values[map['recurrenceType']],
      installments: map['installments'],
      currentInstallment: map['currentInstallment'],
      parentTransactionId: map['parentTransactionId'],
      isRefundable: map['isRefundable'] == 1,
      refundAmount: map['refundAmount'],
      isRefunded: map['isRefunded'] == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt']),
    );
  }
} 