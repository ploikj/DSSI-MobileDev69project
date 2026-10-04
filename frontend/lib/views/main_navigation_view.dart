import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/booking_viewmodel.dart';
import '../viewmodels/locale_viewmodel.dart';
import 'equipment_catalog_view.dart';
import 'my_bookings_view.dart';
import 'settings_auth_view.dart';

/// หน้าจอหลักพร้อมเมนูนำทางด้านล่าง (Bottom Navigation)
/// เชื่อมต่อกับ ViewModel ผ่าน Provider โดยตรง
class MainNavigationView extends StatefulWidget {
  const MainNavigationView({super.key});

  @override
  State<MainNavigationView> createState() => _MainNavigationViewState();
}

class _MainNavigationViewState extends State<MainNavigationView> {
  int _currentIndex = 0;

  void _navigateToTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  Future<void> _confirmLogout() async {
    final localeVM = context.read<LocaleViewModel>();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.logout, color: Colors.red),
            const SizedBox(width: 8),
            Text(localeVM.t('confirm_logout_title'), style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(localeVM.t('confirm_logout_msg')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(localeVM.t('btn_cancel')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(localeVM.t('btn_logout')),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await context.read<AuthViewModel>().logout();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localeVM.isThai
                ? 'ออกจากระบบและล้าง Secure Storage เรียบร้อยแล้ว'
                : 'Logged out and cleared Secure Storage successfully'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bookingVM = context.watch<BookingViewModel>();
    final localeVM = context.watch<LocaleViewModel>();
    final pendingCount = bookingVM.pendingCount;

    final List<Widget> screens = [
      EquipmentCatalogView(
        onNavigateToBookings: () => _navigateToTab(1),
        onLogout: _confirmLogout,
      ),
      MyBookingsView(
        onLogout: _confirmLogout,
      ),
      SettingsAuthView(
        onLogout: _confirmLogout,
      ),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _navigateToTab,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.devices_outlined),
            selectedIcon: const Icon(Icons.devices),
            label: localeVM.t('nav_equipment'),
          ),
          NavigationDestination(
            icon: Badge.count(
              count: pendingCount,
              isLabelVisible: pendingCount > 0,
              backgroundColor: Colors.amber.shade900,
              child: const Icon(Icons.event_note_outlined),
            ),
            selectedIcon: Badge.count(
              count: pendingCount,
              isLabelVisible: pendingCount > 0,
              backgroundColor: Colors.amber.shade900,
              child: const Icon(Icons.event_note),
            ),
            label: localeVM.t('nav_schedule'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.security_outlined),
            selectedIcon: const Icon(Icons.security),
            label: localeVM.t('nav_oidc'),
          ),
        ],
      ),
    );
  }
}
