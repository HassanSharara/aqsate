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
    // إعادة قراءة القرض المحدث (حالته قد تكون تغيّرت) من المزود
    final provider = context.watch<AppProvider>();
    final loan = provider.allLoans.firstWhere((l) => l.id == widget.loan.id, orElse: () => widget.loan);

    final rows = ProfitCalculator.calculateRows(
      principalAmount: loan.principalAmount,
      totalProfit: loan.profitAmount,
      installments: _installments,
    );

    final totalPaid = rows.fold<double>(0, (s, r) => s + r.installment.paymentAmount);
    final remainingTotal = rows.isNotEmpty ? rows.last.remainingTotal : loan.totalAmount;

    return Scaffold(
      appBar: AppBar(
        title: Text('قرض ${widget.customerName}'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SummaryHeader(loan: loan, totalPaid: totalPaid, remainingTotal: remainingTotal),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('جدول الأقساط', style: Theme.of(context).textTheme.titleLarge),
                      if (loan.status == LoanStatus.completed)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.success.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text('تم سداد القرض بالكامل ✓',
                              style: TextStyle(color: AppColors.success, fontWeight: FontWeight.w700)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Card(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columnSpacing: 22,
                        columns: const [
                          DataColumn(label: Text('الشهر')),
                          DataColumn(label: Text('تاريخ الاستحقاق')),
                          DataColumn(label: Text('ربح الشهر المجدول')),
                          DataColumn(label: Text('التسديد')),
                          DataColumn(label: Text('المتبقي من المبلغ الأصلي')),
                          DataColumn(label: Text('المتبقي من الأرباح')),
                          DataColumn(label: Text('المتبقي الكلي')),
                          DataColumn(label: Text('')),
                        ],
                        rows: rows.map((r) => _buildRow(context, r)).toList(),
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
    return DataRow(
      color: WidgetStateProperty.resolveWith((states) {
        if (r.remainingTotal <= 0.01) return AppColors.success.withOpacity(0.05);
        return null;
      }),
      cells: [
        DataCell(Text('${inst.monthIndex}', style: const TextStyle(fontWeight: FontWeight.w700))),
        DataCell(Text(Formatters.date(inst.dueDate))),
        DataCell(Text(Formatters.currency(inst.scheduledProfit))),
        DataCell(
          Text(
            paid ? Formatters.currency(inst.paymentAmount) : '—',
            style: TextStyle(
              color: paid ? AppColors.textPrimary : AppColors.textSecondary,
              fontWeight: paid ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
        ),
        DataCell(Text(Formatters.currency(r.remainingPrincipal))),
        DataCell(Text(Formatters.currency(r.remainingProfit))),
        DataCell(Text(Formatters.currency(r.remainingTotal),
            style: const TextStyle(fontWeight: FontWeight.w800))),
        DataCell(
          IconButton(
            icon: Icon(paid ? Icons.edit_rounded : Icons.payments_rounded,
                size: 20, color: AppColors.primary),
            tooltip: paid ? 'تعديل الدفعة' : 'تسجيل دفعة',
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('تسديد قسط الشهر ${inst.monthIndex}'),
        content: SizedBox(
          width: 340,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('ربح هذا الشهر مجدول بـ: ${Formatters.currency(inst.scheduledProfit)}',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              const SizedBox(height: 14),
              TextField(
                controller: ctrl,
                autofocus: true,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'مبلغ التسديد (د.ع)'),
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
            child: const Text('حفظ'),
          ),
        ],
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
        loan.totalAmount == 0 ? 0.0 : (1 - (remainingTotal / loan.totalAmount)).clamp(0.0, 1.0).toDouble();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 36,
              runSpacing: 16,
              children: [
                _stat('المبلغ الأصلي', Formatters.currency(loan.principalAmount)),
                _stat('إجمالي الأرباح', Formatters.currency(loan.profitAmount)),
                _stat('المبلغ الكلي', Formatters.currency(loan.totalAmount)),
                _stat('عدد الأشهر', '${loan.months} شهر'),
                _stat('طريقة التوزيع', loan.distributionMode.label),
                _stat('إجمالي المُسدَّد', Formatters.currency(totalPaid)),
                _stat('المتبقي الكلي', Formatters.currency(remainingTotal)),
              ],
            ),
            const SizedBox(height: 18),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 10,
                backgroundColor: const Color(0xFFE7ECEA),
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 6),
            Text('${(progress * 100).toStringAsFixed(0)}% مكتمل',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
          ],
        ),
      ),
    );
  }

  Widget _stat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
      ],
    );
  }
}
