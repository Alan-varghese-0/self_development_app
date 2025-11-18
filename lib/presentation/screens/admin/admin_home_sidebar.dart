import 'package:flutter/material.dart';

class AdminSidebar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  /// When true, labels show in drawer mode
  final bool isDrawerMode;

  const AdminSidebar({
    super.key,
    required this.selectedIndex,
    required this.onSelect,
    this.isDrawerMode = false,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      _NavItem("Home", Icons.dashboard),
      _NavItem("Uploads", Icons.upload),
      _NavItem("PDFs", Icons.picture_as_pdf),
      _NavItem("Users", Icons.person),
      _NavItem("Settings", Icons.settings),
    ];

    if (isDrawerMode) {
      // MOBILE DRAWER MENU
      return ListView(
        children: [
          const DrawerHeader(
            child: Text(
              "Admin Menu",
              style: TextStyle(color: Colors.white, fontSize: 22),
            ),
          ),
          ...List.generate(items.length, (i) {
            final selected = i == selectedIndex;
            return ListTile(
              leading: Icon(
                items[i].icon,
                color: selected ? Colors.white : Colors.white70,
              ),
              title: Text(
                items[i].label,
                style: TextStyle(
                  color: selected ? Colors.white : Colors.white70,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              onTap: () => onSelect(i),
            );
          }),
        ],
      );
    }

    // WEB DESKTOP SIDEBAR (NavigationRail)
    return Container(
      width: 90,
      color: Colors.white.withOpacity(.05),
      child: NavigationRail(
        backgroundColor: Colors.transparent,
        selectedIndex: selectedIndex,
        onDestinationSelected: onSelect,
        labelType: NavigationRailLabelType.all,
        destinations: items.map((item) {
          return NavigationRailDestination(
            icon: Icon(item.icon, color: Colors.white54),
            selectedIcon: Icon(item.icon, color: Colors.white),
            label: Text(
              item.label,
              style: const TextStyle(color: Colors.white),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _NavItem {
  final String label;
  final IconData icon;
  const _NavItem(this.label, this.icon);
}
