import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'screens/camera_screen.dart';
import 'screens/live_scan_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/splash_screen.dart';
import 'widgets/app_navbar.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Draw behind the system bars so the nav bar can read the real inset
  // (gesture pill vs 3-button bar) and position itself above it.
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

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
  DateTime? _lastBackPress;

  void _onTap(int index) {
    if (index == _currentIndex) return;
    setState(() => _currentIndex = index);
  }

  void _handleBack() {
    // Not on Home -> go back to Home first
    if (_currentIndex != 0) {
      setState(() => _currentIndex = 0);
      return;
    }

    // On Home -> require a double tap to exit
    final now = DateTime.now();
    final firstTap =
        _lastBackPress == null ||
        now.difference(_lastBackPress!) > const Duration(seconds: 2);

    if (firstTap) {
      _lastBackPress = now;
      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Press back again to exit'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          // keep it above the floating nav bar
          margin: EdgeInsets.fromLTRB(20, 0, 20, 110),
        ),
      );
      return;
    }

    SystemNavigator.pop(); // exit the app
  }

  @override
  Widget build(BuildContext context) {
    // Hide navbar on Camera (1) and Live (2)
    final showNavBar = _currentIndex != 1 && _currentIndex != 2;

    final screens = [
      HomeScreen(onNavigate: _onTap),
      CameraScreen(onClose: () => _onTap(0)),
      LiveScanScreen(onClose: () => _onTap(0)),
      const SettingsScreen(),
    ];

    return PopScope(
      canPop: false, // we decide what back does
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBack();
      },
      child: Scaffold(
        extendBody: true,
        body: screens[_currentIndex],
        bottomNavigationBar: showNavBar
            ? AppNavBar(currentIndex: _currentIndex, onTap: _onTap)
            : null,
      ),
    );
  }
}
