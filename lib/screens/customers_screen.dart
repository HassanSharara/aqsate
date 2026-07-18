import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/customer.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import 'customer_detail_screen.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final filtered = provider.customers
        .where((c) =>
            c.name.toLowerCase().contains(_query.toLowerCase()) ||
            c.phone.contains(_query))
        .toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('العملاء'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(left: 20),
            child: _GradientButton(
              icon: Icons.person_add_alt_1_rounded,
              label: 'عميل جديد',
              onTap: () => _showCustomerDialog(context),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(28, 8, 28, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stats bar
            _CustomersStatsBar(
              total: provider.customers.length,
              activeLoans: provider.activeLoanCount,
            ),
            const SizedBox(height: 20),

            // Search
            TextField(
              decoration: const InputDecoration(
                hintText: 'ابحث بالاسم أو رقم الهاتف...',
                prefixIcon: Icon(Icons.search_rounded),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
            const SizedBox(height: 20),

            // List / Table
            Expanded(
              child: filtered.isEmpty
                  ? _EmptyState(
                      hasQuery: _query.isNotEmpty,
                      onAdd: () => _showCustomerDialog(context),
                    )
                  : LayoutBuilder(builder: (context, c) {
                      if (c.maxWidth > 800) {
                        return _CustomersTable(customers: filtered, provider: provider);
                      }
                      return _CustomersList(customers: filtered);
                    }),
            ),
          ],
        ),
      ),
    );
  }

  void _showCustomerDialog(BuildContext context, {Customer? existing}) {
    showDialog(
      context: context,
      builder: (_) => _CustomerFormDialog(existing: existing),
    );
  }
}

