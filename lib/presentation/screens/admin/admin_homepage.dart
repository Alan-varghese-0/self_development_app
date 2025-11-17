import 'dart:ui';
import 'package:flutter/material.dart';

class AdminHomepage extends StatefulWidget {
  const AdminHomepage({super.key});

  @override
  State<AdminHomepage> createState() => _AdminHomepageState();
}

class _AdminHomepageState extends State<AdminHomepage> {
  int _selectedIndex = 0;

  final _tabs = const [
    _NavItem("Home", Icons.dashboard_rounded),
    _NavItem("Upload", Icons.upload_rounded),
    _NavItem("Books", Icons.menu_book_outlined),
    _NavItem("Users", Icons.group_outlined),
    _NavItem("Settings", Icons.settings_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (ctx, c) {
        final isWide = c.maxWidth >= 900;

        if (isWide) {
          return Scaffold(
            backgroundColor: const Color(0xFFF7F9FC),
            body: Row(
              children: [
                _SidebarRail(
                  items: _tabs,
                  selectedIndex: _selectedIndex,
                  onSelect: (i) => setState(() => _selectedIndex = i),
                ),
                const VerticalDivider(width: 1),
                Expanded(child: _buildPage(_selectedIndex)),
              ],
            ),
          );
        } else {
          return Scaffold(
            backgroundColor: const Color(0xFFF7F9FC),
            appBar: AppBar(
              elevation: 0,
              backgroundColor: Colors.white,
              foregroundColor: Colors.black87,
              title: const Text("Admin"),
            ),
            drawer: _SidebarDrawer(
              items: _tabs,
              selectedIndex: _selectedIndex,
              onSelect: (i) {
                setState(() => _selectedIndex = i);
                Navigator.pop(context);
              },
            ),
            body: _buildPage(_selectedIndex),
          );
        }
      },
    );
  }

  Widget _buildPage(int index) {
    switch (index) {
      case 0:
        return _HomeMockPage();
      case 1:
        return _UploadPage();
      case 2:
        return _BooksPage();
      case 3:
        return _UsersPage();
      case 4:
      default:
        return _SettingsPage();
    }
  }
}

/* ------------------------------------------------------------------------
  ✅ MODERN GLASS SIDEBAR (NavigationRail)
------------------------------------------------------------------------ */

