import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/loan.dart';
import '../models/installment.dart';
import '../services/profit_calculator.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

class LoanDetailScreen extends StatefulWidget {
  final Loan loan;
  final String customerName;
  const LoanDetailScreen({super.key, required this.loan, required this.customerName});

  @override
  State<LoanDetailScreen> createState() => _LoanDetailScreenState();
}

class _LoanDetailScreenState extends State<LoanDetailScreen> {
  List<Installment> _installments = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await context.read<AppProvider>().installmentsForLoan(widget.loan.id!);
    setState(() {
      _installments = list;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final loan = provider.allLoans.firstWhere(
          (l) => l.id == widget.loan.id,
      orElse: () => widget.loan,
    );

    final rows = ProfitCalculator.calculateRows(
      principalAmount: loan.principalAmount,
      totalProfit: loan.profitAmount,
      installments: _installments,
    );

    final totalPaid = rows.fold<double>(0, (s, r) => s + r.installment.paymentAmount);
    final remainingTotal = rows.isNotEmpty ? rows.last.remainingTotal : loan.totalAmount;
    final isFullyPaid = remainingTotal <= 0.01;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0F172A),
            Color(0xFF1E1E38),
            Color(0xFF0F172A),
          ],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primary.withOpacity(0.2),
                child: Text(
                  widget.customerName.isNotEmpty ? widget.customerName[0] : '?',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text('قرض ${widget.customerName}'),
            ],
          ),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(28, 8, 28, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SummaryHeader(
                loan: loan,
                totalPaid: totalPaid,
                remainingTotal: remainingTotal,
              ),
              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'جدول الأقساط',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (isFullyPaid || loan.status == LoanStatus.completed)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: AppColors.successGradient,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.success.withOpacity(0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle_rounded, color: Colors.white, size: 16),
                          SizedBox(width: 6),
                          Text(
                            'تم سداد القرض بالكامل ✓',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              GlassContainer(
                borderRadius: BorderRadius.circular(18),
                padding: EdgeInsets.zero,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columnSpacing: 20,
                      dataRowMinHeight: 56,
                      dataRowMaxHeight: 68,
                      headingTextStyle: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                      columns: const [
                        DataColumn(label: Text('الشهر')),
                        DataColumn(label: Text('الفائدة المجدولة')),
                        DataColumn(label: Text('القسط المفترض هذا الشهر')),
                        DataColumn(label: Text('المتبقي الكلي')),
                        DataColumn(label: Text('المتبقي الصافي')),
                        DataColumn(label: Text('المسدد من قبل الزبون')),
                        DataColumn(label: Text('تاريخ الاستحقاق')),
                        DataColumn(label: Text('')),
                      ],
                      rows: rows.map((r) => _buildRow(context, r, isFullyPaid, loan.principalAmount)).toList(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  DataRow _buildRow(BuildContext context, InstallmentRow r, bool isLoanFullyPaid, double principalAmount) {
    final inst = r.installment;
    final paid = inst.paymentAmount > 0;
    final completed = r.remainingTotal <= 0.01;
    final bool isOverpaid = paid && inst.paymentAmount > r.expectedInstallment + 1;
    final bool isUnderpaid = paid && inst.paymentAmount < r.expectedInstallment - 1;

    return DataRow(
      color: WidgetStateProperty.resolveWith((states) {
        if (completed) return AppColors.success.withOpacity(0.06);
        if (states.contains(WidgetState.hovered)) return AppColors.glassMid;
        return Colors.transparent;
      }),
      cells: [
        DataCell(
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: completed
                  ? AppColors.success.withOpacity(0.15)
                  : AppColors.glassLight,
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Text(
              '${inst.monthIndex}',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: completed ? AppColors.success : AppColors.textPrimary,
                fontSize: 13,
              ),
            ),
          ),
        ),
        DataCell(Text(
          Formatters.currency(inst.scheduledProfit),
          style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.w700),
        )),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.primary.withOpacity(0.3)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  Formatters.currency(r.expectedInstallment),
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                Text(
                  'أصل: ${Formatters.currency(r.expectedInstallment - inst.scheduledProfit)} | ربح: ${Formatters.currency(inst.scheduledProfit)}',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 9),
                ),
              ],
            ),
          ),
        ),
        DataCell(
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                Formatters.currency(r.remainingTotal),
                style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.textPrimary, fontSize: 13),
              ),
              Text(
                'المفترض: ${Formatters.currency(r.expectedRemainingTotal)}',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 10),
              ),
            ],
          ),
        ),
        DataCell(
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                Formatters.currency(r.remainingPrincipal),
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
              ),
              Text(
                'المفترض: ${Formatters.currency(r.expectedRemainingPrincipal)}',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 10),
              ),
            ],
          ),
        ),
        DataCell(
          paid
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isOverpaid
                          ? Icons.arrow_upward_rounded
                          : isUnderpaid
                              ? Icons.arrow_downward_rounded
                              : Icons.check_circle_rounded,
                      size: 14,
                      color: isOverpaid
                          ? AppColors.info
                          : isUnderpaid
                              ? AppColors.accent
                              : AppColors.success,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      Formatters.currency(inst.paymentAmount),
                      style: TextStyle(
                        color: isOverpaid
                            ? AppColors.info
                            : isUnderpaid
                                ? AppColors.accent
                                : AppColors.success,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                )
              : const Text('—', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        ),
        DataCell(Text(Formatters.date(inst.dueDate), style: const TextStyle(fontSize: 12))),
        DataCell(
          (isLoanFullyPaid && !paid)
              ? const SizedBox.shrink()
              : _PaymentIconButton(
            paid: paid,
            onPressed: () => _showPaymentDialog(context, r),
          ),
        ),
      ],
    );

  }

  void _showPaymentDialog(BuildContext context, InstallmentRow r) {
    final inst = r.installment;
    String defaultText = '';

    if (inst.paymentAmount > 0) {
      defaultText = inst.paymentAmount.round().toString();
    } else {
      defaultText = r.expectedInstallment.round().toString();
    }

    final ctrl = TextEditingController(text: defaultText);
    final double principalPart = r.expectedInstallment - inst.scheduledProfit;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.payments_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            Text('تسديد قسط الشهر ${inst.monthIndex}'),
          ],
        ),
        content: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // بطاقة معلومات القسط المفترض
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withOpacity(0.25)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.calculate_rounded, color: AppColors.primary, size: 16),
                        const SizedBox(width: 8),
                        const Text(
                          'تفاصيل القسط المفترض هذا الشهر',
                          style: TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _InfoRow('قسط الأصل', Formatters.currency(principalPart), AppColors.info),
                    const SizedBox(height: 6),
                    _InfoRow('الفائدة المجدولة', Formatters.currency(inst.scheduledProfit), AppColors.accent),
                    Divider(color: AppColors.glassBorder, height: 16),
                    _InfoRow('إجمالي القسط المفترض', Formatters.currency(r.expectedInstallment), AppColors.primary),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: ctrl,
                autofocus: true,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'مبلغ التسديد الفعلي (د.ع)',
                  prefixIcon: Icon(Icons.payments_outlined),
                  helperText: 'ادخل المبلغ الفعلي المسدد من قبل الزبون',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(ctrl.text) ?? 0;
              await context.read<AppProvider>().recordPayment(inst, amount: amount);
              if (context.mounted) Navigator.pop(context);
              await _load();
            },
            child: const Text('حفظ التسديد'),
          ),
        ],
      ),
    );
  }
}

