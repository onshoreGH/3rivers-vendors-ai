import 'package:flutter/material.dart';

import '../broadcasts/broadcasts_screen.dart';
import '../catalogue/catalogue_screen.dart';
import '../dashboard/dashboard_screen.dart';
import '../invoices/invoices_screen.dart';
import '../settings/settings_screen.dart';

/// Bottom-nav container for the 3Rivers Vendors app.
///
/// Five tabs, each backed by a real endpoint. Payments deliberately has no tab
/// of its own: the only payments data available is the same figures already
/// summarised on Overview, and a tab that restates another tab is the kind of
/// thin filler that reads as an incomplete app in review.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const _tabs = <_Tab>[
    _Tab('Overview', Icons.insights_outlined, Icons.insights,
        DashboardScreen()),
    _Tab('Invoices', Icons.receipt_long_outlined, Icons.receipt_long,
        InvoicesScreen()),
    _Tab('Catalogue', Icons.inventory_2_outlined, Icons.inventory_2,
        CatalogueScreen()),
    _Tab('Notices', Icons.campaign_outlined, Icons.campaign,
        BroadcastsScreen()),
    _Tab('Settings', Icons.settings_outlined, Icons.settings, SettingsScreen()),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // IndexedStack, not a swapped child: each tab keeps its scroll position
      // and loaded data when you come back to it, instead of re-fetching.
      body: IndexedStack(
        index: _index,
        children: [for (final t in _tabs) t.screen],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          for (final t in _tabs)
            NavigationDestination(
              icon: Icon(t.icon),
              selectedIcon: Icon(t.activeIcon),
              label: t.label,
            ),
        ],
      ),
    );
  }
}

class _Tab {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final Widget screen;
  const _Tab(this.label, this.icon, this.activeIcon, this.screen);
}