class _SidebarRail extends StatelessWidget {
  final List<_NavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  const _SidebarRail({
    required this.items,
    required this.selectedIndex,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 78,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.35),
        border: Border(right: BorderSide(color: Colors.white.withOpacity(.25))),
        boxShadow: [
          BoxShadow(
            color: Colors.black12.withOpacity(.08),
            blurRadius: 20,
            spreadRadius: 1,
          ),
        ],
      ),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: NavigationRail(
            backgroundColor: Colors.transparent,
            minWidth: 72,
            groupAlignment: -0.5,
            selectedIndex: selectedIndex,
            onDestinationSelected: onSelect,
            labelType: NavigationRailLabelType.all,
            leading: Padding(
              padding: const EdgeInsets.only(top: 20),
              child: CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFF4A6CF7).withOpacity(.2),
                child: const Icon(
                  Icons.admin_panel_settings,
                  color: Color(0xFF3657E0),
                ),
              ),
            ),
            destinations: items.map((e) {
              final selected = items.indexOf(e) == selectedIndex;
              return NavigationRailDestination(
                icon: Icon(e.icon, color: Colors.grey.shade600),
                selectedIcon: Icon(e.icon, color: const Color(0xFF3657E0)),
                label: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: TextStyle(
                    color: selected ? const Color(0xFF3657E0) : Colors.black54,
                    fontWeight: selected ? FontWeight.bold : FontWeight.w400,
                    fontSize: selected ? 13 : 12,
                  ),
                  child: Text(e.label),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

/* ------------------------------------------------------------------------
  ✅ MODERN GLASS DRAWER
------------------------------------------------------------------------ */

class _SidebarDrawer extends StatelessWidget {
  final List<_NavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  const _SidebarDrawer({
    required this.items,
    required this.selectedIndex,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Colors.blueGrey.shade50],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const ListTile(
                leading: CircleAvatar(
                  backgroundColor: Color(0xFF4A6CF7),
                  child: Icon(Icons.admin_panel_settings, color: Colors.white),
                ),
                title: Text(
                  "Admin Dashboard",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text("Manage your application"),
              ),
              const Divider(),

              ...List.generate(items.length, (i) {
                final item = items[i];
                final selected = i == selectedIndex;

                return ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: selected
                          ? const Color(0xFF4A6CF7).withOpacity(.15)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      item.icon,
                      color: selected
                          ? const Color(0xFF4A6CF7)
                          : Colors.grey[700],
                    ),
                  ),
                  title: Text(
                    item.label,
                    style: TextStyle(
                      color: selected
                          ? const Color(0xFF4A6CF7)
                          : Colors.black87,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                  onTap: () => onSelect(i),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

/* ------------------------------------------------------------------------
  ✅ HOME PAGE (Dashboard)
------------------------------------------------------------------------ */

class _HomeMockPage extends StatelessWidget {
  final _stats = const [
    ("Total Books", "1,248", Icons.menu_book_rounded, Color(0xFF4A6CF7)),
    ("Active Users", "8,312", Icons.group, Color(0xFF22B07D)),
    ("Audio Minutes", "57,430", Icons.headset_rounded, Color(0xFFFFA000)),
    ("Avg. Rating", "4.7", Icons.star_rounded, Color(0xFFEF5350)),
  ];

  final _recentUploads = const [
    ("Atomic Habits.pdf", "Self-Help", "2h ago"),
    ("30-Day Fitness.pdf", "Health", "5h ago"),
    ("Quick Recipes.pdf", "Cooking", "1d ago"),
    ("Mindfulness 101.pdf", "Wellness", "2d ago"),
  ];

  final _topCategories = const [
    ("Self-Help", 324),
    ("Health", 291),
    ("Cooking", 254),
    ("Wellness", 199),
    ("Finance", 182),
  ];

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF4A6CF7), Color(0xFF6D89FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
            ),
            child: const _HeaderTitle(),
          ),
        ),

        SliverPadding(
          padding: const EdgeInsets.all(20),
          sliver: SliverList.list(
            children: [
              LayoutBuilder(
                builder: (context, c) {
                  final cross = c.maxWidth > 1000
                      ? 4
                      : c.maxWidth > 700
                      ? 2
                      : 1;
                  return GridView.count(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    crossAxisCount: cross,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 3.3,
                    children: _stats
                        .map(
                          (s) => _StatCard(
                            label: s.$1,
                            value: s.$2,
                            icon: s.$3,
                            color: s.$4,
                          ),
                        )
                        .toList(),
                  );
                },
              ),
              const SizedBox(height: 20),

              LayoutBuilder(
                builder: (context, c) {
                  final isWide = c.maxWidth > 900;
                  return isWide
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _RecentUploads(recent: _recentUploads),
                            ),
                            const SizedBox(width: 20),
                            SizedBox(
                              width: 360,
                              child: _TopCategories(top: _topCategories),
                            ),
                          ],
                        )
                      : Column(
                          children: [
                            _RecentUploads(recent: _recentUploads),
                            const SizedBox(height: 20),
                            _TopCategories(top: _topCategories),
                          ],
                        );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HeaderTitle extends StatelessWidget {
  const _HeaderTitle();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Icon(Icons.dashboard_customize_rounded, color: Colors.white, size: 30),
        SizedBox(width: 12),
        Text(
          "Overview",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: .5,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black12.withOpacity(.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12.withOpacity(.04),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: color.withOpacity(.12),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),

                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
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

/* ------------------------------------------------------------------------
  ✅ Recent Uploads
------------------------------------------------------------------------ */

class _RecentUploads extends StatelessWidget {
  final List<(String, String, String)> recent;
  const _RecentUploads({required this.recent});

  @override
  Widget build(BuildContext context) {
    return _Card(
      title: "Recent Uploads",
      trailing: TextButton(onPressed: () {}, child: const Text("View All")),
      child: ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: recent.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (_, i) {
          final (name, tag, time) = recent[i];
          return ListTile(
            leading: const CircleAvatar(
              backgroundColor: Color(0xFFE9EEFF),
              child: Icon(Icons.picture_as_pdf, color: Color(0xFF4A6CF7)),
            ),
            title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text("$tag • $time"),
            trailing: IconButton(
              onPressed: () {},
              icon: const Icon(Icons.more_horiz),
            ),
          );
        },
      ),
    );
  }
}

/* ------------------------------------------------------------------------
  ✅ Top Categories
------------------------------------------------------------------------ */

class _TopCategories extends StatelessWidget {
  final List<(String, int)> top;
  const _TopCategories({required this.top});

  @override
  Widget build(BuildContext context) {
    return _Card(
      title: "Top Categories",
      child: Column(
        children: top
            .map(
              (t) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        t.$1,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    Container(
                      height: 10,
                      width: 160,
                      decoration: BoxDecoration(
                        color: const Color(0xFFECEFF7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: (t.$2 / (top.first.$2)).clamp(0.05, 1.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF4A6CF7),
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text("${t.$2}"),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

/* ------------------------------------------------------------------------
  ✅ Generic Reusable Card
------------------------------------------------------------------------ */

class _Card extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? trailing;

  const _Card({required this.title, required this.child, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black12.withOpacity(.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12.withOpacity(.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

/* ------------------------------------------------------------------------
  ✅ Other Tabs
------------------------------------------------------------------------ */

class _UploadPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _SimplePane(
      title: "Upload",
      subtitle: "Add PDFs or notes",
      icon: Icons.upload_rounded,
      action: ElevatedButton.icon(
        onPressed: () {},
        icon: const Icon(Icons.add),
        label: const Text("New Upload"),
      ),
    );
  }
}

class _BooksPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _SimplePane(
      title: "Books",
      subtitle: "Manage existing content",
      icon: Icons.menu_book_outlined,
      child: DataTable(
        columns: const [
          DataColumn(label: Text("Title")),
          DataColumn(label: Text("Category")),
          DataColumn(label: Text("Status")),
        ],
        rows: const [
          DataRow(
            cells: [
              DataCell(Text("Atomic Habits")),
              DataCell(Text("Self-Help")),
              DataCell(Text("Published")),
            ],
          ),
        ],
      ),
    );
  }
}

class _UsersPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _SimplePane(
      title: "Users",
      subtitle: "View & moderate users",
      icon: Icons.group_outlined,
      child: Column(
        children: const [
          ListTile(leading: Icon(Icons.person), title: Text("alice@email.com")),
          ListTile(leading: Icon(Icons.person), title: Text("bob@email.com")),
        ],
      ),
    );
  }
}

class _SettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _SimplePane(
      title: "Settings",
      subtitle: "App configuration",
      icon: Icons.settings_rounded,
      child: Column(
        children: [
          SwitchListTile(
            title: const Text("Maintenance Mode"),
            value: false,
            onChanged: (_) {},
          ),
        ],
      ),
    );
  }
}

/* ------------------------------------------------------------------------
  ✅ Simple Page Layout
------------------------------------------------------------------------ */

class _SimplePane extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget? action;
  final Widget? child;

  const _SimplePane({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.action,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF4A6CF7), Color(0xFF6D89FF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.white.withOpacity(.2),
                child: Icon(icon, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              if (action != null) action!,
            ],
          ),
        ),
        const SizedBox(height: 16),

        if (child != null)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.black12.withOpacity(.06)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12.withOpacity(.03),
                  blurRadius: 12,
                ),
              ],
            ),
            child: child!,
          ),
      ],
    );
  }
}

/* ------------------------------------------------------------------------
  ✅ Sidebar Menu Model
------------------------------------------------------------------------ */

class _NavItem {
  final String label;
  final IconData icon;
  const _NavItem(this.label, this.icon);
}
