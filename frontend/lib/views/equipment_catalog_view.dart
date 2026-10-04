import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/equipment.dart';
import '../viewmodels/booking_viewmodel.dart';
import '../viewmodels/equipment_viewmodel.dart';
import 'booking_form_dialog_view.dart';

/// หน้าจอคลังอุปกรณ์ไอทีตามสถาปัตยกรรม MVVM
/// แสดงผลข้อมูลจาก EquipmentViewModel และสถิตินัดรับจาก BookingViewModel ผ่าน Provider
class EquipmentCatalogView extends StatefulWidget {
  final VoidCallback onNavigateToBookings;
  final VoidCallback? onLogout;

  const EquipmentCatalogView({
    super.key,
    required this.onNavigateToBookings,
    this.onLogout,
  });

  @override
  State<EquipmentCatalogView> createState() => _EquipmentCatalogViewState();
}

class _EquipmentCatalogViewState extends State<EquipmentCatalogView> {
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EquipmentViewModel>().loadEquipments();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _openBookingDialog(Equipment equipment) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => BookingFormDialogView(
        equipment: equipment,
        onBookingSuccess: () {
          context.read<EquipmentViewModel>().loadEquipments();
          widget.onNavigateToBookings();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final eqVM = context.watch<EquipmentViewModel>();
    final bookingVM = context.watch<BookingViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ระบบจองอุปกรณ์ไอที',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            Text(
              'เลือกอุปกรณ์และนัดหมายวัน-เวลารับ',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'รีเฟรชข้อมูล',
            onPressed: () => eqVM.loadEquipments(),
          ),
          if (widget.onLogout != null)
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'ออกจากระบบ',
              onPressed: widget.onLogout,
            ),
        ],
      ),
      body: Column(
        children: [
          // Search box
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'ค้นหาอุปกรณ์ไอที...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          eqVM.search('');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (val) => eqVM.search(val),
            ),
          ),

          // Pending Pickup Reminder Banner (ดึงสถิติตรงจาก BookingViewModel)
          if (bookingVM.pendingCount > 0)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.shade300),
              ),
              child: Row(
                children: [
                  Icon(Icons.alarm_on, color: Colors.amber.shade900, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'คุณมีรายการอุปกรณ์รอนัดรับ ${bookingVM.pendingCount} รายการ',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.amber.shade900,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  TextButton(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: widget.onNavigateToBookings,
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('ตรวจสอบวันนัดรับ', style: TextStyle(fontWeight: FontWeight.bold)),
                        Icon(Icons.arrow_forward_ios, size: 12),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // Categories Filter Horizontal List
          SizedBox(
            height: 48,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: eqVM.categories.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final cat = eqVM.categories[index];
                final isSelected = eqVM.selectedCategory == cat['key'];
                return ChoiceChip(
                  label: Text(cat['label']!),
                  selected: isSelected,
                  selectedColor: theme.colorScheme.primaryContainer,
                  labelStyle: TextStyle(
                    color: isSelected ? theme.colorScheme.primary : Colors.black87,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 13,
                  ),
                  onSelected: (selected) {
                    if (selected) {
                      eqVM.setCategory(cat['key']!);
                    }
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 8),

          // Content List
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => eqVM.loadEquipments(),
              child: _buildEquipmentContent(theme, eqVM),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEquipmentContent(ThemeData theme, EquipmentViewModel eqVM) {
    if (eqVM.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (eqVM.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 54, color: Colors.redAccent),
              const SizedBox(height: 12),
              Text('โหลดข้อมูลอุปกรณ์ไม่สำเร็จ', style: theme.textTheme.titleMedium),
              const SizedBox(height: 6),
              Text(eqVM.errorMessage!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => eqVM.loadEquipments(),
                icon: const Icon(Icons.refresh),
                label: const Text('ลองใหม่'),
              ),
            ],
          ),
        ),
      );
    }

    if (eqVM.equipments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.devices_other, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            const Text(
              'ไม่พบอุปกรณ์ตามเงื่อนไขที่ค้นหา',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              'ลองเปลี่ยนหมวดหมู่หรือคำค้นหา',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: eqVM.equipments.length,
      itemBuilder: (context, index) {
        final eq = eqVM.equipments[index];
        return _buildEquipmentCard(eq, theme);
      },
    );
  }

  Widget _buildEquipmentCard(Equipment item, ThemeData theme) {
    final bool isAvailable = item.isAvailable;

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: isAvailable
                        ? theme.colorScheme.primaryContainer.withValues(alpha: 0.5)
                        : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    _getCategoryIcon(item.category),
                    color: isAvailable ? theme.colorScheme.primary : Colors.grey,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      if (item.modelNumber != null && item.modelNumber!.isNotEmpty)
                        Text(
                          'รุ่น/รหัส: ${item.modelNumber}',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                      const SizedBox(height: 4),
                      Text(
                        item.categoryDisplay,
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (item.description.isNotEmpty) ...[
              Text(
                item.description,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
            ],
            Row(
              children: [
                Icon(Icons.location_on_outlined, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    item.pickupLocation,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isAvailable ? Colors.green : Colors.red,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'พร้อมให้ยืม ${item.availableQuantity}/${item.totalQuantity} เครื่อง',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isAvailable ? Colors.green.shade800 : Colors.red.shade800,
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isAvailable ? theme.colorScheme.primary : Colors.grey.shade300,
                    foregroundColor: isAvailable ? Colors.white : Colors.grey.shade600,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                  onPressed: isAvailable ? () => _openBookingDialog(item) : null,
                  icon: const Icon(Icons.event_available, size: 18),
                  label: Text(isAvailable ? 'จองอุปกรณ์' : 'ของหมด'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String cat) {
    switch (cat) {
      case 'laptop':
        return Icons.laptop_chromebook;
      case 'projector':
        return Icons.videocam_outlined;
      case 'tablet':
        return Icons.tablet_mac;
      case 'audio_video':
        return Icons.camera_alt_outlined;
      case 'accessories':
        return Icons.cable;
      default:
        return Icons.devices;
    }
  }
}
