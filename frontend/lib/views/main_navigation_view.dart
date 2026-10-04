import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/booking_viewmodel.dart';
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
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.logout, color: Colors.red),
            SizedBox(width: 8),
            Text('ยืนยันออกจากระบบ', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text('คุณต้องการออกจากระบบและล้าง Token จาก Secure Storage ใช่หรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('ออกจากระบบ'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await context.read<AuthViewModel>().logout();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ออกจากระบบและล้าง Secure Storage เรียบร้อยแล้ว')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bookingVM = context.watch<BookingViewModel>();
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
          const NavigationDestination(
            icon: Icon(Icons.devices_outlined),
            selectedIcon: Icon(Icons.devices),
            label: 'อุปกรณ์ไอที',
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
            label: 'กำหนดการรับ',
          ),
          const NavigationDestination(
            icon: Icon(Icons.security_outlined),
            selectedIcon: Icon(Icons.security),
            label: 'ข้อมูล OIDC',
          ),
        ],
      ),
    );
  }
}
