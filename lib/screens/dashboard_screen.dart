import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../models/loan.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    final totalPrincipal = provider.allLoans.fold<double>(0, (s, l) => s + l.principalAmount);
    final totalProfit = provider.allLoans.fold<double>(0, (s, l) => s + l.profitAmount);
    final activeCount = provider.activeLoanCount;
    final completedCount = provider.completedLoanCount;
    final customersCount = provider.customers.length;

    return Scaffold(
      appBar: AppBar(title: const Text('لوحة التحكم')),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LayoutBuilder(builder: (context, c) {
                    final wide = c.maxWidth > 900;
                    final cards = [
                      _StatCard(
                        title: 'إجمالي رؤوس الأموال المُقرضة',
                        value: Formatters.currency(totalPrincipal),
                        icon: Icons.account_balance_wallet_rounded,
                        color: AppColors.primary,
                      ),
                      _StatCard(
                        title: 'إجمالي الأرباح المتوقعة',
                        value: Formatters.currency(totalProfit),
                        icon: Icons.trending_up_rounded,
                        color: AppColors.accent,
                      ),
                      _StatCard(
                        title: 'قروض نشطة',
                        value: '$activeCount',
                        icon: Icons.hourglass_bottom_rounded,
                        color: AppColors.warning,
                      ),
                      _StatCard(
                        title: 'قروض مكتملة',
                        value: '$completedCount',
                        icon: Icons.check_circle_rounded,
                        color: AppColors.success,
                      ),
                      _StatCard(
                        title: 'عدد العملاء',
                        value: '$customersCount',
                        icon: Icons.groups_rounded,
                        color: AppColors.primaryDark,
                      ),
                    ];
                    return Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: cards
                          .map((c2) => SizedBox(
                                width: wide ? (c.maxWidth - 16 * 4) / 5 : (c.maxWidth - 16) / 2,
                                child: c2,
                              ))
                          .toList(),
                    );
                  }),
                  const SizedBox(height: 28),
                  Text('نظرة عامة على القروض', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: SizedBox(
                        height: 260,
                        child: provider.allLoans.isEmpty
                            ? const Center(child: Text('لا توجد بيانات قروض بعد'))
                            : _LoanBarChart(loans: provider.allLoans),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({required this.title, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 14),
            Text(value,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
            const SizedBox(height: 4),
            Text(title, style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

class _LoanBarChart extends StatelessWidget {
  final List<Loan> loans;
  const _LoanBarChart({required this.loans});

  @override
  Widget build(BuildContext context) {
    final recent = loans.take(8).toList().reversed.toList();
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= recent.length) return const SizedBox();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text('#${recent[idx].id}', style: const TextStyle(fontSize: 11)),
                );
              },
            ),
          ),
        ),
        barGroups: [
          for (int i = 0; i < recent.length; i++)
            BarChartGroupData(x: i, barRods: [
              BarChartRodData(
                toY: recent[i].principalAmount,
                color: AppColors.primary,
                width: 14,
                borderRadius: BorderRadius.circular(4),
              ),
              BarChartRodData(
                toY: recent[i].profitAmount,
                color: AppColors.accent,
                width: 14,
                borderRadius: BorderRadius.circular(4),
              ),
            ]),
        ],
      ),
    );
  }
}
