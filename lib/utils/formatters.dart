import 'package:intl/intl.dart';

class Formatters {
  // Formatação de moeda brasileira
  static final NumberFormat _currencyFormatter = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: 'R\$',
    decimalDigits: 2,
  );

  // Formatação de data
  static final DateFormat _dateFormatter = DateFormat('dd/MM/yyyy');
  static final DateFormat _monthYearFormatter = DateFormat('MMMM/yyyy', 'pt_BR');
  static final DateFormat _dayMonthFormatter = DateFormat('dd/MM');

  // Formatar moeda
  static String formatCurrency(double value) {
    return _currencyFormatter.format(value);
  }

  // Formatar data
  static String formatDate(DateTime date) {
    return _dateFormatter.format(date);
  }

  // Formatar mês/ano
  static String formatMonthYear(DateTime date) {
    return _monthYearFormatter.format(date);
  }

  // Formatar dia/mês
  static String formatDayMonth(DateTime date) {
    return _dayMonthFormatter.format(date);
  }

  // Formatar percentual
  static String formatPercentage(double value) {
    return '${value.toStringAsFixed(1)}%';
  }

  // Formatar número com separadores de milhares
  static String formatNumber(double value) {
    return NumberFormat('#,##0.00', 'pt_BR').format(value);
  }

  // Formatar período do mês financeiro
  static String formatFinancialMonthPeriod(DateTime startDate, DateTime endDate) {
    final start = formatDayMonth(startDate);
    final end = formatDayMonth(endDate);
    final monthYear = formatMonthYear(startDate);
    return '$start a $end de $monthYear';
  }

  // Formatar descrição de transação parcelada
  static String formatInstallmentDescription(String description, int current, int total) {
    return '$description ($current/$total)';
  }

  // Formatar método de pagamento
  static String formatPaymentMethod(int paymentMethodIndex) {
    switch (paymentMethodIndex) {
      case 0:
        return 'Cartão de Crédito';
      case 1:
        return 'Cartão de Débito';
      case 2:
        return 'Pix';
      case 3:
        return 'Dinheiro';
      case 4:
        return 'Transferência';
      default:
        return 'Desconhecido';
    }
  }

  // Formatar tipo de recorrência
  static String formatRecurrenceType(int recurrenceTypeIndex) {
    switch (recurrenceTypeIndex) {
      case 0:
        return 'Única';
      case 1:
        return 'Mensal';
      case 2:
        return 'Parcelada';
      default:
        return 'Desconhecido';
    }
  }

  // Formatar tipo de transação
  static String formatTransactionType(int transactionTypeIndex) {
    switch (transactionTypeIndex) {
      case 0:
        return 'Receita';
      case 1:
        return 'Despesa';
      default:
        return 'Desconhecido';
    }
  }

  // Obter ícone para método de pagamento
  static String getPaymentMethodIcon(int paymentMethodIndex) {
    switch (paymentMethodIndex) {
      case 0:
        return '💳';
      case 1:
        return '💳';
      case 2:
        return '📱';
      case 3:
        return '💵';
      case 4:
        return '🏦';
      default:
        return '❓';
    }
  }

  // Obter cor para tipo de transação
  static String getTransactionTypeColor(int transactionTypeIndex) {
    switch (transactionTypeIndex) {
      case 0:
        return '#4CAF50'; // Verde para receita
      case 1:
        return '#F44336'; // Vermelho para despesa
      default:
        return '#9E9E9E'; // Cinza para desconhecido
    }
  }

  // Formatar saldo (positivo ou negativo)
  static String formatBalance(double balance) {
    final formatted = formatCurrency(balance.abs());
    return balance >= 0 ? '+$formatted' : '-$formatted';
  }

  // Formatar valor com sinal baseado no tipo
  static String formatAmountWithSign(double amount, int transactionTypeIndex) {
    final formatted = formatCurrency(amount);
    return transactionTypeIndex == 0 ? '+$formatted' : '-$formatted';
  }
} 