import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/loan.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import 'loan_detail_screen.dart';
import 'select_customer_dialog.dart';

class LoansScreen extends StatefulWidget {
  const LoansScreen({super.key});

  @override
  State<LoansScreen> createState() => _LoansScreenState();
}

enum _FilterMode { all, active, completed }

class _LoansScreenState extends State<LoansScreen> {
  _FilterMode _filter = _FilterMode.all;
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final customersById = {for (final c in provider.customers) c.id: c};

    List<Loan> loans = provider.allLoans;
    if (_filter == _FilterMode.active) {
      loans = loans.where((l) => l.status == LoanStatus.active).toList();
    } else if (_filter == _FilterMode.completed) {
      loans = loans.where((l) => l.status == LoanStatus.completed).toList();
    }
    if (_query.isNotEmpty) {
      loans = loans.where((l) {
        final c = customersById[l.customerId];
        return (c?.name ?? '').toLowerCase().contains(_query.toLowerCase());
      }).toList();
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('الأقساط والقروض'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(left: 20),
            child: _NewLoanButton(onTap: () => _showSelectCustomer(context)),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(28, 8, 28, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary strip
            _LoansSummaryStrip(loans: provider.allLoans),
            const SizedBox(height: 20),

            // Filters row
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'ابحث باسم العميل...',
                      prefixIcon: Icon(Icons.search_rounded),
                    ),
                    onChanged: (v) => setState(() => _query = v),
                  ),
                ),
                const SizedBox(width: 16),
                SegmentedButton<_FilterMode>(
                  segments: const [
                    ButtonSegment(value: _FilterMode.all, label: Text('الكل')),
                    ButtonSegment(value: _FilterMode.active, label: Text('نشطة')),
                    ButtonSegment(value: _FilterMode.completed, label: Text('مكتملة')),
                  ],
                  selected: {_filter},
                  onSelectionChanged: (s) => setState(() => _filter = s.first),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Table
            Expanded(
              child: loans.isEmpty
                  ? _EmptyState(
                      isFiltered: _query.isNotEmpty || _filter != _FilterMode.all,
                      onAddLoan: () => _showSelectCustomer(context),
                    )
                  : GlassContainer(
                      borderRadius: BorderRadius.circular(18),
                      padding: EdgeInsets.zero,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: SingleChildScrollView(
                          child: _LoansTable(
                            loans: loans,
                            customersById: customersById,
                            onRowTap: (loan) {
                              final c = customersById[loan.customerId];
                              if (c == null) return;
                              Navigator.of(context).push(MaterialPageRoute(
                                builder: (_) =>
                                    LoanDetailScreen(loan: loan, customerName: c.name),
                              ));
                            },
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSelectCustomer(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => const SelectCustomerDialog(),
    );
  }
}

// ─────────────────────────────────────────
// New Loan Button
// ─────────────────────────────────────────
class _NewLoanButton extends StatefulWidget {
  final VoidCallback onTap;
  const _NewLoanButton({required this.onTap});

  @override
  State<_NewLoanButton> createState() => _NewLoanButtonState();
}

class _NewLoanButtonState extends State<_NewLoanButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        transform: _hovered
            ? (Matrix4.identity()..scale(1.04))
            : Matrix4.identity(),
        transformAlignment: Alignment.center,
        child: GestureDetector(
          onTap: widget.onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(14),
              boxShadow: _hovered
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.45),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      )
                    ]
                  : [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      )
                    ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add_rounded, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text(
                  'قرض / قسط جديد',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// Summary strip
// ─────────────────────────────────────────
class _LoansSummaryStrip extends StatelessWidget {
  final List<Loan> loans;
  const _LoansSummaryStrip({required this.loans});

  @override
  Widget build(BuildContext context) {
    final active = loans.where((l) => l.status == LoanStatus.active).length;
    final completed = loans.where((l) => l.status == LoanStatus.completed).length;
    final totalPrincipal = loans.fold<double>(0, (s, l) => s + l.principalAmount);

    return Row(
      children: [
        _StripItem(
          icon: Icons.receipt_long_rounded,
          label: 'إجمالي القروض',
          value: '${loans.length}',
          color: AppColors.info,
        ),
        const SizedBox(width: 12),
        _StripItem(
          icon: Icons.hourglass_bottom_rounded,
          label: 'نشطة',
          value: '$active',
          color: AppColors.warning,
        ),
        const SizedBox(width: 12),
        _StripItem(
          icon: Icons.check_circle_rounded,
          label: 'مكتملة',
          value: '$completed',
          color: AppColors.success,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StripItem(
            icon: Icons.account_balance_wallet_rounded,
            label: 'إجمالي رأس المال',
            value: Formatters.currency(totalPrincipal),
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }
}

class _StripItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StripItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      borderRadius: BorderRadius.circular(14),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
              Text(
                label,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 11.5),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
// Table
// ─────────────────────────────────────────
class _LoansTable extends StatelessWidget {
  final List<Loan> loans;
  final Map<int?, dynamic> customersById;
  final void Function(Loan) onRowTap;

  const _LoansTable({
    required this.loans,
    required this.customersById,
    required this.onRowTap,
  });

  @override
  Widget build(BuildContext context) {
    return DataTable(
      columns: const [
        DataColumn(label: Text('العميل')),
        DataColumn(label: Text('المبلغ الأصلي')),
        DataColumn(label: Text('الأرباح')),
        DataColumn(label: Text('المبلغ الكلي')),
        DataColumn(label: Text('الأشهر')),
        DataColumn(label: Text('البداية')),
        DataColumn(label: Text('الحالة')),
      ],
      rows: loans.map((l) {
        final c = customersById[l.customerId];
        return DataRow(
          onSelectChanged: (_) => onRowTap(l),
          cells: [
            DataCell(
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.primary.withOpacity(0.18),
                    child: Text(
                      c?.name.isNotEmpty == true ? c!.name[0] : '?',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(c?.name ?? '—',
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                ],
              ),
            ),
            DataCell(Text(Formatters.currency(l.principalAmount))),
            DataCell(Text(Formatters.currency(l.profitAmount),
                style: const TextStyle(color: AppColors.accent))),
            DataCell(Text(Formatters.currency(l.totalAmount),
                style: const TextStyle(fontWeight: FontWeight.w700))),
            DataCell(Text('${l.months} شهر')),
            DataCell(Text(Formatters.date(l.startDate))),
            DataCell(_StatusBadge(status: l.status)),
          ],
        );
      }).toList(),
    );
  }
}

// ─────────────────────────────────────────
// Status badge
// ─────────────────────────────────────────
class _StatusBadge extends StatelessWidget {
  final LoanStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final active = status == LoanStatus.active;
    final gradient = active ? AppColors.accentGradient : AppColors.successGradient;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (active ? AppColors.warning : AppColors.success).withOpacity(0.3),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        status.label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// Empty state
// ─────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final bool isFiltered;
  final VoidCallback onAddLoan;

  const _EmptyState({required this.isFiltered, required this.onAddLoan});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.glassLight,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.glassBorder),
            ),
            child: Icon(
              isFiltered ? Icons.search_off_rounded : Icons.receipt_long_rounded,
              size: 40,
              color: AppColors.textSecondary.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            isFiltered ? 'لا توجد قروض مطابقة للبحث' : 'لا توجد قروض بعد',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isFiltered ? 'جرب تغيير مصطلح البحث أو الفلتر' : 'ابدأ بإنشاء قرض جديد لأحد عملائك',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13.5),
          ),
          if (!isFiltered) ...[
            const SizedBox(height: 24),
            GestureDetector(
              onTap: onAddLoan,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_rounded, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'قرض / قسط جديد',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
