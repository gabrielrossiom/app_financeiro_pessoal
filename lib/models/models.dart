export 'transaction.dart';
export 'category.dart';
export 'credit_card.dart';
export 'financial_month.dart';
import 'package:uuid/uuid.dart';

class AppSettings {
  final String id;
  final int creditCardClosingDay;
  final DateTime createdAt;
  final DateTime updatedAt;

  AppSettings({
    required this.id,
    required this.creditCardClosingDay,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'creditCardClosingDay': creditCardClosingDay,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  factory AppSettings.fromMap(Map<String, dynamic> map) {
    return AppSettings(
      id: map['id'],
      creditCardClosingDay: map['creditCardClosingDay'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt']),
    );
  }

  AppSettings copyWith({
    String? id,
    int? creditCardClosingDay,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AppSettings(
      id: id ?? this.id,
      creditCardClosingDay: creditCardClosingDay ?? this.creditCardClosingDay,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

enum InvoiceStatus {
  aberta,
  fechada,
  prevista,
}

class CreditCardInvoice {
  final String id;
  final DateTime startDate;
  final DateTime endDate;
  final InvoiceStatus status;
  final double amount;
  final DateTime createdAt;
  final DateTime updatedAt;

  CreditCardInvoice({
    required this.id,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.amount,
    required this.createdAt,
    required this.updatedAt,
  });

  // Construtor para criar fatura baseada no dia de fechamento
  factory CreditCardInvoice.fromClosingDay(DateTime referenceDate, int closingDay, {String? id, bool isFirstInvoice = false}) {
    final now = DateTime.now();
    
    // Calcular a data de início da fatura
    DateTime startDate;
    if (referenceDate.day > closingDay) {
      // Se já passou do dia de fechamento, a fatura começou no mês atual no dia de fechamento
      startDate = DateTime(referenceDate.year, referenceDate.month, closingDay);
    } else {
      // Se ainda não chegou ao dia de fechamento, a fatura começa no mês anterior no dia de fechamento
      startDate = DateTime(referenceDate.year, referenceDate.month - 1, closingDay);
    }
    
    // Calcular a data de fim da fatura (dia anterior ao fechamento do próximo mês)
    DateTime nextMonthClosing = DateTime(startDate.year, startDate.month + 1, closingDay);
    DateTime endDate = nextMonthClosing.subtract(const Duration(days: 1));
    
    // Determinar o status: primeira fatura é ABERTA, demais são PREVISTA
    InvoiceStatus status = isFirstInvoice ? InvoiceStatus.aberta : InvoiceStatus.prevista;
    
    return CreditCardInvoice(
      id: id ?? const Uuid().v4(),
      startDate: startDate,
      endDate: endDate,
      status: status,
      amount: 0.0,
      createdAt: now,
      updatedAt: now,
    );
  }

  // Construtor para criar fatura subsequente baseada na data de início
  factory CreditCardInvoice.fromStartDate(DateTime startDate, int closingDay, {String? id}) {
    final now = DateTime.now();
    
    // Calcular a data de fim da fatura (dia anterior ao fechamento do próximo mês)
    DateTime nextMonthClosing = DateTime(startDate.year, startDate.month + 1, closingDay);
    DateTime endDate = nextMonthClosing.subtract(const Duration(days: 1));
    
    return CreditCardInvoice(
      id: id ?? const Uuid().v4(),
      startDate: startDate,
      endDate: endDate,
      status: InvoiceStatus.prevista,
      amount: 0.0,
      createdAt: now,
      updatedAt: now,
    );
  }

  // Método para verificar se uma data está dentro do período da fatura
  bool containsDate(DateTime date) {
    return date.isAfter(startDate.subtract(const Duration(days: 1))) && 
           date.isBefore(endDate.add(const Duration(days: 1)));
  }

  // Método para verificar se a fatura se sobrepõe a um período
  bool overlapsWithPeriod(DateTime periodStart, DateTime periodEnd) {
    return (startDate.isBefore(periodEnd.add(const Duration(days: 1))) &&
            endDate.isAfter(periodStart.subtract(const Duration(days: 1))));
  }

  // Método para fechar a fatura
  CreditCardInvoice close(DateTime closingDate) {
    return copyWith(
      endDate: closingDate,
      status: InvoiceStatus.fechada,
      updatedAt: DateTime.now(),
    );
  }

  // Método para abrir a fatura
  CreditCardInvoice open(DateTime openingDate) {
    return copyWith(
      startDate: openingDate,
      status: InvoiceStatus.aberta,
      updatedAt: DateTime.now(),
    );
  }

  // Método para atualizar o valor
  CreditCardInvoice updateAmount(double newAmount) {
    return copyWith(
      amount: newAmount,
      updatedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'startDate': startDate.millisecondsSinceEpoch,
      'endDate': endDate.millisecondsSinceEpoch,
      'status': status.name,
      'amount': amount,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  factory CreditCardInvoice.fromMap(Map<String, dynamic> map) {
    return CreditCardInvoice(
      id: map['id'],
      startDate: DateTime.fromMillisecondsSinceEpoch(map['startDate']),
      endDate: DateTime.fromMillisecondsSinceEpoch(map['endDate']),
      status: InvoiceStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => InvoiceStatus.prevista,
      ),
      amount: map['amount'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt']),
    );
  }

  CreditCardInvoice copyWith({
    String? id,
    DateTime? startDate,
    DateTime? endDate,
    InvoiceStatus? status,
    double? amount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CreditCardInvoice(
      id: id ?? this.id,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
      amount: amount ?? this.amount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
} 