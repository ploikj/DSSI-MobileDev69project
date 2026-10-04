import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/booking.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/booking_viewmodel.dart';
import '../viewmodels/locale_viewmodel.dart';

/// หน้าจอกำหนดการรับอุปกรณ์ไอทีและรายการจองตามสถาปัตยกรรม MVVM
/// รองรับการค้นหาแบบเรียลไทม์, จัดเรียงลำดับวันนัดรับ, กรองสถานะ, และสลับภาษาไทย/อังกฤษ
class MyBookingsView extends StatefulWidget {
  final VoidCallback? onLogout;

  const MyBookingsView({
    super.key,
    this.onLogout,
  });

  @override
  State<MyBookingsView> createState() => _MyBookingsViewState();
}

class _MyBookingsViewState extends State<MyBookingsView> {
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BookingViewModel>().loadBookings();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _updateStatus(int bookingId, String newStatus, String actionName) async {
    final localeVM = context.read<LocaleViewModel>();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${localeVM.isThai ? 'ยืนยัน' : 'Confirm'} $actionName'),
        content: Text(
          localeVM.isThai
              ? 'คุณต้องการ$actionName สำหรับรายการจอง #$bookingId ใช่หรือไม่?'
              : 'Are you sure you want to $actionName for booking #$bookingId?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(localeVM.t('btn_cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(localeVM.isThai ? 'ยืนยัน' : 'Confirm'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    final bookingVM = context.read<BookingViewModel>();
    final success = await bookingVM.updateStatus(bookingId, newStatus);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green.shade700,
            content: Text(
              localeVM.isThai ? '$actionName สำเร็จแล้ว!' : '$actionName completed successfully!',
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red.shade700,
            content: Text(
              localeVM.isThai
                  ? 'เกิดข้อผิดพลาด: ${bookingVM.errorMessage}'
                  : 'Error: ${bookingVM.errorMessage}',
            ),
          ),
        );
      }
    }
  }

  String _getSortLabel(String sortBy, LocaleViewModel localeVM) {
    switch (sortBy) {
      case 'pickup_desc':
        return localeVM.t('sort_pickup_desc');
      case 'created_desc':
        return localeVM.t('sort_booking_newest');
      default:
        return localeVM.t('sort_pickup_asc');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bookingVM = context.watch<BookingViewModel>();
    final localeVM = context.watch<LocaleViewModel>();

    final pendingCount = bookingVM.pendingCount;
    final pickedUpCount = bookingVM.pickedUpCount;
    final returnedCount = bookingVM.returnedCount;
    final totalCount = bookingVM.totalCount;

    final List<Map<String, String>> statusFilters = [
      {'key': 'ALL', 'label': localeVM.t('tab_all')},
      {'key': 'PENDING', 'label': localeVM.t('tab_pending')},
      {'key': 'PICKED_UP', 'label': localeVM.t('tab_picked_up')},
      {'key': 'RETURNED', 'label': localeVM.t('tab_returned')},
    ];

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              localeVM.t('schedule_title'),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 19),
            ),
            Text(
              localeVM.t('schedule_subtitle'),
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
            onPressed: () => bookingVM.loadBookings(),
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
          // 1. Summary Counters Banner
          Container(
            margin: const EdgeInsets.fromLTRB(16, 10, 16, 6),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.indigo.shade800, Colors.blue.shade700],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.indigo.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(localeVM.t('stat_pending'), '$pendingCount', Icons.alarm, Colors.amberAccent),
                Container(height: 30, width: 1, color: Colors.white24),
                _buildStatItem(localeVM.t('stat_picked_up'), '$pickedUpCount', Icons.assignment_turned_in, Colors.lightGreenAccent),
                Container(height: 30, width: 1, color: Colors.white24),
                _buildStatItem(localeVM.t('stat_returned'), '$returnedCount', Icons.check_circle_outline, Colors.white70),
              ],
            ),
          ),

          // 2. Real-time Search Box
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: localeVM.t('search_booking_hint'),
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          bookingVM.search('');
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
                bookingVM.search(val);
              },
            ),
          ),

          // 3. Status Filter Chips & Sorting Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                // Filter chips horizontally scrollable
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: statusFilters.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 6),
                      itemBuilder: (context, index) {
                        final item = statusFilters[index];
                        final isSelected = bookingVM.selectedStatus == item['key'];
                        int count;
                        switch (item['key']) {
                          case 'PENDING':
                            count = pendingCount;
                            break;
                          case 'PICKED_UP':
                            count = pickedUpCount;
                            break;
                          case 'RETURNED':
                            count = returnedCount;
                            break;
                          default:
                            count = totalCount;
                        }
                        return ChoiceChip(
                          label: Text('${item['label']} ($count)'),
                          selected: isSelected,
                          selectedColor: theme.colorScheme.primaryContainer,
                          labelStyle: TextStyle(
                            color: isSelected ? theme.colorScheme.primary : Colors.black87,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            fontSize: 12,
                          ),
                          onSelected: (selected) {
                            if (selected) {
                              bookingVM.setStatusFilter(item['key']!);
                            }
                          },
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Sorting Menu for Booking Schedules
                PopupMenuButton<String>(
                  tooltip: localeVM.t('sort_by'),
                  initialValue: bookingVM.sortBy,
                  onSelected: (val) => bookingVM.setSortBy(val),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
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
                          _getSortLabel(bookingVM.sortBy, localeVM),
                          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w500),
                        ),
                        const Icon(Icons.arrow_drop_down, size: 18),
                      ],
                    ),
                  ),
                  itemBuilder: (ctx) => [
                    PopupMenuItem(
                      value: 'pickup_asc',
                      child: Row(
                        children: [
                          const Icon(Icons.date_range, size: 18),
                          const SizedBox(width: 8),
                          Text(localeVM.t('sort_pickup_asc'), style: const TextStyle(fontSize: 13)),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'pickup_desc',
                      child: Row(
                        children: [
                          const Icon(Icons.event_repeat, size: 18),
                          const SizedBox(width: 8),
                          Text(localeVM.t('sort_pickup_desc'), style: const TextStyle(fontSize: 13)),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'created_desc',
                      child: Row(
                        children: [
                          const Icon(Icons.history, size: 18),
                          const SizedBox(width: 8),
                          Text(localeVM.t('sort_booking_newest'), style: const TextStyle(fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),

          // 4. Content List
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => bookingVM.loadBookings(),
              child: _buildBookingsContent(theme, bookingVM, localeVM),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String title, String count, IconData icon, Color color) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(
              count,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          title,
          style: const TextStyle(fontSize: 11, color: Colors.white70),
        ),
      ],
    );
  }

  Widget _buildBookingsContent(ThemeData theme, BookingViewModel bookingVM, LocaleViewModel localeVM) {
    if (bookingVM.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (bookingVM.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 54, color: Colors.redAccent),
              const SizedBox(height: 12),
              Text(
                localeVM.isThai ? 'โหลดข้อมูลการจองไม่สำเร็จ' : 'Failed to load bookings',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 6),
              Text(
                bookingVM.errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => bookingVM.loadBookings(),
                icon: const Icon(Icons.refresh),
                label: Text(localeVM.isThai ? 'ลองใหม่' : 'Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final displayedList = bookingVM.displayedBookings;

    if (displayedList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              localeVM.t('empty_bookings'),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              localeVM.t('empty_bookings_sub'),
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      itemCount: displayedList.length,
      itemBuilder: (context, index) => _buildBookingCard(displayedList[index], theme, localeVM),
    );
  }

  Widget _buildBookingCard(Booking item, ThemeData theme, LocaleViewModel localeVM) {
    final authVM = context.watch<AuthViewModel>();
    final isOwner = authVM.isBookingOwner(item);
    final isAdmin = authVM.isAdmin;
    final canManage = authVM.canManageBooking(item);

    final eq = item.equipmentDetail;
    final isPending = item.status == 'PENDING';
    final isPickedUp = item.status == 'PICKED_UP';
    final isReturned = item.status == 'RETURNED';
    final isCancelled = item.status == 'CANCELLED';

    Color statusColor;
    Color statusBgColor;
    IconData statusIcon;
    String statusDisplay;

    switch (item.status) {
      case 'PENDING':
      case 'APPROVED':
        statusColor = Colors.orange.shade800;
        statusBgColor = Colors.orange.shade50;
        statusIcon = Icons.hourglass_top_rounded;
        statusDisplay = localeVM.t('stat_pending');
        break;
      case 'PICKED_UP':
        statusColor = Colors.green.shade800;
        statusBgColor = Colors.green.shade50;
        statusIcon = Icons.thumb_up_alt_outlined;
        statusDisplay = localeVM.t('stat_picked_up');
        break;
      case 'RETURNED':
        statusColor = Colors.teal.shade800;
        statusBgColor = Colors.teal.shade50;
        statusIcon = Icons.task_alt;
        statusDisplay = localeVM.t('stat_returned');
        break;
      case 'CANCELLED':
        statusColor = Colors.red.shade800;
        statusBgColor = Colors.red.shade50;
        statusIcon = Icons.cancel_outlined;
        statusDisplay = localeVM.t('status_cancelled');
        break;
      default:
        statusColor = Colors.grey.shade700;
        statusBgColor = Colors.grey.shade100;
        statusIcon = Icons.info_outline;
        statusDisplay = item.status;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row: Booking ID, Owner/Admin Badge and Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.qr_code, size: 18, color: theme.colorScheme.primary),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${localeVM.t('booking_id')} #${item.id}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    if (isOwner) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue.shade300),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.person_pin, size: 13, color: Colors.blue.shade800),
                            const SizedBox(width: 4),
                            Text(
                              localeVM.t('owner_badge'),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else if (isAdmin) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.purple.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.purple.shade300),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.admin_panel_settings, size: 13, color: Colors.purple.shade800),
                            const SizedBox(width: 4),
                            Text(
                              localeVM.t('admin_badge'),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.purple.shade900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusBgColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 14, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        statusDisplay,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 20),

            // Equipment info
            Text(
              eq?.name ?? (localeVM.isThai ? 'อุปกรณ์ไอที' : 'IT Equipment'),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            if (eq?.modelNumber != null && eq!.modelNumber!.isNotEmpty)
              Text(
                '${localeVM.isThai ? 'รหัสครุภัณฑ์:' : 'Model/SN:'} ${eq.modelNumber}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            const SizedBox(height: 12),

            // Pickup & Return Schedule Highlight Box
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.calendar_month, size: 20, color: Colors.amber.shade900),
                      const SizedBox(width: 8),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: const TextStyle(fontSize: 13, color: Colors.black87),
                            children: [
                              TextSpan(
                                text: '${localeVM.t('pickup_schedule_label')} ',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              TextSpan(
                                text: '${item.pickupDate} ${localeVM.isThai ? 'เวลา' : 'at'} ${item.pickupTime.substring(0, 5)} ${localeVM.isThai ? 'น.' : ''}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.amber.shade900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 18, color: Colors.blue.shade800),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${localeVM.t('pickup_location_label')} ${eq?.pickupLocation ?? 'ห้องบริการไอที อาคาร EN2'}',
                          style: TextStyle(fontSize: 12, color: Colors.blue.shade900),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.event_repeat, size: 18, color: Colors.grey.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${localeVM.t('return_schedule_label')} ${item.returnDate}',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade800),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Borrower details
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.person, size: 16, color: Colors.blueGrey),
                      const SizedBox(width: 6),
                      Text(
                        '${localeVM.t('borrower_label')} ${item.borrowerName} (${item.borrowerStudentId.isNotEmpty ? item.borrowerStudentId : (localeVM.isThai ? 'บุคคลทั่วไป' : 'General User')})',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.phone, size: 16, color: Colors.blueGrey),
                      const SizedBox(width: 6),
                      Text('${localeVM.t('phone_label')} ${item.borrowerPhone}', style: const TextStyle(fontSize: 12)),
                      const Spacer(),
                      const Icon(Icons.layers, size: 16, color: Colors.blueGrey),
                      const SizedBox(width: 6),
                      Text(
                        '${localeVM.t('quantity_label')} ${item.quantity} ${localeVM.isThai ? 'เครื่อง' : 'unit(s)'}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  if (item.purpose.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline, size: 16, color: Colors.blueGrey),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '${localeVM.t('purpose_label')} ${item.purpose}',
                            style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Action Buttons: Only Owner or Admin can Cancel or Return
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (isPending) ...[
                  if (canManage) ...[
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red.shade700,
                        side: BorderSide(color: Colors.red.shade300),
                      ),
                      onPressed: () => _updateStatus(
                        item.id,
                        'CANCELLED',
                        localeVM.isThai ? 'ยกเลิกการจอง' : 'Cancel Booking',
                      ),
                      icon: const Icon(Icons.cancel_outlined, size: 16),
                      label: Text(localeVM.t('btn_cancel_booking')),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => _updateStatus(
                        item.id,
                        'PICKED_UP',
                        localeVM.isThai ? 'รับอุปกรณ์แล้ว' : 'Mark Picked Up',
                      ),
                      icon: const Icon(Icons.check, size: 16),
                      label: Text(localeVM.t('btn_confirm_pickup')),
                    ),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.amber.shade300),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.lock_outline, size: 14, color: Colors.amber.shade900),
                          const SizedBox(width: 6),
                          Text(
                            authVM.isAuthenticated
                                ? localeVM.t('permission_denied_cancel')
                                : localeVM.t('permission_login_required'),
                            style: TextStyle(
                              fontSize: 11.5,
                              color: Colors.amber.shade900,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ] else if (isPickedUp) ...[
                  if (canManage) ...[
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal.shade700,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => _updateStatus(
                        item.id,
                        'RETURNED',
                        localeVM.isThai ? 'คืนอุปกรณ์เรียบร้อยแล้ว' : 'Mark Returned',
                      ),
                      icon: const Icon(Icons.assignment_return, size: 16),
                      label: Text(localeVM.t('btn_confirm_return')),
                    ),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.amber.shade300),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.lock_outline, size: 14, color: Colors.amber.shade900),
                          const SizedBox(width: 6),
                          Text(
                            authVM.isAuthenticated
                                ? localeVM.t('permission_denied_return')
                                : localeVM.t('permission_login_required'),
                            style: TextStyle(
                              fontSize: 11.5,
                              color: Colors.amber.shade900,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ] else if (isReturned) ...[
                  Chip(
                    avatar: const Icon(Icons.check_circle, color: Colors.teal, size: 16),
                    label: Text(
                      localeVM.t('status_completed'),
                      style: const TextStyle(fontSize: 11, color: Colors.teal),
                    ),
                    backgroundColor: Colors.teal.shade50,
                  ),
                ] else if (isCancelled) ...[
                  Chip(
                    avatar: const Icon(Icons.cancel_outlined, color: Colors.red, size: 16),
                    label: Text(
                      localeVM.t('status_cancelled_full'),
                      style: const TextStyle(fontSize: 11, color: Colors.red),
                    ),
                    backgroundColor: Colors.red.shade50,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
