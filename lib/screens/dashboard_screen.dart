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
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('لوحة التحكم'),
      ),
      body: provider.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(28, 8, 28, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome header
                  _WelcomeHeader(
                    activeCount: activeCount,
                    customersCount: customersCount,
                  ),
                  const SizedBox(height: 28),

                  // Stats grid
                  LayoutBuilder(builder: (context, c) {
                    final wide = c.maxWidth > 800;
                    final cards = [
                      _StatCard(
                        title: 'رأس المال المُقرض',
                        value: Formatters.currency(totalPrincipal),
                        icon: Icons.account_balance_wallet_rounded,
                        gradient: AppColors.primaryGradient,
                        trend: '+12%',
                        trendUp: true,
                      ),
                      _StatCard(
                        title: 'الأرباح المتوقعة',
                        value: Formatters.currency(totalProfit),
                        icon: Icons.trending_up_rounded,
                        gradient: AppColors.accentGradient,
                        trend: '+8%',
                        trendUp: true,
                      ),
                      _StatCard(
                        title: 'قروض نشطة',
                        value: '$activeCount',
                        icon: Icons.hourglass_bottom_rounded,
                        gradient: AppColors.infoGradient,
                      ),
                      _StatCard(
                        title: 'قروض مكتملة',
                        value: '$completedCount',
                        icon: Icons.check_circle_rounded,
                        gradient: AppColors.successGradient,
                      ),
                      _StatCard(
                        title: 'إجمالي العملاء',
                        value: '$customersCount',
                        icon: Icons.groups_rounded,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF9B59B6), Color(0xFF6C3483)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ];

                    final cardWidth = wide
                        ? (c.maxWidth - 16 * 4) / 5
                        : (c.maxWidth - 16) / 2;

                    return Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: cards
                          .map((card) => SizedBox(width: cardWidth, child: card))
                          .toList(),
                    );
                  }),

                  const SizedBox(height: 32),

                  // Chart section
                  Row(
                    children: [
                      const Text(
                        'نظرة عامة على القروض',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.bar_chart_rounded, color: AppColors.primary, size: 14),
                            SizedBox(width: 6),
                            Text(
                              'آخر 8 قروض',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  GlassContainer(
                    padding: const EdgeInsets.all(24),
                    borderRadius: BorderRadius.circular(20),
                    child: SizedBox(
                      height: 280,
                      child: provider.allLoans.isEmpty
                          ? _EmptyChart()
                          : _LoanBarChart(loans: provider.allLoans),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Legend
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _LegendDot(color: AppColors.primary, label: 'رأس المال'),
                      const SizedBox(width: 24),
                      _LegendDot(color: AppColors.accent, label: 'الأرباح'),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}

class _WelcomeHeader extends StatelessWidget {
  final int activeCount;
  final int customersCount;

  const _WelcomeHeader({required this.activeCount, required this.customersCount});

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.all(24),
      borderRadius: BorderRadius.circular(20),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, Color(0xFF0099CC)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.savings_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'مرحباً بك في اقساطي 👋',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'لديك $activeCount قرض نشط • $customersCount عميل مسجّل',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatefulWidget {
  final String title;
  final String value;
  final IconData icon;
  final LinearGradient gradient;
  final String? trend;
  final bool trendUp;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.gradient,
    this.trend,
    this.trendUp = true,
  });

  @override
  State<_StatCard> createState() => _StatCardState();
}

class _StatCardState extends State<_StatCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: _hovered
            ? (Matrix4.identity()..translate(0.0, -4.0))
            : Matrix4.identity(),
        decoration: BoxDecoration(
          color: AppColors.glassLight,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: _hovered ? AppColors.glassMid : AppColors.glassBorder,
            width: 1,
          ),
          boxShadow: _hovered
              ? [
                  BoxShadow(
                    color: widget.gradient.colors.first.withOpacity(0.25),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: widget.gradient,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: widget.gradient.colors.first.withOpacity(0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Icon(widget.icon, color: Colors.white, size: 22),
                  ),
                  if (widget.trend != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: (widget.trendUp ? AppColors.success : AppColors.danger)
                            .withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            widget.trendUp
                                ? Icons.arrow_upward_rounded
                                : Icons.arrow_downward_rounded,
                            size: 12,
                            color: widget.trendUp ? AppColors.success : AppColors.danger,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            widget.trend!,
                            style: TextStyle(
                              color: widget.trendUp ? AppColors.success : AppColors.danger,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                widget.value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.title,
                style: const TextStyle(
                  fontSize: 12.5,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bar_chart_rounded, size: 48, color: Colors.white.withOpacity(0.15)),
          const SizedBox(height: 12),
          const Text(
            'لا توجد بيانات قروض بعد',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _LoanBarChart extends StatefulWidget {
  final List<Loan> loans;
  const _LoanBarChart({required this.loans});

  @override
  State<_LoanBarChart> createState() => _LoanBarChartState();
}

class _LoanBarChartState extends State<_LoanBarChart> {
  int touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final recent = widget.loans.take(8).toList().reversed.toList();
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: recent.fold<double>(0, (m, l) => l.principalAmount > m ? l.principalAmount : m) * 1.3,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final l = recent[group.x.toInt()];
              return BarTooltipItem(
                rodIndex == 0
                    ? 'رأس المال\n${Formatters.currency(l.principalAmount)}'
                    : 'الأرباح\n${Formatters.currency(l.profitAmount)}',
                const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
              );
            },
          ),
          touchCallback: (event, response) {
            setState(() {
              touchedIndex = response?.spot?.touchedBarGroupIndex ?? -1;
            });
          },
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => FlLine(
            color: Colors.white.withOpacity(0.06),
            strokeWidth: 1,
          ),
        ),
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
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '#${recent[idx].id}',
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
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
                gradient: i == touchedIndex
                    ? const LinearGradient(
                        colors: [AppColors.primary, Color(0xFF00E5A8)],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      )
                    : LinearGradient(
                        colors: [
                          AppColors.primary.withOpacity(0.7),
                          AppColors.primary,
                        ],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                width: 16,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
              ),
              BarChartRodData(
                toY: recent[i].profitAmount,
                gradient: i == touchedIndex
                    ? const LinearGradient(
                        colors: [AppColors.accent, Color(0xFFFFD080)],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      )
                    : LinearGradient(
                        colors: [
                          AppColors.accent.withOpacity(0.7),
                          AppColors.accent,
                        ],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                width: 16,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
              ),
            ]),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
      ],
    );
  }
}
