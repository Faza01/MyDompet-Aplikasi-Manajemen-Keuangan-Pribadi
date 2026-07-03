import 'dart:ui';
import 'package:flutter/material.dart';
import 'transactions/home_screen.dart';
import 'budgeting/budgeting_screen.dart';
import 'reports/reports_screen.dart';
import 'backup/settings_screen.dart';
import 'quick_input/quick_input_dialog.dart';

class MainNavigationHub extends StatefulWidget {
  const MainNavigationHub({super.key});

  @override
  State<MainNavigationHub> createState() => _MainNavigationHubState();
}

class _MainNavigationHubState extends State<MainNavigationHub> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    BudgetingScreen(),
    SizedBox(), // Spacing dummy
    ReportsScreen(),
    SettingsScreen(),
  ];

  void _openQuickInput({bool startListeningImmediately = false}) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => QuickInputDialog(
        startListeningImmediately: startListeningImmediately,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: ClipRect(
        child: SizedBox(
          height: 120.0,
          child: Stack(
            children: [
              // 1. Gradient Blur Background Layer
              Positioned.fill(
                child: ShaderMask(
                  shaderCallback: (rect) {
                    return const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black12,
                        Colors.black38,
                        Colors.black87,
                        Colors.black,
                      ],
                      stops: [0.0, 0.3, 0.6, 0.85, 1.0],
                    ).createShader(rect);
                  },
                  blendMode: BlendMode.dstIn,
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                    child: Container(
                      color: Colors.black.withOpacity(0.05), // Low opacity paint to trigger BackdropFilter
                    ),
                  ),
                ),
              ),
              // 2. Floating Navbar Capsule
              Align(
                alignment: Alignment.bottomCenter,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 280.0,
                          height: 64.0,
                          decoration: BoxDecoration(
                            color: const Color(0xFF2C2C2C), // Solid Charcoal Gray navbar
                            borderRadius: BorderRadius.circular(16.0),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.15),
                                blurRadius: 16.0,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildNavItem(0, Icons.home_outlined),
                              _buildNavItem(1, Icons.pie_chart_outline),
                              _buildCenterPlusButton(),
                              _buildNavItem(3, Icons.analytics_outlined),
                              _buildNavItem(4, Icons.settings_outlined),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 46.0,
        height: 46.0,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Icon(
          icon,
          color: isSelected ? const Color(0xFF003434) : Colors.white70,
          size: 22.0,
        ),
      ),
    );
  }

  Widget _buildCenterPlusButton() {
    return GestureDetector(
      onTap: _openQuickInput,
      onLongPress: () => _openQuickInput(startListeningImmediately: true),
      child: Container(
        width: 46.0,
        height: 46.0,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: const Icon(
          Icons.add,
          color: Color(0xFF003434), // Core Ledger Deep Teal
          size: 28.0,
        ),
      ),
    );
  }
}
