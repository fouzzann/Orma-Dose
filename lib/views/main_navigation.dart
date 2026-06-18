import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:orma_dose/core/theme.dart';
import 'package:orma_dose/providers/app_state_provider.dart';
import 'package:orma_dose/views/home/home_view.dart';
import 'package:orma_dose/views/medicines/medicines_view.dart';
import 'package:orma_dose/views/history/history_view.dart';
import 'package:orma_dose/views/profile/profile_view.dart';
import 'package:orma_dose/views/reminder/reminder_overlay.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  late PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _onTabTapped(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (appState.isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Stack(
      children: [
        Scaffold(
          extendBody: true, // Allows content to flow behind glass navigation bar
          body: PageView(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            children: const [
              HomeView(),
              MedicinesView(),
              HistoryView(),
              ProfileView(),
            ],
          ),
          bottomNavigationBar: _buildGlassmorphicNavBar(isDark),
        ),
        if (appState.activeReminder != null)
          ReminderOverlay(reminderData: appState.activeReminder!),
      ],
    );
  }

  Widget _buildGlassmorphicNavBar(bool isDark) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    
    return Container(
      margin: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: bottomPadding > 0 ? bottomPadding : 16,
      ),
      height: 72,
      decoration: BoxDecoration(
        color: isDark 
            ? Colors.black.withOpacity(0.4) 
            : Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isDark 
              ? Colors.white.withOpacity(0.08) 
              : Colors.white.withOpacity(0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark 
                ? Colors.black.withOpacity(0.3) 
                : const Color(0xFF0D8AD4).withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavBarItem(0, Icons.home_rounded, 'Home'),
              _buildNavBarItem(1, Icons.medical_services_rounded, 'Medicines'),
              _buildNavBarItem(2, Icons.analytics_rounded, 'History'),
              _buildNavBarItem(3, Icons.person_rounded, 'Profile'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavBarItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    final activeColor = AppTheme.primaryTeal;
    final inactiveColor = Theme.of(context).brightness == Brightness.dark 
        ? Colors.grey[500] 
        : Colors.grey[600];

    return InkWell(
      onTap: () => _onTabTapped(index),
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected 
              ? activeColor.withOpacity(0.12) 
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? activeColor : inactiveColor,
              size: 24,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? activeColor : inactiveColor,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
