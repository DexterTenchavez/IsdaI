import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'screens/camera_screen.dart';
import 'screens/live_scan_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/splash_screen.dart';
import 'widgets/app_navbar.dart';

void main() {
  runApp(const IsdaAIApp());
}

class IsdaAIApp extends StatelessWidget {
  const IsdaAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IsdaAI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const SplashScreen(home: MainNavigationWrapper()),
    );
  }
}

class MainNavigationWrapper extends StatefulWidget {
  const MainNavigationWrapper({super.key});

  @override
  State<MainNavigationWrapper> createState() => _MainNavigationWrapperState();
}

class _MainNavigationWrapperState extends State<MainNavigationWrapper> {
  int _currentIndex = 0;

  void _onTap(int index) {
    if (index == _currentIndex) return;
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    // Hide navbar on Camera (1) and Live (2)
    final showNavBar = _currentIndex != 1 && _currentIndex != 2;

    final screens = [
      const HomeScreen(),
      CameraScreen(onClose: () => _onTap(0)),
      LiveScanScreen(onClose: () => _onTap(0)),
      const SettingsScreen(),
    ];

    return Scaffold(
      extendBody: true,
      body: screens[_currentIndex],
      bottomNavigationBar: showNavBar
          ? AppNavBar(currentIndex: _currentIndex, onTap: _onTap)
          : null,
    );
  }
}
