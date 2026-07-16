/// وضع توزيع الأرباح على الأشهر
enum ProfitDistributionMode { auto, manual }

/// حالة القرض
enum LoanStatus { active, completed }

extension ProfitDistributionModeX on ProfitDistributionMode {
  String get dbValue => this == ProfitDistributionMode.auto ? 'auto' : 'manual';

  static ProfitDistributionMode fromDb(String v) =>
      v == 'manual' ? ProfitDistributionMode.manual : ProfitDistributionMode.auto;

  String get label => this == ProfitDistributionMode.auto ? 'تلقائي (متناقص)' : 'يدوي';
}

extension LoanStatusX on LoanStatus {
  String get dbValue => this == LoanStatus.active ? 'active' : 'completed';

  static LoanStatus fromDb(String v) =>
      v == 'completed' ? LoanStatus.completed : LoanStatus.active;

  String get label => this == LoanStatus.active ? 'نشط' : 'مكتمل';
}

class Loan {
  final int? id;
  final int customerId;
  final double principalAmount; // المبلغ الأصلي (مثلاً مليون)
  final double profitAmount; // إجمالي الأرباح (مثلاً 350 ألف)
  final int months; // عدد أشهر التسديد
  final String startDate;
  final ProfitDistributionMode distributionMode;
  final LoanStatus status;
  final String notes;
  final String createdAt;

  Loan({
    this.id,
    required this.customerId,
    required this.principalAmount,
    required this.profitAmount,
    required this.months,
    required this.startDate,
    this.distributionMode = ProfitDistributionMode.auto,
    this.status = LoanStatus.active,
    this.notes = '',
    required this.createdAt,
  });

  double get totalAmount => principalAmount + profitAmount;

  Loan copyWith({
    int? id,
    int? customerId,
    double? principalAmount,
    double? profitAmount,
    int? months,
    String? startDate,
    ProfitDistributionMode? distributionMode,
    LoanStatus? status,
    String? notes,
    String? createdAt,
  }) {
    return Loan(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      principalAmount: principalAmount ?? this.principalAmount,
      profitAmount: profitAmount ?? this.profitAmount,
      months: months ?? this.months,
      startDate: startDate ?? this.startDate,
      distributionMode: distributionMode ?? this.distributionMode,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customer_id': customerId,
      'principal_amount': principalAmount,
      'profit_amount': profitAmount,
      'months': months,
      'start_date': startDate,
      'distribution_mode': distributionMode.dbValue,
      'status': status.dbValue,
      'notes': notes,
      'created_at': createdAt,
    };
  }

  factory Loan.fromMap(Map<String, dynamic> map) {
    return Loan(
      id: map['id'] as int?,
      customerId: map['customer_id'] as int,
      principalAmount: (map['principal_amount'] as num).toDouble(),
      profitAmount: (map['profit_amount'] as num).toDouble(),
      months: map['months'] as int,
      startDate: map['start_date'] as String? ?? '',
      distributionMode: ProfitDistributionModeX.fromDb(map['distribution_mode'] as String? ?? 'auto'),
      status: LoanStatusX.fromDb(map['status'] as String? ?? 'active'),
      notes: map['notes'] as String? ?? '',
      createdAt: map['created_at'] as String? ?? '',
    );
  }
}
