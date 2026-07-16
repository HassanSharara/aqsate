import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/customer.dart';
import '../theme/app_theme.dart';
import 'loan_form_dialog.dart';

/// Dialog يظهر قائمة العملاء للاختيار منها ثم يفتح نموذج إنشاء قرض جديد
class SelectCustomerDialog extends StatefulWidget {
  const SelectCustomerDialog({super.key});

  @override
  State<SelectCustomerDialog> createState() => _SelectCustomerDialogState();
}

class _SelectCustomerDialogState extends State<SelectCustomerDialog> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final filtered = provider.customers
        .where((c) =>
            c.name.toLowerCase().contains(_query.toLowerCase()) ||
            c.phone.contains(_query))
        .toList();

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 600),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.person_search_rounded, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'اختر العميل',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'اختر العميل لإنشاء قرض/قسط جديد له',
                          style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
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
              const SizedBox(height: 20),

              // Search
              TextField(
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'ابحث بالاسم أو رقم الهاتف...',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
                onChanged: (v) => setState(() => _query = v),
              ),
              const SizedBox(height: 14),

              // List
              Flexible(
                child: filtered.isEmpty
                    ? _EmptyState(query: _query)
                    : ListView.separated(
                        shrinkWrap: true,
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => Divider(
                          height: 1,
                          color: AppColors.glassBorder,
                        ),
                        itemBuilder: (context, i) {
                          final c = filtered[i];
                          return _CustomerTile(
                            customer: c,
                            onTap: () => _openLoanForm(context, c),
                          );
                        },
                      ),
              ),

              const SizedBox(height: 16),
              // Footer hint
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${filtered.length} عميل',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openLoanForm(BuildContext context, Customer customer) {
    Navigator.pop(context); // أغلق dialog الاختيار
    showDialog(
      context: context,
      builder: (_) => LoanFormDialog(customer: customer),
    );
  }
}

class _CustomerTile extends StatefulWidget {
  final Customer customer;
  final VoidCallback onTap;

  const _CustomerTile({required this.customer, required this.onTap});

  @override
  State<_CustomerTile> createState() => _CustomerTileState();
}

class _CustomerTileState extends State<_CustomerTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final initials = widget.customer.name.isNotEmpty
        ? widget.customer.name.trim().split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join()
        : '?';

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        color: _hovered ? AppColors.glassMid : Colors.transparent,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          leading: CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.primary.withOpacity(0.18),
            child: Text(
              initials,
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
          ),
          title: Text(
            widget.customer.name,
            style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
          subtitle: widget.customer.phone.isNotEmpty
              ? Text(widget.customer.phone,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13))
              : null,
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'اختر',
              style: TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w700),
            ),
          ),
          onTap: widget.onTap,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String query;
  const _EmptyState({required this.query});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              query.isNotEmpty ? Icons.search_off_rounded : Icons.people_outline_rounded,
              size: 48,
              color: AppColors.textSecondary.withOpacity(0.4),
            ),
            const SizedBox(height: 12),
            Text(
              query.isNotEmpty ? 'لا يوجد عميل بهذا الاسم' : 'لا يوجد عملاء بعد',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
