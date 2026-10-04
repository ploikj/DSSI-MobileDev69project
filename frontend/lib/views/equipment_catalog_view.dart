import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/equipment.dart';
import '../viewmodels/booking_viewmodel.dart';
import '../viewmodels/equipment_viewmodel.dart';
import '../viewmodels/locale_viewmodel.dart';
import 'booking_form_dialog_view.dart';

/// หน้าจอคลังอุปกรณ์ไอทีตามสถาปัตยกรรม MVVM
/// รองรับการค้นหา/กรองแบบเรียลไทม์, เรียงลำดับหลายรูปแบบ, และสลับภาษาไทย/อังกฤษ
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

  String _getCategoryLabel(String key, LocaleViewModel localeVM) {
    switch (key) {
      case 'laptop':
        return localeVM.t('cat_laptop');
      case 'projector':
        return localeVM.t('cat_projector');
      case 'tablet':
        return localeVM.t('cat_tablet');
      case 'audio_video':
        return localeVM.t('cat_audio_video');
      case 'accessories':
        return localeVM.t('cat_accessories');
      default:
        return localeVM.t('cat_all');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final eqVM = context.watch<EquipmentViewModel>();
    final bookingVM = context.watch<BookingViewModel>();
    final localeVM = context.watch<LocaleViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              localeVM.t('catalog_title'),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 19),
            ),
            Text(
              localeVM.t('catalog_subtitle'),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        actions: [
          // Language Switcher Action Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ActionChip(
              avatar: Text(localeVM.isThai ? '🇹🇭' : '🇬🇧', style: const TextStyle(fontSize: 14)),
              label: Text(
                localeVM.isThai ? 'TH' : 'EN',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
              backgroundColor: theme.colorScheme.primaryContainer.withValues(alpha: 0.6),
              side: BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.3)),
              padding: const EdgeInsets.symmetric(horizontal: 2),
              visualDensity: VisualDensity.compact,
              onPressed: () => localeVM.toggleLocale(),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: localeVM.isThai ? 'รีเฟรชข้อมูล' : 'Refresh Data',
            onPressed: () => eqVM.loadEquipments(),
          ),
          if (widget.onLogout != null)
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: localeVM.t('btn_logout'),
              onPressed: widget.onLogout,
            ),
        ],
      ),
      body: Column(
        children: [
          // 1. Real-time Search Box
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: localeVM.t('search_hint'),
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
              onChanged: (val) {
                setState(() {});
                eqVM.search(val);
              },
            ),
          ),

          // 2. Pending Pickup Reminder Banner
          if (bookingVM.pendingCount > 0)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 4, 16, 6),
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
                      localeVM.t('pending_pickup_banner', {'count': '${bookingVM.pendingCount}'}),
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
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(localeVM.t('check_pickup_btn'), style: const TextStyle(fontWeight: FontWeight.bold)),
                        const Icon(Icons.arrow_forward_ios, size: 12),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // 3. Category Filter Chips (Horizontal)
          SizedBox(
            height: 44,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: eqVM.categories.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final cat = eqVM.categories[index];
                final catKey = cat['key']!;
                final isSelected = eqVM.selectedCategory == catKey;
                final label = _getCategoryLabel(catKey, localeVM);

                return ChoiceChip(
                  label: Text(label),
                  selected: isSelected,
                  selectedColor: theme.colorScheme.primaryContainer,
                  labelStyle: TextStyle(
                    color: isSelected ? theme.colorScheme.primary : Colors.black87,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 12.5,
                  ),
                  onSelected: (selected) {
                    if (selected) {
                      eqVM.setCategory(catKey);
                    }
                  },
                );
              },
            ),
          ),

          // 4. Filter & Sorting Controls Row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
            child: Row(
              children: [
                // Available Only Filter Chip
                FilterChip(
                  avatar: Icon(
                    eqVM.onlyAvailable ? Icons.check_circle : Icons.circle_outlined,
                    size: 16,
                    color: eqVM.onlyAvailable ? Colors.green.shade800 : Colors.grey,
                  ),
                  label: Text(
                    localeVM.t('filter_available_only'),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: eqVM.onlyAvailable ? FontWeight.bold : FontWeight.normal,
                      color: eqVM.onlyAvailable ? Colors.green.shade900 : Colors.black87,
                    ),
                  ),
                  selected: eqVM.onlyAvailable,
                  selectedColor: Colors.green.shade100,
                  checkmarkColor: Colors.green.shade900,
                  onSelected: (_) => eqVM.toggleOnlyAvailable(),
                ),
                const Spacer(),
                // Items Count Tag
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    localeVM.t('found_items', {'count': '${eqVM.equipments.length}'}),
                    style: TextStyle(fontSize: 11.5, color: Colors.blueGrey.shade800, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 8),
                // Sorting Menu
                PopupMenuButton<String>(
                  tooltip: localeVM.t('sort_by'),
                  initialValue: eqVM.sortBy,
                  onSelected: (val) => eqVM.setSortBy(val),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.sort, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          _getSortLabel(eqVM.sortBy, localeVM),
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                        const Icon(Icons.arrow_drop_down, size: 18),
                      ],
                    ),
                  ),
                  itemBuilder: (ctx) => [
                    PopupMenuItem(
                      value: 'name_asc',
                      child: Row(
                        children: [
                          const Icon(Icons.sort_by_alpha, size: 18),
                          const SizedBox(width: 8),
                          Text(localeVM.t('sort_name_asc'), style: const TextStyle(fontSize: 13)),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'name_desc',
                      child: Row(
                        children: [
                          const Icon(Icons.sort_by_alpha, size: 18),
                          const SizedBox(width: 8),
                          Text(localeVM.t('sort_name_desc'), style: const TextStyle(fontSize: 13)),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'available_desc',
                      child: Row(
                        children: [
                          const Icon(Icons.inventory_2_outlined, size: 18),
                          const SizedBox(width: 8),
                          Text(localeVM.t('sort_qty_desc'), style: const TextStyle(fontSize: 13)),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'newest',
                      child: Row(
                        children: [
                          const Icon(Icons.new_releases_outlined, size: 18),
                          const SizedBox(width: 8),
                          Text(localeVM.t('sort_newest'), style: const TextStyle(fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 5. Equipment Content List
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => eqVM.loadEquipments(),
              child: _buildEquipmentContent(theme, eqVM, localeVM),
            ),
          ),
        ],
      ),
    );
  }

  String _getSortLabel(String sortBy, LocaleViewModel localeVM) {
    switch (sortBy) {
      case 'name_desc':
        return localeVM.t('sort_name_desc');
      case 'available_desc':
        return localeVM.t('sort_qty_desc');
      case 'newest':
        return localeVM.t('sort_newest');
      default:
        return localeVM.t('sort_name_asc');
    }
  }

  Widget _buildEquipmentContent(ThemeData theme, EquipmentViewModel eqVM, LocaleViewModel localeVM) {
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
              Text(
                localeVM.isThai ? 'โหลดข้อมูลอุปกรณ์ไม่สำเร็จ' : 'Failed to load equipment catalog',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 6),
              Text(
                eqVM.errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => eqVM.loadEquipments(),
                icon: const Icon(Icons.refresh),
                label: Text(localeVM.isThai ? 'ลองใหม่' : 'Retry'),
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
            Text(
              localeVM.t('empty_equipments'),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              localeVM.t('empty_equipments_sub'),
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      itemCount: eqVM.equipments.length,
      itemBuilder: (context, index) {
        final eq = eqVM.equipments[index];
        return _buildEquipmentCard(eq, theme, localeVM);
      },
    );
  }

  Widget _buildEquipmentCard(Equipment item, ThemeData theme, LocaleViewModel localeVM) {
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
                          '${localeVM.isThai ? 'รุ่น/รหัส:' : 'Model/SN:'} ${item.modelNumber}',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                      const SizedBox(height: 4),
                      Text(
                        _getCategoryLabel(item.category, localeVM),
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
                    '${localeVM.t('pickup_location_label')} ${item.pickupLocation}',
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
                      localeVM.t('available_count', {
                        'avail': '${item.availableQuantity}',
                        'total': '${item.totalQuantity}',
                      }),
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
                  label: Text(isAvailable ? localeVM.t('btn_book') : localeVM.t('out_of_stock')),
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
