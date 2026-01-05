import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:self_develpoment_app/daily%20_challange/daily_challenge_page.dart';
import 'package:self_develpoment_app/journal/pages/journal_list_page.dart';
import 'package:self_develpoment_app/presentation/screens/profile/profile.dart';
import 'package:self_develpoment_app/presentation/screens/user/user_homepage.dart';

class Bottumbar extends StatefulWidget {
  const Bottumbar({super.key});

  @override
  State<Bottumbar> createState() => _BottumbarState();
}

class _BottumbarState extends State<Bottumbar>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    UserHomePage(key: PageStorageKey("Home")),
    JournalListPage(key: PageStorageKey('Diary')),
    DailyChallengePage(key: PageStorageKey('challenge')),
    ProfilePage(key: PageStorageKey("Profile")),
  ];

  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 280),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.22,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
  }

  void _onTabTapped(int index) {
    if (index == _currentIndex) return;
    _controller.forward(from: 0);
    setState(() => _currentIndex = index);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        transitionBuilder: (child, animation) {
          final offsetAnimation = Tween<Offset>(
            begin: const Offset(0.1, 0),
            end: Offset.zero,
          ).animate(animation);

          return SlideTransition(
            position: offsetAnimation,
            child: FadeTransition(opacity: animation, child: child),
          );
        },
        child: _screens[_currentIndex],
      ),

      // GLASSMORPHIC NAV BAR
      bottomNavigationBar: SafeArea(
        bottom: true,
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(26),
            topRight: Radius.circular(26),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Container(
              height: 75,
              decoration: BoxDecoration(
                color: theme.colorScheme.surface.withOpacity(0.65),
                border: Border(
                  top: BorderSide(
                    color: theme.colorScheme.primary.withOpacity(0.2),
                    width: 1,
                  ),
                ),
              ),
              child: BottomNavigationBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                type: BottomNavigationBarType.fixed,
                currentIndex: _currentIndex,
                onTap: _onTabTapped,

                selectedItemColor: theme.colorScheme.primary,
                unselectedItemColor: theme.colorScheme.onSurfaceVariant,

                selectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
                unselectedLabelStyle: const TextStyle(fontSize: 12),

                items: List.generate(4, (index) {
                  final icons = [
                    Icons.home_outlined,
                    Icons.menu_book_outlined,
                    Icons.check_circle_outline,
                    Icons.person_outline,
                  ];

                  final activeIcons = [
                    Icons.home,
                    Icons.menu_book_rounded,
                    Icons.task_alt_rounded,
                    Icons.person,
                  ];

                  final labels = ['Home', 'Diary', 'challange', 'Profile'];

                  final isSelected = _currentIndex == index;

                  return BottomNavigationBarItem(
                    icon: AnimatedBuilder(
                      animation: _controller,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: isSelected ? _scaleAnimation.value : 1.0,
                          child: Icon(
                            isSelected ? activeIcons[index] : icons[index],
                            color: isSelected
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                        );
                      },
                    ),
                    label: labels[index],
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
