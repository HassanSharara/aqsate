class Installment {
  final int? id;
  final int loanId;
  final int monthIndex; // 1..n
  final String dueDate;
  final double scheduledProfit; // حصة هذا الشهر من الأرباح حسب الجدول
  final double paymentAmount; // التسديد الفعلي المسجل لهذا الشهر
  final String? paymentDate;
  final String notes;

  Installment({
    this.id,
    required this.loanId,
    required this.monthIndex,
    required this.dueDate,
    required this.scheduledProfit,
    this.paymentAmount = 0,
    this.paymentDate,
    this.notes = '',
  });

  bool get isPaid => paymentAmount > 0;

  Installment copyWith({
    int? id,
    int? loanId,
    int? monthIndex,
    String? dueDate,
    double? scheduledProfit,
    double? paymentAmount,
    String? paymentDate,
    String? notes,
  }) {
    return Installment(
      id: id ?? this.id,
      loanId: loanId ?? this.loanId,
      monthIndex: monthIndex ?? this.monthIndex,
      dueDate: dueDate ?? this.dueDate,
      scheduledProfit: scheduledProfit ?? this.scheduledProfit,
      paymentAmount: paymentAmount ?? this.paymentAmount,
      paymentDate: paymentDate ?? this.paymentDate,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'loan_id': loanId,
      'month_index': monthIndex,
      'due_date': dueDate,
      'scheduled_profit': scheduledProfit,
      'payment_amount': paymentAmount,
      'payment_date': paymentDate,
      'notes': notes,
    };
  }

  factory Installment.fromMap(Map<String, dynamic> map) {
    return Installment(
      id: map['id'] as int?,
      loanId: map['loan_id'] as int,
      monthIndex: map['month_index'] as int,
      dueDate: map['due_date'] as String? ?? '',
      scheduledProfit: (map['scheduled_profit'] as num).toDouble(),
      paymentAmount: (map['payment_amount'] as num?)?.toDouble() ?? 0,
      paymentDate: map['payment_date'] as String?,
      notes: map['notes'] as String? ?? '',
    );
  }
}

/// صف محسوب يُعرض في جدول الأقساط (الخانات الست + إضافات)
class InstallmentRow {
  final Installment installment;
  final double profitPortion; // الجزء الذاهب للأرباح من هذا التسديد
  final double principalPortion; // الجزء الذاهب لأصل المبلغ
  final double remainingPrincipal; // المتبقي من المبلغ الأصلي
  final double remainingProfit; // المتبقي من الأرباح
  final double remainingTotal; // المتبقي من المبلغ الكلي مع الأرباح

  InstallmentRow({
    required this.installment,
    required this.profitPortion,
    required this.principalPortion,
    required this.remainingPrincipal,
    required this.remainingProfit,
    required this.remainingTotal,
  });
}
