import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/loan.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import 'loan_detail_screen.dart';

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
      appBar: AppBar(title: const Text('الأقساط والقروض')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 14,
              runSpacing: 14,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: 320,
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'ابحث باسم العميل...',
                      prefixIcon: Icon(Icons.search_rounded),
                    ),
                    onChanged: (v) => setState(() => _query = v),
                  ),
                ),
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
                  ? const Center(child: Text('لا توجد قروض مطابقة'))
                  : Card(
                      child: SingleChildScrollView(
                        child: DataTable(
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
                              onSelectChanged: (_) {
                                if (c == null) return;
                                Navigator.of(context).push(MaterialPageRoute(
                                  builder: (_) => LoanDetailScreen(loan: l, customerName: c.name),
                                ));
                              },
                              cells: [
                                DataCell(Text(c?.name ?? '—', style: const TextStyle(fontWeight: FontWeight.w700))),
                                DataCell(Text(Formatters.currency(l.principalAmount))),
                                DataCell(Text(Formatters.currency(l.profitAmount))),
                                DataCell(Text(Formatters.currency(l.totalAmount))),
                                DataCell(Text('${l.months}')),
                                DataCell(Text(Formatters.date(l.startDate))),
                                DataCell(_StatusBadge(status: l.status)),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final LoanStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final active = status == LoanStatus.active;
    final color = active ? AppColors.warning : AppColors.success;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
      child: Text(status.label, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12.5)),
    );
  }
}
