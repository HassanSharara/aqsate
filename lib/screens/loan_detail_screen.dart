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

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
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
                      if (loan.status == LoanStatus.completed)
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
                                'تم سداد القرض بالكامل',
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
                          columnSpacing: 22,
                          columns: const [
                            DataColumn(label: Text('الشهر')),
                            DataColumn(label: Text('تاريخ الاستحقاق')),
                            DataColumn(label: Text('ربح مجدول')),
                            DataColumn(label: Text('التسديد')),
                            DataColumn(label: Text('متبقي أصل')),
                            DataColumn(label: Text('متبقي ربح')),
                            DataColumn(label: Text('المتبقي الكلي')),
                            DataColumn(label: Text('')),
                          ],
                          rows: rows.map((r) => _buildRow(context, r)).toList(),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  DataRow _buildRow(BuildContext context, InstallmentRow r) {
    final inst = r.installment;
    final paid = inst.paymentAmount > 0;
    final completed = r.remainingTotal <= 0.01;

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
        DataCell(Text(Formatters.date(inst.dueDate))),
        DataCell(Text(Formatters.currency(inst.scheduledProfit),
            style: const TextStyle(color: AppColors.accent))),
        DataCell(
          paid
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle_rounded, size: 14, color: AppColors.success),
                    const SizedBox(width: 5),
                    Text(
                      Formatters.currency(inst.paymentAmount),
                      style: const TextStyle(
                        color: AppColors.success,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                )
              : const Text('—', style: TextStyle(color: AppColors.textSecondary)),
        ),
        DataCell(Text(Formatters.currency(r.remainingPrincipal))),
        DataCell(Text(Formatters.currency(r.remainingProfit))),
        DataCell(
          Text(
            Formatters.currency(r.remainingTotal),
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
        DataCell(
          _PaymentIconButton(
            paid: paid,
            onPressed: () => _showPaymentDialog(context, inst),
          ),
        ),
      ],
    );
  }

  void _showPaymentDialog(BuildContext context, Installment inst) {
    final ctrl = TextEditingController(
        text: inst.paymentAmount > 0 ? inst.paymentAmount.round().toString() : '');
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
          width: 340,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.accent.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, color: AppColors.accent, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'ربح هذا الشهر مجدول بـ: ${Formatters.currency(inst.scheduledProfit)}',
                      style: const TextStyle(color: AppColors.accent, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: ctrl,
                autofocus: true,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'مبلغ التسديد (د.ع)',
                  prefixIcon: Icon(Icons.payments_outlined),
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

// ─────────────────────────────────────────
// Summary Header
// ─────────────────────────────────────────
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
          // Stats
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

          // Progress
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
