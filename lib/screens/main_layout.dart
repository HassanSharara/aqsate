import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/loan.dart';
import '../models/customer.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import 'loan_detail_screen.dart';
import 'select_customer_dialog.dart';
import 'loan_form_dialog.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'dashboard_screen.dart';
import 'customers_screen.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  final List<_NavItem> _items = const [
    _NavItem('لوحة التحكم', Icons.dashboard_rounded, Icons.dashboard_outlined),
    _NavItem('العملاء', Icons.people_alt_rounded, Icons.people_alt_outlined),
    _NavItem('الأقساط والقروض', Icons.receipt_long_rounded, Icons.receipt_long_outlined),
  ];

  final List<Widget> _screens = const [
    DashboardScreen(),
    CustomersScreen(),
    LoansScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 220));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  void _onSelect(int i) {
    if (i == _selectedIndex) return;
    _animCtrl.reverse().then((_) {
      setState(() => _selectedIndex = i);
      _animCtrl.forward();
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isWide = constraints.maxWidth >= 900;
        final bool isMedium = constraints.maxWidth >= 640 && constraints.maxWidth < 900;

        return Container(
          decoration: const BoxDecoration(gradient: AppColors.appBackground),
          child: isWide || isMedium
              ? Row(
            children: [
              _SideNav(
                items: _items,
                selectedIndex: _selectedIndex,
                extended: isWide,
                onSelect: _onSelect,
              ),
              Expanded(
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: _screens[_selectedIndex],
                ),
              ),
            ],
          )
              : Scaffold(
            backgroundColor: Colors.transparent,
            body: FadeTransition(
              opacity: _fadeAnim,
              child: _screens[_selectedIndex],
            ),
            bottomNavigationBar: _BottomNav(
              items: _items,
              selectedIndex: _selectedIndex,
              onSelect: _onSelect,
            ),
          ),
        );
      },
    );
  }
}

class _NavItem {
  final String label;
  final IconData icon;
  final IconData iconOutlined;
  const _NavItem(this.label, this.icon, this.iconOutlined);
}

class _SideNav extends StatelessWidget {
  final List<_NavItem> items;
  final int selectedIndex;
  final bool extended;
  final ValueChanged<int> onSelect;

