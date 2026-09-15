import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_colors.dart';

class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: NavigationBar(
            height: 68,
            backgroundColor: Colors.white,
            indicatorColor: AppColors.petal.withValues(alpha: 0.35),
            selectedIndex: navigationShell.currentIndex,
            onDestinationSelected: navigationShell.goBranch,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.checkroom_outlined, color: AppColors.navInactive),
                selectedIcon: Icon(Icons.checkroom, color: AppColors.pinkChip),
                label: 'Closet',
              ),
              NavigationDestination(
                icon: Icon(Icons.auto_awesome_outlined, color: AppColors.navInactive),
                selectedIcon: Icon(Icons.auto_awesome, color: Color(0xFFE8B84A)),
                label: 'Desejos',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline, color: AppColors.navInactive),
                selectedIcon: Icon(Icons.person, color: Color(0xFF5B8DEF)),
                label: 'Perfil',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