class _PaymentIconButton extends StatefulWidget {
  final bool paid;
  final VoidCallback onPressed;
  const _PaymentIconButton({required this.paid, required this.onPressed});

  @override
  State<_PaymentIconButton> createState() => _PaymentIconButtonState();
}

class _PaymentIconButtonState extends State<_PaymentIconButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: _hovered
              ? AppColors.primary.withOpacity(0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: IconButton(
          icon: Icon(
            widget.paid ? Icons.edit_rounded : Icons.payments_rounded,
            size: 20,
            color: AppColors.primary,
          ),
          tooltip: widget.paid ? 'تعديل الدفعة' : 'تسجيل دفعة',
          onPressed: widget.onPressed,
        ),
      ),
    );
  }
}

class _SummaryHeader extends StatelessWidget {
  final Loan loan;
  final double totalPaid;
  final double remainingTotal;
  const _SummaryHeader({required this.loan, required this.totalPaid, required this.remainingTotal});

  @override
  Widget build(BuildContext context) {
    final double progress =
    loan.totalAmount == 0 ? 0.0 : (1 - (remainingTotal / loan.totalAmount)).clamp(0.0, 1.0);

    return GlassContainer(
      padding: const EdgeInsets.all(24),
      borderRadius: BorderRadius.circular(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 28,
            runSpacing: 16,
            children: [
              _Stat('المبلغ الأصلي', Formatters.currency(loan.principalAmount), AppColors.info),
              _Stat('إجمالي الأرباح', Formatters.currency(loan.profitAmount), AppColors.accent),
              _Stat('المبلغ الكلي', Formatters.currency(loan.totalAmount), AppColors.primary),
              _Stat('عدد الأشهر', '${loan.months} شهر', AppColors.textSecondary),
              _Stat('طريقة التوزيع', loan.distributionMode.label, AppColors.textSecondary),
              _Stat('المُسدَّد', Formatters.currency(totalPaid), AppColors.success),
              _Stat('المتبقي', Formatters.currency(remainingTotal), AppColors.danger),
            ],
          ),
          const SizedBox(height: 22),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'نسبة التسديد',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
              ),
              Text(
                '${(progress * 100).toStringAsFixed(0)}%',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Stack(
            children: [
              Container(
                height: 10,
                decoration: BoxDecoration(
                  color: AppColors.glassLight,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              FractionallySizedBox(
                widthFactor: progress,
                child: Container(
                  height: 10,
                  decoration: BoxDecoration(
                    gradient: progress >= 1
                        ? AppColors.successGradient
                        : AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _Stat(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 15,
            color: color == AppColors.textSecondary ? AppColors.textPrimary : color,
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _InfoRow(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w800,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}