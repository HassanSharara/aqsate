import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'dashboard_screen.dart';
import 'customers_screen.dart';
import 'loans_screen.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;

  final List<_NavItem> _items = const [
    _NavItem('لوحة التحكم', Icons.dashboard_rounded),
    _NavItem('العملاء', Icons.people_alt_rounded),
    _NavItem('الأقساط والقروض', Icons.receipt_long_rounded),
  ];

  final List<Widget> _screens = const [
    DashboardScreen(),
    CustomersScreen(),
    LoansScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isWide = constraints.maxWidth >= 900;
        final bool isMedium = constraints.maxWidth >= 640 && constraints.maxWidth < 900;

        if (isWide) {
          return Scaffold(
            body: Row(
              children: [
                _SideNav(
                  items: _items,
                  selectedIndex: _selectedIndex,
                  extended: true,
                  onSelect: (i) => setState(() => _selectedIndex = i),
                ),
                Expanded(
                  child: _screens[_selectedIndex],
                ),
              ],
            ),
          );
        } else if (isMedium) {
          return Scaffold(
            body: Row(
              children: [
                _SideNav(
                  items: _items,
                  selectedIndex: _selectedIndex,
                  extended: false,
                  onSelect: (i) => setState(() => _selectedIndex = i),
                ),
                Expanded(
                  child: _screens[_selectedIndex],
                ),
              ],
            ),
          );
        }

        // موبايل: BottomNavigationBar
        return Scaffold(
          body: _screens[_selectedIndex],
          bottomNavigationBar: NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (i) => setState(() => _selectedIndex = i),
            destinations: _items
                .map((e) => NavigationDestination(icon: Icon(e.icon), label: e.label))
                .toList(),
          ),
        );
      },
    );
  }
}

class _NavItem {
  final String label;
  final IconData icon;
  const _NavItem(this.label, this.icon);
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
    return Container(
      width: extended ? 260 : 84,
      color: AppColors.sidebar,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(vertical: 28, horizontal: extended ? 24 : 8),
              child: Row(
                mainAxisAlignment: extended ? MainAxisAlignment.start : MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.savings_rounded, color: Colors.white, size: 22),
                  ),
                  if (extended) ...[
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'اقساطي',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
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
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                extended ? 'إصدار 1.0' : '',
                style: const TextStyle(color: Colors.white38, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SideNavTile extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: extended ? 14 : 12, vertical: 4),
      child: Material(
        color: selected ? Colors.white.withOpacity(0.12) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
            child: Row(
              mainAxisAlignment: extended ? MainAxisAlignment.start : MainAxisAlignment.center,
              children: [
                Icon(item.icon, color: selected ? AppColors.accent : Colors.white70, size: 22),
                if (extended) ...[
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      item.label,
                      style: TextStyle(
                        color: selected ? Colors.white : Colors.white70,
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