// ─────────────────────────────────────────
// Stats bar
// ─────────────────────────────────────────
class _CustomersStatsBar extends StatelessWidget {
  final int total;
  final int activeLoans;
  const _CustomersStatsBar({required this.total, required this.activeLoans});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: GlassContainer(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            borderRadius: BorderRadius.circular(14),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.groups_rounded, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$total',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                    const Text(
                      'إجمالي العملاء',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GlassContainer(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            borderRadius: BorderRadius.circular(14),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: AppColors.infoGradient,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.receipt_long_rounded, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$activeLoans',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                    const Text(
                      'قروض نشطة',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────
// Table (wide)
// ─────────────────────────────────────────
class _CustomersTable extends StatelessWidget {
  final List<Customer> customers;
  final AppProvider provider;
  const _CustomersTable({required this.customers, required this.provider});

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.sizeOf(context);
    return GlassContainer(
      borderRadius: BorderRadius.circular(18),
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: SingleChildScrollView(
          child: SizedBox(
            width:size.width,
            child: DataTable(
              dataRowMinHeight:60,
              dataRowMaxHeight:100,
              showCheckboxColumn: false,
              dataTextStyle:TextStyle(fontSize:20),
              columns: const [
                DataColumn(label: Text('الاسم')),
                DataColumn(label: Text('الهاتف')),
                DataColumn(label: Text('العنوان')),
                DataColumn(label: Text('عدد القروض')),
                DataColumn(label: Text('')),
              ],
              rows: customers.map((c) {
                final loanCount = provider.loansForCustomer(c.id!).length;
                final initials = c.name.isNotEmpty ? c.name[0] : '?';
                return DataRow(cells: [
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: AppColors.primary.withOpacity(0.18),
                          child: Text(
                            initials,
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(c.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                      ],
                    ),
                    onTap: () => _open(context, c),
                  ),
                  DataCell(Text(c.phone.isEmpty ? '—' : c.phone)),
                  DataCell(Text(c.address.isEmpty ? '—' : c.address)),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: loanCount > 0
                            ? AppColors.info.withOpacity(0.15)
                            : AppColors.glassLight,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$loanCount',
                        style: TextStyle(
                          color: loanCount > 0 ? AppColors.info : AppColors.textSecondary,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                  DataCell(Row(children: [
                    _ActionIconBtn(
                      icon: Icons.edit_rounded,
                      color: AppColors.info,
                      onPressed: () => showDialog(
                        context: context,
                        builder: (_) => _CustomerFormDialog(existing: c),
                      ),
                    ),
                    const SizedBox(width:20,),
                    _ActionIconBtn(
                      icon: Icons.delete_outline_rounded,
                      color: AppColors.danger,
                      onPressed: () => _confirmDelete(context, c),
                    ),
                  ])),
                ]);
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  void _open(BuildContext context, Customer c) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => CustomerDetailScreen(customer: c)));
  }

  void _confirmDelete(BuildContext context, Customer c) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('هل أنت متأكد من حذف العميل "${c.name}"؟ سيتم حذف كل قروضه المرتبطة.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () {
              provider.deleteCustomer(c.id!);
              Navigator.pop(context);
            },
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }
}

class _ActionIconBtn extends StatefulWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;
  const _ActionIconBtn({required this.icon, required this.color, required this.onPressed});

  @override
  State<_ActionIconBtn> createState() => _ActionIconBtnState();
}

class _ActionIconBtnState extends State<_ActionIconBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: _hovered ? widget.color.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: IconButton(
          icon: Icon(widget.icon, size: 30, color: widget.color),
          onPressed: widget.onPressed,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// List (narrow)
// ─────────────────────────────────────────
class _CustomersList extends StatelessWidget {
  final List<Customer> customers;
  const _CustomersList({required this.customers});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: customers.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) => _CustomerCard(customer: customers[i]),
    );
  }
}

class _CustomerCard extends StatefulWidget {
  final Customer customer;
  const _CustomerCard({required this.customer});

  @override
  State<_CustomerCard> createState() => _CustomerCardState();
}

class _CustomerCardState extends State<_CustomerCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final initials = widget.customer.name.isNotEmpty ? widget.customer.name[0] : '?';
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
            color: _hovered ? AppColors.primary.withOpacity(0.4) : AppColors.glassBorder,
          ),
          boxShadow: _hovered
              ? [BoxShadow(color: AppColors.primary.withOpacity(0.15), blurRadius: 12, offset: const Offset(0, 4))]
              : [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.primary.withOpacity(0.18),
            child: Text(
              initials,
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w800,
                fontSize: 15,
              ),
            ),
          ),
          title: Text(
            widget.customer.name,
            style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
          subtitle: Text(
            widget.customer.phone.isEmpty ? 'لا يوجد رقم هاتف' : widget.customer.phone,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          trailing: const Icon(Icons.chevron_left_rounded, color: AppColors.textSecondary),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => CustomerDetailScreen(customer: widget.customer)),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// Gradient Button
// ─────────────────────────────────────────
class _GradientButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _GradientButton({required this.icon, required this.label, required this.onTap});

  @override
  State<_GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<_GradientButton> {
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
// Empty state
// ─────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final bool hasQuery;
  final VoidCallback onAdd;
  const _EmptyState({required this.hasQuery, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GlassContainer(
            width: 80,
            height: 80,
            borderRadius: BorderRadius.circular(24),
            child: Icon(
              hasQuery ? Icons.search_off_rounded : Icons.people_outline_rounded,
              size: 40,
              color: AppColors.textSecondary.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            hasQuery ? 'لا يوجد عميل مطابق' : 'لا يوجد عملاء بعد',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            hasQuery ? 'جرب البحث بكلمة مختلفة' : 'أضف عميلك الأول للبدء',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13.5),
          ),
          if (!hasQuery) ...[
            const SizedBox(height: 24),
            GestureDetector(
              onTap: onAdd,
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
                    Icon(Icons.person_add_alt_1_rounded, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'إضافة عميل جديد',
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

// ─────────────────────────────────────────
// Customer Form Dialog
// ─────────────────────────────────────────
class _CustomerFormDialog extends StatefulWidget {
  final Customer? existing;
  const _CustomerFormDialog({this.existing});

  @override
  State<_CustomerFormDialog> createState() => _CustomerFormDialogState();
}

class _CustomerFormDialogState extends State<_CustomerFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _notesCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.existing?.name ?? '');
    _phoneCtrl = TextEditingController(text: widget.existing?.phone ?? '');
    _addressCtrl = TextEditingController(text: widget.existing?.address ?? '');
    _notesCtrl = TextEditingController(text: widget.existing?.notes ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isEdit ? Icons.edit_rounded : Icons.person_add_alt_1_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Text(
                      isEdit ? 'تعديل بيانات العميل' : 'إضافة عميل جديد',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'الاسم الكامل',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'الاسم مطلوب' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _phoneCtrl,
                  decoration: const InputDecoration(
                    labelText: 'رقم الهاتف',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _addressCtrl,
                  decoration: const InputDecoration(
                    labelText: 'العنوان',
                    prefixIcon: Icon(Icons.location_on_outlined),
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _notesCtrl,
                  decoration: const InputDecoration(
                    labelText: 'ملاحظات',
                    prefixIcon: Icon(Icons.notes_rounded),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 24),
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
                        child: Text(isEdit ? 'حفظ التعديلات' : 'إضافة العميل'),
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

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final provider = context.read<AppProvider>();
    if (widget.existing != null) {
      provider.updateCustomer(widget.existing!.copyWith(
        name: _nameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        address: _addressCtrl.text.trim(),
        notes: _notesCtrl.text.trim(),
      ));
    } else {
      provider.addCustomer(Customer(
        name: _nameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        address: _addressCtrl.text.trim(),
        notes: _notesCtrl.text.trim(),
        createdAt: Formatters.todayIso(),
      ));
    }
    Navigator.pop(context);
  }
}
