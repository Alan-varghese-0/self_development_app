import 'package:flutter/material.dart';
import 'package:self_develpoment_app/presentation/screens/admin/admin_home_sidebar.dart';

import 'admin_home_page.dart';
import 'admin_uploads_page.dart';
import 'admin_pdfs_page.dart';
import 'admin_users_page.dart';
import 'admin_settings_page.dart';

class AdminHome extends StatefulWidget {
  const AdminHome({super.key});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  int _index = 0;

  final pages = const [
    AdminHomePage(),
    AdminUploadsPage(),
    AdminPDFsPage(),
    AdminUsersPage(),
    AdminSettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isDesktop = constraints.maxWidth >= 900;

        return Scaffold(
          backgroundColor: Colors.black,
          // MOBILE → show drawer icon automatically
          appBar: isDesktop
              ? null
              : AppBar(
                  title: const Text("Admin Dashboard"),
                  backgroundColor: Colors.black,
                ),

          // MOBILE → Drawer Sidebar
          drawer: isDesktop
              ? null
              : Drawer(
                  child: Container(
                    color: Colors.black,
                    child: AdminSidebar(
                      selectedIndex: _index,
                      onSelect: (i) {
                        setState(() => _index = i);
                        Navigator.pop(context); // close drawer
                      },
                      isDrawerMode: true,
                    ),
                  ),
                ),

          body: Row(
            children: [
              // DESKTOP MODE = Permanent sidebar
              if (isDesktop)
                AdminSidebar(
                  selectedIndex: _index,
                  onSelect: (i) => setState(() => _index = i),
                ),

              // PAGE CONTENT
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: pages[_index],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
