import 'package:flutter/material.dart';
import '../widgets/app_bottom_nav.dart';
import 'diagnosis_screen.dart';
import 'history_screen.dart';
import 'home_screen.dart';
import 'my_car_screen.dart';
import 'profile_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  void _onTabSelected(int index) {
    setState(() => _selectedIndex = index);
  }

  void _openScan() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const DiagnosisScreen()),
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return HomeScreen(
          onScanTap: _openScan,
          onNavigateToTab: _onTabSelected,
        );
      case 1:
        return const HistoryScreen();
      case 3:
        return const MyCarScreen();
      case 4:
        return const ProfileScreen();
      default:
        return HomeScreen(
          onScanTap: _openScan,
          onNavigateToTab: _onTabSelected,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildBody(),
      bottomNavigationBar: AppBottomNav(
        currentIndex: _selectedIndex,
        onTap: _onTabSelected,
        onScanTap: _openScan,
      ),
    );
  }
}