  const _SideNav({
    required this.items,
    required this.selectedIndex,
    required this.extended,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          width: extended ? 260 : 80,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xCC071525), Color(0xBB0C1E35)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            border: Border(
              right: BorderSide(color: AppColors.glassBorder, width: 1),
            ),
          ),
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    extended ? 22 : 12,
                    28,
                    extended ? 22 : 12,
                    20,
                  ),
                  child: Row(
                    mainAxisAlignment: extended ? MainAxisAlignment.start : MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.primary, Color(0xFF0099CC)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.savings_rounded, color: Colors.white, size: 24),
                      ),
                      if (extended) ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'اقساطي',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              Text(
                                'إدارة القروض والأقساط',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.45),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: extended ? 16 : 10, vertical: 4),
                  child: Divider(color: Colors.white.withOpacity(0.08), thickness: 1),
                ),
                const SizedBox(height: 8),
                for (int i = 0; i < items.length; i++)
                  _SideNavTile(
                    item: items[i],
                    selected: i == selectedIndex,
                    extended: extended,
                    onTap: () => onSelect(i),
                  ),
                const Spacer(),
                if (extended)
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                          ),
                          child: const Text(
                            'v 1.0',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SideNavTile extends StatefulWidget {
  final _NavItem item;
  final bool selected;
  final bool extended;
  final VoidCallback onTap;

  const _SideNavTile({
    required this.item,
    required this.selected,
    required this.extended,
    required this.onTap,
  });

  @override
  State<_SideNavTile> createState() => _SideNavTileState();
}

class _SideNavTileState extends State<_SideNavTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final selected = widget.selected;
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: widget.extended ? 12 : 8,
        vertical: 3,
      ),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary.withOpacity(0.18)
                : _hovered
                ? Colors.white.withOpacity(0.06)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(13),
            border: selected
                ? Border.all(color: AppColors.primary.withOpacity(0.35), width: 1)
                : Border.all(color: Colors.transparent),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(13),
              onTap: widget.onTap,
              splashColor: AppColors.primary.withOpacity(0.1),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  vertical: 13,
                  horizontal: widget.extended ? 14 : 0,
                ),
                child: Row(
                  mainAxisAlignment: widget.extended ? MainAxisAlignment.start : MainAxisAlignment.center,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        selected ? widget.item.icon : widget.item.iconOutlined,
                        key: ValueKey(selected),
                        color: selected ? AppColors.primary : Colors.white.withOpacity(0.55),
                        size: 22,
                      ),
                    ),
                    if (widget.extended) ...[
                      const SizedBox(width: 13),
                      Expanded(
                        child: Text(
                          widget.item.label,
                          style: TextStyle(
                            color: selected ? AppColors.textPrimary : Colors.white.withOpacity(0.6),
                            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                            fontSize: 14.5,
                          ),
                        ),
                      ),
                      if (selected)
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final List<_NavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  const _BottomNav({
    required this.items,
    required this.selectedIndex,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xCC071525),
            border: Border(top: BorderSide(color: AppColors.glassBorder)),
          ),
          child: NavigationBar(
            backgroundColor: Colors.transparent,
            indicatorColor: AppColors.primary.withOpacity(0.18),
            selectedIndex: selectedIndex,
            onDestinationSelected: onSelect,
            labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
            destinations: items
                .map((e) => NavigationDestination(
              icon: Icon(e.iconOutlined, color: Colors.white54),
              selectedIcon: Icon(e.icon, color: AppColors.primary),
              label: e.label,
            ))
                .toList(),
          ),
        ),
      ),
    );
  }
}
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
            _LoansSummaryStrip(loans: provider.allLoans),
            const SizedBox(height: 20),
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
                    scrollDirection: Axis.horizontal,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.vertical,
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
                        onEditTap: (loan) {
                          final c = customersById[loan.customerId];
                          if (c == null) return;
                          _showEditLoanDialog(context, loan, c);
                        },
                        onDeleteTap: (loan) {
                          final c = customersById[loan.customerId];
                          if (c == null) return;
                          _showDeleteConfirmDialog(context, loan, c.name);
                        },
                      ),
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

  void _showEditLoanDialog(BuildContext context, Loan loan, Customer customer) {
    showDialog(
      context: context,
      builder: (_) => LoanFormDialog(
        customer: customer,
        loan: loan,
      ),
    );
  }

  void _showDeleteConfirmDialog(BuildContext context, Loan loan, String customerName) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.danger.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.warning_amber_rounded, color: AppColors.danger, size: 20),
            ),
            const SizedBox(width: 12),
            const Text('تأكيد حذف القرض'),
          ],
        ),
        content: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'هل أنت متأكد من رغبتك في حذف قرض العميل ($customerName)؟',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.danger.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.danger.withOpacity(0.2)),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, color: AppColors.danger, size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'تنبيه: سيؤدي هذا الإجراء إلى حذف كافة تفاصيل الأقساط والدفعات المسجلة المرتبطة بهذا القرض نهائياً ولا يمكن التراجع عنه.',
                        style: TextStyle(color: AppColors.danger, fontSize: 12, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              context.read<AppProvider>().deleteLoan(loan.id!);
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('تم حذف القرض والبيانات التابعة له بنجاح'),
                  backgroundColor: AppColors.danger,
                ),
              );
            },
            child: const Text('حذف نهائي'),
          ),
        ],
      ),
    );
  }
}

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

class _LoansTable extends StatelessWidget {
  final List<Loan> loans;
  final Map<int?, dynamic> customersById;
  final void Function(Loan) onRowTap;
  final void Function(Loan) onEditTap;
  final void Function(Loan) onDeleteTap;

  const _LoansTable({
    required this.loans,
    required this.customersById,
    required this.onRowTap,
    required this.onEditTap,
    required this.onDeleteTap,
  });

  @override
  Widget build(BuildContext context) {
    return DataTable(
      showCheckboxColumn: false,
      columns: const [
        DataColumn(label: Text('العميل')),
        DataColumn(label: Text('المبلغ الأصلي')),
        DataColumn(label: Text('الأرباح')),
        DataColumn(label: Text('المبلغ الكلي')),
        DataColumn(label: Text('الأشهر')),
        DataColumn(label: Text('البداية')),
        DataColumn(label: Text('الحالة')),
        DataColumn(label: Text('إجراءات')),
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
            DataCell(
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_note_rounded, color: AppColors.primary, size: 22),
                    tooltip: 'تعديل القرض',
                    onPressed: () => onEditTap(l),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger, size: 20),
                    tooltip: 'حذف القرض',
                    onPressed: () => onDeleteTap(l),
                  ),
                ],
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}

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