import 'dart:ui';
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

        // Full gradient background wrapping everything
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

// ─────────────────────────────────────────
// Sidebar
// ─────────────────────────────────────────
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
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xCC071525), Color(0xBB0C1E35)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            border: const Border(
              right: BorderSide(color: AppColors.glassBorder, width: 1),
            ),
          ),
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Logo
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

                // Divider
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: extended ? 16 : 10, vertical: 4),
                  child: Divider(color: Colors.white.withOpacity(0.08), thickness: 1),
                ),

                const SizedBox(height: 8),

                // Nav items
                for (int i = 0; i < items.length; i++)
                  _SideNavTile(
                    item: items[i],
                    selected: i == selectedIndex,
                    extended: extended,
                    onTap: () => onSelect(i),
                  ),

                const Spacer(),

                // Version
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

// ─────────────────────────────────────────
// Bottom Nav (mobile)
// ─────────────────────────────────────────
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
