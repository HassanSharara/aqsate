import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/customer.dart';
import '../models/loan.dart';
import '../services/profit_calculator.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

class LoanFormDialog extends StatefulWidget {
  final Customer customer;
  const LoanFormDialog({super.key, required this.customer});

  @override
  State<LoanFormDialog> createState() => _LoanFormDialogState();
}

class _LoanFormDialogState extends State<LoanFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _principalCtrl = TextEditingController(text: '1000000');
  final _profitCtrl = TextEditingController(text: '350000');
  final _monthsCtrl = TextEditingController(text: '10');
  DateTime _startDate = DateTime.now();
  ProfitDistributionMode _mode = ProfitDistributionMode.auto;

  List<TextEditingController> _manualControllers = [];

  @override
  void initState() {
    super.initState();
    _principalCtrl.addListener(_refreshPreview);
    _profitCtrl.addListener(_refreshPreview);
    _monthsCtrl.addListener(_onMonthsChanged);
  }

  double get _principal => double.tryParse(_principalCtrl.text) ?? 0;
  double get _profit => double.tryParse(_profitCtrl.text) ?? 0;
  int get _months => int.tryParse(_monthsCtrl.text) ?? 0;

  void _onMonthsChanged() {
    _syncManualControllers();
    setState(() {});
  }

  void _refreshPreview() => setState(() {});

  void _syncManualControllers() {
    final n = _months.clamp(0, 60);
    if (_manualControllers.length == n) return;
    final equal = ProfitCalculator.generateEqualSchedule(totalProfit: _profit, months: n);
    _manualControllers = List.generate(
      n,
      (i) => TextEditingController(text: equal.isEmpty ? '0' : equal[i].round().toString()),
    );
  }

  List<double> get _autoPreview =>
      ProfitCalculator.generateAutoSchedule(totalProfit: _profit, months: _months.clamp(0, 60));

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620, maxHeight: 720),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('قرض جديد لـ ${widget.customer.name}', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 20),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Expanded(
                            child: TextFormField(
                              controller: _principalCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'المبلغ الأصلي (د.ع)'),
                              validator: (v) =>
                                  (double.tryParse(v ?? '') ?? 0) <= 0 ? 'أدخل مبلغاً صحيحاً' : null,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: TextFormField(
                              controller: _profitCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'الأرباح المطلوبة (د.ع)'),
                              validator: (v) =>
                                  (double.tryParse(v ?? '') ?? -1) < 0 ? 'أدخل قيمة صحيحة' : null,
                            ),
                          ),
                        ]),
                        const SizedBox(height: 14),
                        Row(children: [
                          Expanded(
                            child: TextFormField(
                              controller: _monthsCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'عدد أشهر التسديد'),
                              validator: (v) {
                                final n = int.tryParse(v ?? '');
                                if (n == null || n <= 0) return 'أدخل عدد أشهر صحيح';
                                if (n > 60) return 'الحد الأقصى 60 شهر';
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: _startDate,
                                  firstDate: DateTime(2015),
                                  lastDate: DateTime(2100),
                                );
                                if (picked != null) setState(() => _startDate = picked);
                              },
                              child: InputDecorator(
                                decoration: const InputDecoration(labelText: 'تاريخ بداية القرض'),
                                child: Text(Formatters.date(_startDate.toIso8601String())),
                              ),
                            ),
                          ),
                        ]),
                        const SizedBox(height: 18),
                        Text('طريقة توزيع الأرباح على الأشهر',
                            style: Theme.of(context).textTheme.titleSmall),
                        const SizedBox(height: 8),
                        SegmentedButton<ProfitDistributionMode>(
                          segments: const [
                            ButtonSegment(
                              value: ProfitDistributionMode.auto,
                              label: Text('تلقائي (متناقص)'),
                              icon: Icon(Icons.auto_graph_rounded),
                            ),
                            ButtonSegment(
                              value: ProfitDistributionMode.manual,
                              label: Text('يدوي (تعديل كل شهر)'),
                              icon: Icon(Icons.edit_calendar_rounded),
                            ),
                          ],
                          selected: {_mode},
                          onSelectionChanged: (s) {
                            setState(() {
                              _mode = s.first;
                              if (_mode == ProfitDistributionMode.manual) _syncManualControllers();
                            });
                          },
                        ),
                        const SizedBox(height: 18),
                        if (_months > 0 && _profit >= 0) _buildSchedulePreview(),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('إلغاء'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _save,
                        child: const Text('إنشاء القرض'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSchedulePreview() {
    final isAuto = _mode == ProfitDistributionMode.auto;
    if (isAuto) {
      final preview = _autoPreview;
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFDDE4E2)),
        ),
        child: Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (int i = 0; i < preview.length; i++)
              Chip(
                label: Text('ش${i + 1}: ${Formatters.number(preview[i])}'),
                backgroundColor: Colors.white,
                side: const BorderSide(color: Color(0xFFDDE4E2)),
              ),
          ],
        ),
      );
    }

    _syncManualControllers();
    final sum = _manualControllers.fold<double>(0, (s, c) => s + (double.tryParse(c.text) ?? 0));
    final diff = _profit - sum;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (int i = 0; i < _manualControllers.length; i++)
              SizedBox(
                width: 110,
                child: TextField(
                  controller: _manualControllers[i],
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: 'ربح ش${i + 1}'),
                  onChanged: (_) => setState(() {}),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          diff.abs() < 1 ? 'المجموع مطابق للأرباح المطلوبة ✓' : 'الفرق عن الإجمالي: ${Formatters.number(diff)} د.ع',
          style: TextStyle(color: diff.abs() < 1 ? AppColors.success : AppColors.danger, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    List<double>? manualSchedule;
    if (_mode == ProfitDistributionMode.manual) {
      manualSchedule = _manualControllers.map((c) => double.tryParse(c.text) ?? 0).toList();
    }

    final loan = Loan(
      customerId: widget.customer.id!,
      principalAmount: _principal,
      profitAmount: _profit,
      months: _months,
      startDate: _startDate.toIso8601String().split('T').first,
      distributionMode: _mode,
      createdAt: Formatters.todayIso(),
    );

    context.read<AppProvider>().createLoan(loan: loan, manualProfitSchedule: manualSchedule);
    Navigator.pop(context);
  }
}
