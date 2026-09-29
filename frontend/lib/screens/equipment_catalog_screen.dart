import 'package:flutter/material.dart';
import '../models/equipment.dart';
import '../services/api_service.dart';
import 'booking_form_dialog.dart';

class EquipmentCatalogScreen extends StatefulWidget {
  final VoidCallback onNavigateToBookings;

  const EquipmentCatalogScreen({
    super.key,
    required this.onNavigateToBookings,
  });

  @override
  State<EquipmentCatalogScreen> createState() => _EquipmentCatalogScreenState();
}

class _EquipmentCatalogScreenState extends State<EquipmentCatalogScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchCtrl = TextEditingController();

  List<Equipment> _equipments = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _selectedCategory = 'all';

  final List<Map<String, String>> _categories = [
    {'key': 'all', 'label': 'ทั้งหมด'},
    {'key': 'laptop', 'label': 'โน้ตบุ๊ก & PC'},
    {'key': 'projector', 'label': 'โปรเจกเตอร์'},
    {'key': 'tablet', 'label': 'แท็บเล็ต/iPad'},
    {'key': 'audio_video', 'label': 'กล้อง & ระบบเสียง'},
    {'key': 'accessories', 'label': 'อุปกรณ์เสริม'},
  ];

  @override
  void initState() {
    super.initState();
    _loadEquipments();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadEquipments() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final list = await _apiService.fetchEquipments(
        category: _selectedCategory,
        search: _searchCtrl.text,
      );
      if (mounted) {
        setState(() {
          _equipments = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _openBookingDialog(Equipment equipment) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => BookingFormDialog(
        equipment: equipment,
        onBookingSuccess: () {
          _loadEquipments();
          widget.onNavigateToBookings();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
            onPressed: _loadEquipments,
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
                          _loadEquipments();
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
              onSubmitted: (_) => _loadEquipments(),
            ),
          ),

          // Categories Filter Horizontal List
          SizedBox(
            height: 48,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final cat = _categories[index];
                final isSelected = _selectedCategory == cat['key'];
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
                      setState(() => _selectedCategory = cat['key']!);
                      _loadEquipments();
                    }
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 8),

          // Main Equipment Content
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadEquipments,
              child: _buildEquipmentContent(theme),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEquipmentContent(ThemeData theme) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cloud_off_rounded, size: 64, color: Colors.orange),
              const SizedBox(height: 16),
              Text(
                'ไม่สามารถเชื่อมต่อเซิร์ฟเวอร์ได้',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'ตรวจสอบว่ารัน Django Server (python manage.py runserver) แล้วหรือยัง\n\n$_errorMessage',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadEquipments,
                icon: const Icon(Icons.refresh),
                label: const Text('ลองใหม่'),
              ),
            ],
          ),
        ),
      );
    }

    if (_equipments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.devices_other, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            const Text(
              'ไม่พบอุปกรณ์ที่ค้นหา',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              'ลองเลือกหมวดหมู่อื่น หรือพิมพ์คำค้นหาใหม่',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // ถ้าหน้าจอกว้าง (เช่น บนแท็บเล็ต / เว็บ / จอใหญ่) ให้ทำเป็น Grid 2-3 คอลัมน์
        final isWide = constraints.maxWidth > 650;

        if (isWide) {
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.15,
            ),
            itemCount: _equipments.length,
            itemBuilder: (context, index) => _buildEquipmentCard(_equipments[index], theme),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: _equipments.length,
          itemBuilder: (context, index) => _buildEquipmentCard(_equipments[index], theme),
        );
      },
    );
  }

  Widget _buildEquipmentCard(Equipment item, ThemeData theme) {
    final isAvailable = item.isAvailable;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image / Header Banner
          Stack(
            children: [
              Container(
                height: 150,
                width: double.infinity,
                color: Colors.grey.shade200,
                child: item.imageUrl.isNotEmpty
                    ? Image.network(
                        item.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => _fallbackImagePlaceholder(),
                      )
                    : _fallbackImagePlaceholder(),
              ),
              // Category Badge
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    item.categoryDisplay.isNotEmpty ? item.categoryDisplay : item.category,
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              // Stock Badge
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isAvailable ? Colors.green.shade700 : Colors.red.shade700,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isAvailable ? Icons.check_circle : Icons.cancel,
                        color: Colors.white,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isAvailable
                            ? 'ว่าง ${item.availableQuantity}/${item.totalQuantity} เครื่อง'
                            : 'ถูกยืมหมดแล้ว',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Content body
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (item.modelNumber != null && item.modelNumber!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    'รหัสครุภัณฑ์: ${item.modelNumber}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
                const SizedBox(height: 6),
                Text(
                  item.description,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade800),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.location_on_outlined, size: 16, color: Colors.blue.shade700),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        item.pickupLocation,
                        style: TextStyle(fontSize: 12, color: Colors.blue.shade900),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isAvailable ? theme.colorScheme.primary : Colors.grey.shade400,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: isAvailable ? () => _openBookingDialog(item) : null,
                    icon: const Icon(Icons.calendar_month, size: 18),
                    label: Text(isAvailable ? 'จองอุปกรณ์และนัดเวลารับ' : 'ไม่พร้อมให้บริการในขณะนี้'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _fallbackImagePlaceholder() {
    return Container(
      color: Colors.blueGrey.shade100,
      child: Center(
        child: Icon(Icons.devices, size: 54, color: Colors.blueGrey.shade400),
      ),
    );
  }
}
