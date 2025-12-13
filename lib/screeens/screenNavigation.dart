import 'package:flutter/material.dart';
import 'package:kaluu_Epreess_Cargo/screeens/homePage.dart';
import 'package:kaluu_Epreess_Cargo/screeens/useraccount.dart';
import 'package:google_nav_bar/google_nav_bar.dart';

class HomeScreeenNav extends StatefulWidget {
  const HomeScreeenNav({super.key});

  @override
  State<HomeScreeenNav> createState() => _HomepageState();
}

class BlueSkyColors {
  static const Color skyBlue = Color(0xFF4A90E2);
  static const Color lightSkyBlue = Color(0xFF87CEEB);
  static const Color deepSkyBlue = Color(0xFF2E73B8);
}

class _HomepageState extends State<HomeScreeenNav> {
  int _selectedIndex = 0;

  static const List<Widget> _pages = <Widget>[HomePage(), UserAccountPage()];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      extendBody: true,
      body: _pages[_selectedIndex],
      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        decoration: BoxDecoration(
          color:
              isDark
                  ? colorScheme.surfaceContainerHighest.withOpacity(0.95)
                  : colorScheme.surface.withOpacity(0.95),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withOpacity(isDark ? 0.3 : 0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 8),
          child: GNav(
            gap: 8,
            activeColor: colorScheme.onPrimary,
            iconSize: 24,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            duration: const Duration(milliseconds: 400),
            tabBackgroundColor: BlueSkyColors.skyBlue,
            color: colorScheme.onSurfaceVariant,
            tabs: const [
              GButton(icon: Icons.home, text: 'Home'),
              GButton(icon: Icons.person, text: 'Profile'),
            ],
            selectedIndex: _selectedIndex,
            onTabChange: _onItemTapped,
          ),
        ),
      ),
    );
  }
}
