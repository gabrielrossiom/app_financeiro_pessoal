import 'package:uuid/uuid.dart';

class CreditCard {
  final String id;
  final String name;
  final String bank;
  final double creditLimit;
  final int closingDay; // Dia do fechamento da fatura
  final int dueDay; // Dia do vencimento da fatura
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  CreditCard({
    String? id,
    required this.name,
    required this.bank,
    required this.creditLimit,
    required this.closingDay,
    required this.dueDay,
    this.isActive = true,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : 
    id = id ?? const Uuid().v4(),
    createdAt = createdAt ?? DateTime.now(),
    updatedAt = updatedAt ?? DateTime.now();

  // Método para obter a data de fechamento da fatura para um mês específico
  DateTime getClosingDate(DateTime month) {
    return DateTime(month.year, month.month, closingDay);
  }

  // Método para obter a data de vencimento da fatura para um mês específico
  DateTime getDueDate(DateTime month) {
    return DateTime(month.year, month.month, dueDay);
  }

  // Método para verificar se uma transação pertence à fatura de um mês específico
  bool transactionBelongsToInvoice(DateTime transactionDate, DateTime invoiceMonth) {
    final closingDate = getClosingDate(invoiceMonth);
    final nextClosingDate = getClosingDate(DateTime(invoiceMonth.year, invoiceMonth.month + 1, 1));
    
    return transactionDate.isAfter(closingDate.subtract(const Duration(days: 1))) && 
           transactionDate.isBefore(nextClosingDate.add(const Duration(days: 1)));
  }

  // Método para obter o mês da fatura para uma transação
  DateTime getInvoiceMonthForTransaction(DateTime transactionDate) {
    final currentMonthClosing = getClosingDate(transactionDate);
    
    if (transactionDate.isBefore(currentMonthClosing)) {
      // Transação pertence à fatura do mês anterior
      return DateTime(transactionDate.year, transactionDate.month - 1, 1);
    } else {
      // Transação pertence à fatura do mês atual
      return DateTime(transactionDate.year, transactionDate.month, 1);
    }
  }

  // Método para copiar com alterações
  CreditCard copyWith({
    String? name,
    String? bank,
    double? creditLimit,
    int? closingDay,
    int? dueDay,
    bool? isActive,
  }) {
    return CreditCard(
      id: id,
      name: name ?? this.name,
      bank: bank ?? this.bank,
      creditLimit: creditLimit ?? this.creditLimit,
      closingDay: closingDay ?? this.closingDay,
      dueDay: dueDay ?? this.dueDay,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  // Conversão para Map (para banco de dados)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'bank': bank,
      'creditLimit': creditLimit,
      'closingDay': closingDay,
      'dueDay': dueDay,
      'isActive': isActive ? 1 : 0,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  // Criação a partir de Map (do banco de dados)
  factory CreditCard.fromMap(Map<String, dynamic> map) {
    return CreditCard(
      id: map['id'],
      name: map['name'],
      bank: map['bank'],
      creditLimit: map['creditLimit'],
      closingDay: map['closingDay'],
      dueDay: map['dueDay'],
      isActive: map['isActive'] == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt']),
    );
  }
} 