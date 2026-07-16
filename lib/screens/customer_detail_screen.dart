import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/customer.dart';
import '../models/loan.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import 'loan_detail_screen.dart';
import 'loan_form_dialog.dart';

class CustomerDetailScreen extends StatelessWidget {
  final Customer customer;
  const CustomerDetailScreen({super.key, required this.customer});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final loans = provider.loansForCustomer(customer.id!);
    final totalPrincipal = loans.fold<double>(0, (s, l) => s + l.principalAmount);
    final totalProfit = loans.fold<double>(0, (s, l) => s + l.profitAmount);
    final activeLoans = loans.where((l) => l.status == LoanStatus.active).length;

    final initials = customer.name.isNotEmpty
        ? customer.name.trim().split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join()
        : '?';

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
                initials,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(customer.name),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(left: 20),
            child: _GradientActionButton(
              icon: Icons.add_rounded,
              label: 'قرض جديد',
              onTap: () => showDialog(
                context: context,
                builder: (_) => LoanFormDialog(customer: customer),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(28, 8, 28, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile card
            GlassContainer(
              padding: const EdgeInsets.all(24),
              borderRadius: BorderRadius.circular(20),
              child: Column(
                children: [
                  // Avatar + name row
                  Row(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.4),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          initials,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 22,
                          ),
                        ),
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              customer.name,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            if (customer.phone.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Row(
                                  children: [
                                    const Icon(Icons.phone_outlined,
                                        size: 14, color: AppColors.textSecondary),
                                    const SizedBox(width: 5),
                                    Text(
                                      customer.phone,
                                      style: const TextStyle(
                                          color: AppColors.textSecondary, fontSize: 13.5),
                                    ),
                                  ],
                                ),
                              ),
                            if (customer.address.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Row(
                                  children: [
                                    const Icon(Icons.location_on_outlined,
                                        size: 14, color: AppColors.textSecondary),
                                    const SizedBox(width: 5),
                                    Text(
                                      customer.address,
                                      style: const TextStyle(
                                          color: AppColors.textSecondary, fontSize: 13.5),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Divider(color: AppColors.glassBorder.withOpacity(0.5)),
                  const SizedBox(height: 16),

                  // Stats
                  Wrap(
                    spacing: 20,
                    runSpacing: 14,
                    children: [
                      _CustomerStat(
                        icon: Icons.receipt_long_rounded,
                        label: 'عدد القروض',
                        value: '${loans.length}',
                        color: AppColors.info,
                      ),
                      _CustomerStat(
                        icon: Icons.hourglass_bottom_rounded,
                        label: 'قروض نشطة',
                        value: '$activeLoans',
                        color: AppColors.warning,
                      ),
                      _CustomerStat(
                        icon: Icons.account_balance_wallet_rounded,
                        label: 'رأس المال المُقرض',
                        value: Formatters.currency(totalPrincipal),
                        color: AppColors.primary,
                      ),
                      _CustomerStat(
                        icon: Icons.trending_up_rounded,
                        label: 'إجمالي الأرباح',
                        value: Formatters.currency(totalProfit),
                        color: AppColors.accent,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // Loans section
            const Text(
              'سجل القروض',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),

            if (loans.isEmpty)
              GlassContainer(
                padding: const EdgeInsets.all(40),
                borderRadius: BorderRadius.circular(20),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.receipt_long_outlined,
                          size: 48, color: AppColors.textSecondary.withOpacity(0.4)),
                      const SizedBox(height: 12),
                      const Text(
                        'لا يوجد قروض بعد',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                      ),
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: () => showDialog(
                          context: context,
                          builder: (_) => LoanFormDialog(customer: customer),
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'أضف قرضاً الآن',
                            style: TextStyle(
                                color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13.5),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...loans.map(
                (l) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _LoanTile(loan: l, customerName: customer.name),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CustomerStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _CustomerStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
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

class _LoanTile extends StatefulWidget {
  final Loan loan;
  final String customerName;
  const _LoanTile({required this.loan, required this.customerName});

  @override
  State<_LoanTile> createState() => _LoanTileState();
}

class _LoanTileState extends State<_LoanTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final bool active = widget.loan.status == LoanStatus.active;
    final color = active ? AppColors.warning : AppColors.success;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        transform: _hovered
            ? (Matrix4.identity()..translate(0.0, -2.0))
            : Matrix4.identity(),
        decoration: BoxDecoration(
          color: AppColors.glassLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _hovered ? color.withOpacity(0.4) : AppColors.glassBorder,
          ),
          boxShadow: _hovered
              ? [BoxShadow(color: color.withOpacity(0.12), blurRadius: 12, offset: const Offset(0, 4))]
              : [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 6)],
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withOpacity(0.25)),
            ),
            child: Icon(
              active ? Icons.hourglass_bottom_rounded : Icons.check_circle_rounded,
              color: color,
              size: 20,
            ),
          ),
          title: Text(
            '${Formatters.currency(widget.loan.principalAmount)}  +  ربح ${Formatters.currency(widget.loan.profitAmount)}',
            style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                Icon(Icons.calendar_today_outlined, size: 12, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(
                  '${Formatters.date(widget.loan.startDate)}  •  ${widget.loan.months} شهر',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    widget.loan.status.label,
                    style: TextStyle(
                      color: color,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          trailing: const Icon(Icons.chevron_left_rounded, color: AppColors.textSecondary),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => LoanDetailScreen(
                loan: widget.loan,
                customerName: widget.customerName,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GradientActionButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _GradientActionButton({required this.icon, required this.label, required this.onTap});

  @override
  State<_GradientActionButton> createState() => _GradientActionButtonState();
}

class _GradientActionButtonState extends State<_GradientActionButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        transform: _hovered ? (Matrix4.identity()..scale(1.04)) : Matrix4.identity(),
        transformAlignment: Alignment.center,
        child: GestureDetector(
          onTap: widget.onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(_hovered ? 0.45 : 0.25),
                  blurRadius: _hovered ? 16 : 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(widget.icon, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text(
                  widget.label,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
