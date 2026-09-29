import 'package:flutter/material.dart';
import '../models/booking.dart';
import '../services/api_service.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  final ApiService _apiService = ApiService();

  List<Booking> _bookings = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _selectedStatus = 'ALL';

  final List<Map<String, String>> _statusFilters = [
    {'key': 'ALL', 'label': 'ทั้งหมด'},
    {'key': 'PENDING', 'label': 'รอนัดรับ'},
    {'key': 'APPROVED', 'label': 'พร้อมรับ'},
    {'key': 'PICKED_UP', 'label': 'รับอุปกรณ์แล้ว'},
    {'key': 'RETURNED', 'label': 'คืนแล้ว'},
  ];

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final list = await _apiService.fetchBookings(status: _selectedStatus);
      if (mounted) {
        setState(() {
          _bookings = list;
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

    if (confirm != true) return;

    try {
      await _apiService.updateBookingStatus(bookingId, newStatus);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green.shade700,
            content: Text('$actionName สำเร็จแล้ว!'),
          ),
        );
        _loadBookings();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red.shade700,
            content: Text('เกิดข้อผิดพลาด: $e'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final pendingCount = _bookings.where((b) => b.status == 'PENDING' || b.status == 'APPROVED').length;
    final pickedUpCount = _bookings.where((b) => b.status == 'PICKED_UP').length;
    final returnedCount = _bookings.where((b) => b.status == 'RETURNED').length;

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
            onPressed: _loadBookings,
          ),
        ],
      ),
      body: Column(
        children: [
          // Summary Counters Banner
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
                final isSelected = _selectedStatus == item['key'];
                return ChoiceChip(
                  label: Text(item['label']!),
                  selected: isSelected,
                  selectedColor: theme.colorScheme.primaryContainer,
                  labelStyle: TextStyle(
                    color: isSelected ? theme.colorScheme.primary : Colors.black87,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 13,
                  ),
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedStatus = item['key']!);
                      _loadBookings();
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
              onRefresh: _loadBookings,
              child: _buildBookingsContent(theme),
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

  Widget _buildBookingsContent(ThemeData theme) {
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
              const Icon(Icons.error_outline, size: 54, color: Colors.redAccent),
              const SizedBox(height: 12),
              Text('โหลดข้อมูลการจองไม่สำเร็จ', style: theme.textTheme.titleMedium),
              const SizedBox(height: 6),
              Text(_errorMessage!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadBookings,
                icon: const Icon(Icons.refresh),
                label: const Text('ลองใหม่'),
              ),
            ],
          ),
        ),
      );
    }

    if (_bookings.isEmpty) {
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
      itemCount: _bookings.length,
      itemBuilder: (context, index) => _buildBookingCard(_bookings[index], theme),
    );
  }

  Widget _buildBookingCard(Booking item, ThemeData theme) {
    final eq = item.equipmentDetail;
    final isPending = item.status == 'PENDING';
    final isApproved = item.status == 'APPROVED';
    final isPickedUp = item.status == 'PICKED_UP';
    final isReturned = item.status == 'RETURNED';

    Color statusColor;
    Color statusBgColor;
    IconData statusIcon;

    switch (item.status) {
      case 'PENDING':
        statusColor = Colors.orange.shade800;
        statusBgColor = Colors.orange.shade50;
        statusIcon = Icons.hourglass_top_rounded;
        break;
      case 'APPROVED':
        statusColor = Colors.blue.shade800;
        statusBgColor = Colors.blue.shade50;
        statusIcon = Icons.check_circle_outline;
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

            // Pickup & Return Schedule Highlight Box (หัวใจสำคัญของการนัดหมายวัน-เวลา)
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
                          'สถานที่รับ: ${eq?.pickupLocation ?? 'ห้องบริการไอที'}',
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
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.person, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'ผู้ยืม: ${item.borrowerName}',
                          style: const TextStyle(fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.phone, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(item.borrowerPhone, style: const TextStyle(fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.lightbulb_outline, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'วัตถุประสงค์: ${item.purpose}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Action Buttons for Pick-up / Return
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (isPending || isApproved) ...[
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('ยืนยันการรับอุปกรณ์ (Pick-Up)', style: TextStyle(fontSize: 12)),
                    onPressed: () => _updateStatus(item.id, 'PICKED_UP', 'รับอุปกรณ์'),
                  ),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red.shade700,
                      side: BorderSide(color: Colors.red.shade300),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                    icon: const Icon(Icons.cancel_outlined, size: 16),
                    label: const Text('ยกเลิกการจอง', style: TextStyle(fontSize: 12)),
                    onPressed: () => _updateStatus(item.id, 'CANCELLED', 'ยกเลิกการจอง'),
                  ),
                ],
                if (isPickedUp) ...[
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal.shade700,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                    icon: const Icon(Icons.assignment_return_outlined, size: 16),
                    label: const Text('บันทึกการส่งคืนอุปกรณ์', style: TextStyle(fontSize: 12)),
                    onPressed: () => _updateStatus(item.id, 'RETURNED', 'คืนอุปกรณ์'),
                  ),
                ],
                if (isReturned) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.done_all, size: 16, color: Colors.teal.shade700),
                        const SizedBox(width: 6),
                        const Text(
                          'ดำเนินการเสร็จสมบูรณ์แล้ว',
                          style: TextStyle(fontSize: 12, color: Colors.black54),
                        ),
                      ],
                    ),
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
