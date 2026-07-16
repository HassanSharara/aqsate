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

    return Scaffold(
      appBar: AppBar(title: Text(customer.name)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showDialog(
          context: context,
          builder: (_) => LoanFormDialog(customer: customer),
        ),
        icon: const Icon(Icons.add_rounded),
        label: const Text('قرض جديد'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Wrap(
                  spacing: 32,
                  runSpacing: 16,
                  children: [
                    _InfoBlock(label: 'الهاتف', value: customer.phone.isEmpty ? '-' : customer.phone),
                    _InfoBlock(label: 'العنوان', value: customer.address.isEmpty ? '-' : customer.address),
                    _InfoBlock(label: 'عدد القروض', value: '${loans.length}'),
                    _InfoBlock(label: 'إجمالي رأس المال المُقرض', value: Formatters.currency(totalPrincipal)),
                    _InfoBlock(label: 'إجمالي الأرباح', value: Formatters.currency(totalProfit)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text('سجل القروض', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 14),
            if (loans.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: Text('لا يوجد قروض لهذا العميل بعد')),
              )
            else
              ...loans.map((l) => _LoanTile(loan: l, customerName: customer.name)),
          ],
        ),
      ),
    );
  }
}

class _InfoBlock extends StatelessWidget {
  final String label;
  final String value;
  const _InfoBlock({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
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

class _LoanTile extends StatelessWidget {
  final Loan loan;
  final String customerName;
  const _LoanTile({required this.loan, required this.customerName});

  @override
  Widget build(BuildContext context) {
    final bool active = loan.status == LoanStatus.active;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        leading: CircleAvatar(
          backgroundColor: (active ? AppColors.warning : AppColors.success).withOpacity(0.14),
          child: Icon(active ? Icons.hourglass_bottom_rounded : Icons.check_rounded,
              color: active ? AppColors.warning : AppColors.success),
        ),
        title: Text(
          '${Formatters.currency(loan.principalAmount)}  +  ربح ${Formatters.currency(loan.profitAmount)}',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
            'بداية: ${Formatters.date(loan.startDate)}  •  ${loan.months} شهر  •  ${loan.status.label}'),
        trailing: const Icon(Icons.chevron_left_rounded),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => LoanDetailScreen(loan: loan, customerName: customerName)),
        ),
      ),
    );
  }
}
