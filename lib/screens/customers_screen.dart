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
      appBar: AppBar(
        title: const Text('العملاء'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: ElevatedButton.icon(
              onPressed: () => _showCustomerDialog(context),
              icon: const Icon(Icons.person_add_alt_1_rounded, size: 20),
              label: const Text('عميل جديد'),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 360,
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'ابحث بالاسم أو رقم الهاتف...',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: filtered.isEmpty
                  ? const Center(child: Text('لا يوجد عملاء بعد. أضف عميلك الأول!'))
                  : LayoutBuilder(builder: (context, c) {
                      final wide = c.maxWidth > 900;
                      if (wide) {
                        return _CustomersTable(customers: filtered, provider: provider);
                      }
                      return ListView.separated(
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, i) => _CustomerCard(customer: filtered[i]),
                      );
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

class _CustomersTable extends StatelessWidget {
  final List<Customer> customers;
  final AppProvider provider;
  const _CustomersTable({required this.customers, required this.provider});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: SingleChildScrollView(
        child: DataTable(
          columns: const [
            DataColumn(label: Text('الاسم')),
            DataColumn(label: Text('الهاتف')),
            DataColumn(label: Text('العنوان')),
            DataColumn(label: Text('عدد القروض')),
            DataColumn(label: Text('')),
          ],
          rows: customers.map((c) {
            final loanCount = provider.loansForCustomer(c.id!).length;
            return DataRow(cells: [
              DataCell(Text(c.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                  onTap: () => _open(context, c)),
              DataCell(Text(c.phone.isEmpty ? '-' : c.phone)),
              DataCell(Text(c.address.isEmpty ? '-' : c.address)),
              DataCell(Text('$loanCount')),
              DataCell(Row(children: [
                IconButton(
                  icon: const Icon(Icons.edit_rounded, size: 20, color: AppColors.textSecondary),
                  onPressed: () => showDialog(
                      context: context, builder: (_) => _CustomerFormDialog(existing: c)),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, size: 20, color: AppColors.danger),
                  onPressed: () => _confirmDelete(context, c),
                ),
              ])),
            ]);
          }).toList(),
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
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
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

class _CustomerCard extends StatelessWidget {
  final Customer customer;
  const _CustomerCard({required this.customer});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withOpacity(0.12),
          child: Text(customer.name.isNotEmpty ? customer.name[0] : '?',
              style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800)),
        ),
        title: Text(customer.name, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(customer.phone.isEmpty ? 'لا يوجد رقم هاتف' : customer.phone),
        trailing: const Icon(Icons.chevron_left_rounded),
        onTap: () => Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => CustomerDetailScreen(customer: customer))),
      ),
    );
  }
}

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
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                Text(isEdit ? 'تعديل بيانات العميل' : 'إضافة عميل جديد',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(labelText: 'الاسم الكامل'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'الاسم مطلوب' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _phoneCtrl,
                  decoration: const InputDecoration(labelText: 'رقم الهاتف'),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _addressCtrl,
                  decoration: const InputDecoration(labelText: 'العنوان'),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _notesCtrl,
                  decoration: const InputDecoration(labelText: 'ملاحظات'),
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
