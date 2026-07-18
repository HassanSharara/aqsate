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
  final Loan? loan;

  const LoanFormDialog({super.key, required this.customer, this.loan});

  @override
  State<LoanFormDialog> createState() => _LoanFormDialogState();
}

class _LoanFormDialogState extends State<LoanFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _principalCtrl;
  late final TextEditingController _profitCtrl;
  late final TextEditingController _expectedInstallmentCtrl;
  late final TextEditingController _monthsCtrl;
  late DateTime _startDate;
  late ProfitDistributionMode _mode;

  List<TextEditingController> _manualControllers = [];

  bool get _isEditing => widget.loan != null;

  @override
  void initState() {
    super.initState();
    
    final double initPrincipal = _isEditing ? widget.loan!.principalAmount : 1000000;
    final double initProfit = _isEditing ? widget.loan!.profitAmount : 350000;
    final double initExpectedInstallment = _isEditing 
        ? ((widget.loan!.principalAmount + widget.loan!.profitAmount) / widget.loan!.months)
        : (initPrincipal * 0.1);
    final int initMonths = _isEditing 
        ? widget.loan!.months 
        : ((initPrincipal + initProfit) / initExpectedInstallment).ceil();

    _principalCtrl = TextEditingController(text: initPrincipal.round().toString());
    _profitCtrl = TextEditingController(text: initProfit.round().toString());
    _expectedInstallmentCtrl = TextEditingController(text: initExpectedInstallment.round().toString());
    _monthsCtrl = TextEditingController(text: initMonths.toString());
    _startDate = _isEditing ? DateTime.parse(widget.loan!.startDate) : DateTime.now();
    _mode = _isEditing ? widget.loan!.distributionMode : ProfitDistributionMode.auto;

    // No global listeners, we use onChanged in the UI to prevent recursive loops!
    if (_mode == ProfitDistributionMode.manual) {
      _syncManualControllers();
    }
  }

  @override
  void dispose() {
    _principalCtrl.dispose();
    _profitCtrl.dispose();
    _expectedInstallmentCtrl.dispose();
    _monthsCtrl.dispose();
    for (final c in _manualControllers) {
      c.dispose();
    }
    super.dispose();
  }

  double get _principal => double.tryParse(_principalCtrl.text) ?? 0;
  double get _profit => double.tryParse(_profitCtrl.text) ?? 0;
  int get _months => int.tryParse(_monthsCtrl.text) ?? 0;

  void _onPrincipalChanged(String val) {
    final principal = double.tryParse(val) ?? 0;
    final defaultInstallment = (principal / 1000000.0) * 100000.0;
    final defaultProfit = principal * 0.35;
    
    _expectedInstallmentCtrl.text = defaultInstallment > 0 ? defaultInstallment.round().toString() : '';
    _profitCtrl.text = defaultProfit > 0 ? defaultProfit.round().toString() : '';
    
    final total = principal + defaultProfit;
    if (defaultInstallment > 0) {
      final months = (total / defaultInstallment).ceil();
      _monthsCtrl.text = months.toString();
    }
    _syncManualControllers();
    setState(() {});
  }

  void _onProfitChanged(String val) {
    final principal = double.tryParse(_principalCtrl.text) ?? 0;
    final profit = double.tryParse(val) ?? 0;
    final installment = double.tryParse(_expectedInstallmentCtrl.text) ?? ((principal / 1000000.0) * 100000.0);
    
    final total = principal + profit;
    if (installment > 0) {
      final months = (total / installment).ceil();
      _monthsCtrl.text = months.toString();
    }
    _syncManualControllers();
    setState(() {});
  }

  void _onExpectedInstallmentChanged(String val) {
    final principal = double.tryParse(_principalCtrl.text) ?? 0;
    final profit = double.tryParse(_profitCtrl.text) ?? 0;
    final installment = double.tryParse(val) ?? 0;
    
    final total = principal + profit;
    if (installment > 0) {
      final months = (total / installment).ceil();
      _monthsCtrl.text = months.toString();
    }
    _syncManualControllers();
    setState(() {});
  }

  void _onMonthsChanged(String val) {
    final principal = double.tryParse(_principalCtrl.text) ?? 0;
    final profit = double.tryParse(_profitCtrl.text) ?? 0;
    final months = int.tryParse(val) ?? 0;
    
    final total = principal + profit;
    if (months > 0) {
      final installment = total / months;
      _expectedInstallmentCtrl.text = installment.round().toString();
    }
    _syncManualControllers();
    setState(() {});
  }

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
      ProfitCalculator.generateAutoSchedule(
        totalProfit: _profit,
        months: _months.clamp(0, 60),
        principalAmount: _principal,
      );

  @override
  Widget build(BuildContext context) {
    final initials = widget.customer.name.isNotEmpty ? widget.customer.name[0] : '?';

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640, maxHeight: 760),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Icon(
                        _isEditing ? Icons.edit_note_rounded : Icons.add_card_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isEditing ? 'تعديل بيانات القرض' : 'قرض جديد',
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 9,
                                backgroundColor: AppColors.primary.withOpacity(0.2),
                                child: Text(
                                  initials,
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'لـ ${widget.customer.name}',
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                    ),
                  ],
                ),

                const SizedBox(height: 24),
                Divider(color: AppColors.glassBorder.withOpacity(0.5)),
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
                              decoration: const InputDecoration(
                                labelText: 'المبلغ الأصلي (د.ع)',
                                prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                              ),
                              onChanged: _onPrincipalChanged,
                              validator: (v) =>
                              (double.tryParse(v ?? '') ?? 0) <= 0 ? 'أدخل مبلغاً صحيحاً' : null,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: TextFormField(
                              controller: _profitCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'الأرباح المطلوبة (د.ع)',
                                prefixIcon: Icon(Icons.trending_up_rounded),
                              ),
                              onChanged: _onProfitChanged,
                              validator: (v) =>
                              (double.tryParse(v ?? '') ?? -1) < 0 ? 'أدخل قيمة صحيحة' : null,
                            ),
                          ),
                        ]),

                        const SizedBox(height: 16),

                        if (_principal > 0 && _profit >= 0)
                          Container(
                            padding: const EdgeInsets.all(14),
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.primary.withOpacity(0.25)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _MiniStat('الكلي', Formatters.currency(_principal + _profit), AppColors.primary),
                                Container(width: 1, height: 36, color: AppColors.glassBorder),
                                _MiniStat(
                                  'نسبة الربح',
                                  _principal > 0
                                      ? '${((_profit / _principal) * 100).toStringAsFixed(1)}%'
                                      : '0%',
                                  AppColors.accent,
                                ),
                              ],
                            ),
                          ),

                        Row(children: [
                          Expanded(
                            child: TextFormField(
                              controller: _expectedInstallmentCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'القسط الشهري المتوقع (د.ع)',
                                prefixIcon: Icon(Icons.payments_rounded),
                              ),
                              onChanged: _onExpectedInstallmentChanged,
                              validator: (v) =>
                              (double.tryParse(v ?? '') ?? 0) <= 0 ? 'أدخل قسطاً صحيحاً' : null,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: TextFormField(
                              controller: _monthsCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'عدد أشهر التسديد',
                                prefixIcon: Icon(Icons.calendar_month_outlined),
                              ),
                              onChanged: _onMonthsChanged,
                              validator: (v) {
                                final n = int.tryParse(v ?? '');
                                if (n == null || n <= 0) return 'أدخل عدد أشهر صحيح';
                                if (n > 60) return 'الحد الأقصى 60 شهر';
                                return null;
                              },
                            ),
                          ),
                        ]),

                        const SizedBox(height: 16),

                        InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _startDate,
                              firstDate: DateTime(2015),
                              lastDate: DateTime(2100),
                            );
                            if (picked != null) setState(() => _startDate = picked);
                          },
                          borderRadius: BorderRadius.circular(14),
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'تاريخ بداية القرض',
                              prefixIcon: Icon(Icons.calendar_today_outlined),
                            ),
                            child: Text(
                              Formatters.date(_startDate.toIso8601String()),
                              style: const TextStyle(color: AppColors.textPrimary),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        const Text(
                          'طريقة توزيع الأرباح على الأشهر',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 10),
                        SegmentedButton<ProfitDistributionMode>(
                          segments: const [
                            ButtonSegment(
                              value: ProfitDistributionMode.auto,
                              label: Text('تلقائي (متناقص)'),
                              icon: Icon(Icons.auto_graph_rounded, size: 16),
                            ),
                            ButtonSegment(
                              value: ProfitDistributionMode.manual,
                              label: Text('يدوي (تعديل كل شهر)'),
                              icon: Icon(Icons.edit_calendar_rounded, size: 16),
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

                        const SizedBox(height: 20),

                        if (_months > 0 && _profit >= 0) _buildSchedulePreview(),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

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
                        child: Text(_isEditing ? 'تحديث القرض' : 'إنشاء القرض'),
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
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'جدول التوزيع التلقائي',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.glassMid,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.glassBorder),
            ),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (int i = 0; i < preview.length; i++)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.primary.withOpacity(0.25)),
                    ),
                    child: Text(
                      'ش${i + 1}: ${Formatters.number(preview[i])}',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
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
                  decoration: InputDecoration(
                    labelText: 'ربح ش${i + 1}',
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: (diff.abs() < 1 ? AppColors.success : AppColors.danger).withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: (diff.abs() < 1 ? AppColors.success : AppColors.danger).withOpacity(0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                diff.abs() < 1 ? Icons.check_circle_rounded : Icons.warning_rounded,
                size: 16,
                color: diff.abs() < 1 ? AppColors.success : AppColors.danger,
              ),
              const SizedBox(width: 8),
              Text(
                diff.abs() < 1
                    ? 'المجموع مطابق للأرباح المطلوبة ✓'
                    : 'الفرق عن الإجمالي: ${Formatters.number(diff)} د.ع',
                style: TextStyle(
                  color: diff.abs() < 1 ? AppColors.success : AppColors.danger,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
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
      id: _isEditing ? widget.loan!.id : null,
      customerId: widget.customer.id!,
      principalAmount: _principal,
      profitAmount: _profit,
      months: _months,
      startDate: _startDate.toIso8601String().split('T').first,
      distributionMode: _mode,
      createdAt: _isEditing ? widget.loan!.createdAt : Formatters.todayIso(),
      status: _isEditing ? widget.loan!.status : LoanStatus.active,
    );

    final provider = context.read<AppProvider>();

    if (_isEditing) {
      provider.updateLoan(loan);
    } else {
      provider.createLoan(loan: loan, manualProfitSchedule: manualSchedule);
    }

    Navigator.pop(context);
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _MiniStat(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 16),
        ),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
      ],
    );
  }
}