import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/booking.dart';
import '../viewmodels/booking_viewmodel.dart';

/// หน้าจอกำหนดการรับอุปกรณ์ไอทีและรายการจองตามสถาปัตยกรรม MVVM
/// ติดต่อกับ BookingViewModel ผ่าน Provider เท่านั้น ไม่ติดต่อ Service โดยตรง
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
  final List<Map<String, String>> _statusFilters = const [
    {'key': 'ALL', 'label': 'ทั้งหมด'},
    {'key': 'PENDING', 'label': 'รอนัดรับ'},
    {'key': 'PICKED_UP', 'label': 'รับอุปกรณ์แล้ว'},
    {'key': 'RETURNED', 'label': 'คืนแล้ว'},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BookingViewModel>().loadBookings();
    });
  }

  Future<void> _updateStatus(int bookingId, String newStatus, String actionName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('ยืนยัน$actionName'),
        content: Text('คุณต้องการ$actionName สำหรับรายการจอง #$bookingId ใช่หรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('ยืนยัน'),
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
            content: Text('$actionName สำเร็จแล้ว!'),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red.shade700,
            content: Text('เกิดข้อผิดพลาด: ${bookingVM.errorMessage}'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bookingVM = context.watch<BookingViewModel>();

    final pendingCount = bookingVM.pendingCount;
    final pickedUpCount = bookingVM.pickedUpCount;
    final returnedCount = bookingVM.returnedCount;
    final totalCount = bookingVM.totalCount;

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'กำหนดการรับอุปกรณ์ไอที',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            Text(
              'ตรวจสอบวัน-เวลานัดรับ และจัดการสถานะ',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'รีเฟรชข้อมูล',
            onPressed: () => bookingVM.loadBookings(),
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
          // Summary Counters Banner (คำนวณจากยอดรวม ไม่ลดเป็น 0 เมื่อกดสลับแท็บ)
          Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
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
                _buildStatItem('รอนัดรับ', '$pendingCount', Icons.alarm, Colors.amberAccent),
                Container(height: 30, width: 1, color: Colors.white24),
                _buildStatItem('รับแล้ว', '$pickedUpCount', Icons.assignment_turned_in, Colors.lightGreenAccent),
                Container(height: 30, width: 1, color: Colors.white24),
                _buildStatItem('คืนเรียบร้อย', '$returnedCount', Icons.check_circle_outline, Colors.white70),
              ],
            ),
          ),

          // Status Filter Chips
          SizedBox(
            height: 48,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: _statusFilters.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final item = _statusFilters[index];
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
                    fontSize: 13,
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
          const SizedBox(height: 8),

          // Content List
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => bookingVM.loadBookings(),
              child: _buildBookingsContent(theme, bookingVM),
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

  Widget _buildBookingsContent(ThemeData theme, BookingViewModel bookingVM) {
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
              Text('โหลดข้อมูลการจองไม่สำเร็จ', style: theme.textTheme.titleMedium),
              const SizedBox(height: 6),
              Text(bookingVM.errorMessage!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => bookingVM.loadBookings(),
                icon: const Icon(Icons.refresh),
                label: const Text('ลองใหม่'),
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
            const Text(
              'ยังไม่มีรายการจองตามเงื่อนไขที่เลือก',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              'คุณสามารถไปที่แท็บ "อุปกรณ์ไอที" เพื่อเลือกจองอุปกรณ์ได้',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: displayedList.length,
      itemBuilder: (context, index) => _buildBookingCard(displayedList[index], theme),
    );
  }

  Widget _buildBookingCard(Booking item, ThemeData theme) {
    final eq = item.equipmentDetail;
    final isPending = item.status == 'PENDING';
    final isPickedUp = item.status == 'PICKED_UP';
    final isReturned = item.status == 'RETURNED';

    Color statusColor;
    Color statusBgColor;
    IconData statusIcon;

    switch (item.status) {
      case 'PENDING':
      case 'APPROVED':
        statusColor = Colors.orange.shade800;
        statusBgColor = Colors.orange.shade50;
        statusIcon = Icons.hourglass_top_rounded;
        break;
      case 'PICKED_UP':
        statusColor = Colors.green.shade800;
        statusBgColor = Colors.green.shade50;
        statusIcon = Icons.thumb_up_alt_outlined;
        break;
      case 'RETURNED':
        statusColor = Colors.teal.shade800;
        statusBgColor = Colors.teal.shade50;
        statusIcon = Icons.task_alt;
        break;
      default:
        statusColor = Colors.grey.shade700;
        statusBgColor = Colors.grey.shade100;
        statusIcon = Icons.info_outline;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row: Booking ID and Status
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
                      'รหัสการจอง #${item.id}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
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
                        item.statusDisplay.isNotEmpty ? item.statusDisplay : item.status,
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
              eq?.name ?? 'อุปกรณ์ไอที',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            if (eq?.modelNumber != null && eq!.modelNumber!.isNotEmpty)
              Text(
                'รหัสครุภัณฑ์: ${eq.modelNumber}',
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
                              const TextSpan(text: 'นัดหมายเข้ารับ: ', style: TextStyle(fontWeight: FontWeight.bold)),
                              TextSpan(
                                text: '${item.pickupDate} เวลา ${item.pickupTime.substring(0, 5)} น.',
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
                          'สถานที่รับ: ${eq?.pickupLocation ?? 'ห้องบริการไอที อาคาร EN2'}',
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
                          'กำหนดคืนอุปกรณ์: ${item.returnDate}',
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
                      Text('ผู้ยืม: ${item.borrowerName} (${item.borrowerStudentId.isNotEmpty ? item.borrowerStudentId : 'บุคคลทั่วไป'})',
                          style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.phone, size: 16, color: Colors.blueGrey),
                      const SizedBox(width: 6),
                      Text('เบอร์โทร: ${item.borrowerPhone}', style: const TextStyle(fontSize: 12)),
                      const Spacer(),
                      const Icon(Icons.layers, size: 16, color: Colors.blueGrey),
                      const SizedBox(width: 6),
                      Text('จำนวน: ${item.quantity} เครื่อง', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
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
                            'วัตถุประสงค์: ${item.purpose}',
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

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (isPending) ...[
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red.shade700,
                      side: BorderSide(color: Colors.red.shade300),
                    ),
                    onPressed: () => _updateStatus(item.id, 'CANCELLED', 'ยกเลิกการจอง'),
                    icon: const Icon(Icons.cancel_outlined, size: 16),
                    label: const Text('ยกเลิกการจอง'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => _updateStatus(item.id, 'PICKED_UP', 'รับอุปกรณ์แล้ว'),
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('รับอุปกรณ์แล้ว'),
                  ),
                ] else if (isPickedUp) ...[
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal.shade700,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => _updateStatus(item.id, 'RETURNED', 'คืนอุปกรณ์เรียบร้อยแล้ว'),
                    icon: const Icon(Icons.assignment_return, size: 16),
                    label: const Text('คืนอุปกรณ์แล้ว'),
                  ),
                ] else if (isReturned) ...[
                  Chip(
                    avatar: const Icon(Icons.check_circle, color: Colors.teal, size: 16),
                    label: const Text('ดำเนินการเสร็จสิ้นเรียบร้อยแล้ว', style: TextStyle(fontSize: 11, color: Colors.teal)),
                    backgroundColor: Colors.teal.shade50,
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
