import 'package:flutter/material.dart';

import '../dashboard/dashboard_screen.dart';
import '../directory/directory_screen.dart';
import '../settings/settings_screen.dart';
import '../shipments/shipments_screen.dart';
import '../work_orders/work_orders_screen.dart';

/// Bottom-nav container for the 3Rivers staff app.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const _tabs = <_Tab>[
    _Tab('Home', Icons.dashboard_outlined, Icons.dashboard, DashboardScreen()),
    _Tab('Work Orders', Icons.assignment_outlined, Icons.assignment,
        WorkOrdersScreen()),
    _Tab('Shipments', Icons.local_shipping_outlined, Icons.local_shipping,
        ShipmentsScreen()),
    _Tab('Directory', Icons.groups_outlined, Icons.groups, DirectoryScreen()),
    _Tab('Settings', Icons.settings_outlined, Icons.settings, SettingsScreen()),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
