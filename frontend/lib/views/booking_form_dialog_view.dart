import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/equipment.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/booking_viewmodel.dart';

/// ไดอะล็อกแบบฟอร์มการจองอุปกรณ์ไอทีตามสถาปัตยกรรม MVVM
/// รับข้อมูลผู้ใช้จาก AuthViewModel และส่งข้อมูลการจองผ่าน BookingViewModel
class BookingFormDialogView extends StatefulWidget {
  final Equipment equipment;
  final VoidCallback onBookingSuccess;

  const BookingFormDialogView({
    super.key,
    required this.equipment,
    required this.onBookingSuccess,
  });

  @override
  State<BookingFormDialogView> createState() => _BookingFormDialogViewState();
}

class _BookingFormDialogViewState extends State<BookingFormDialogView> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _studentIdCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _purposeCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  late DateTime _pickupDate;
  late TimeOfDay _pickupTime;
  late DateTime _returnDate;
  int _quantity = 1;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _pickupDate = now.add(const Duration(days: 1));
    _pickupTime = const TimeOfDay(hour: 9, minute: 30);
    _returnDate = now.add(const Duration(days: 3));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // ดึง Claims จาก AuthViewModel เพื่อเติมข้อมูลอัตโนมัติ
      final authVM = context.read<AuthViewModel>();
      final claims = authVM.claims;
      if (claims != null && claims.isNotEmpty) {
        _nameCtrl.text = claims['name'] ?? claims['preferred_username'] ?? '';
        _emailCtrl.text = claims['email'] ?? '';
        if (claims['student_id'] != null) {
          _studentIdCtrl.text = claims['student_id'].toString();
        } else if (claims['sub'] != null) {
          _studentIdCtrl.text = '6600000${claims['sub']}';
        }
      } else if (authVM.username != null && authVM.username!.isNotEmpty) {
        _nameCtrl.text = authVM.username!;
      }
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _studentIdCtrl.dispose();
    _emailCtrl.dispose();
    _purposeCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  String _formatTime(TimeOfDay t) {
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:00';
  }

  Future<void> _selectPickupDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _pickupDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (picked != null) {
      setState(() {
        _pickupDate = picked;
        if (_returnDate.isBefore(_pickupDate)) {
          _returnDate = _pickupDate.add(const Duration(days: 1));
        }
      });
    }
  }

  Future<void> _selectPickupTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _pickupTime,
    );
    if (picked != null) {
      setState(() {
        _pickupTime = picked;
      });
    }
  }

  Future<void> _selectReturnDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _returnDate,
      firstDate: _pickupDate,
      lastDate: DateTime.now().add(const Duration(days: 120)),
    );
    if (picked != null) {
      setState(() {
        _returnDate = picked;
      });
    }
  }

  Future<void> _submitBooking() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final payload = {
      'equipment_id': widget.equipment.id,
      'borrower_name': _nameCtrl.text.trim(),
      'borrower_phone': _phoneCtrl.text.trim(),
      'borrower_student_id': _studentIdCtrl.text.trim(),
      'borrower_email': _emailCtrl.text.trim(),
      'quantity': _quantity,
      'pickup_date': _formatDate(_pickupDate),
      'pickup_time': _formatTime(_pickupTime),
      'return_date': _formatDate(_returnDate),
      'purpose': _purposeCtrl.text.trim(),
      'note': _noteCtrl.text.trim(),
      'status': 'PENDING',
    };

    // ส่งผ่าน BookingViewModel ตามหลัก MVVM
    final bookingVM = context.read<BookingViewModel>();
    final success = await bookingVM.createBooking(payload);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      Navigator.of(context).pop();
      widget.onBookingSuccess();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green.shade700,
          content: Text(
            'จองอุปกรณ์สำเร็จ! นัดรับวันที่ ${_formatDate(_pickupDate)} เวลา ${_pickupTime.format(context)}',
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade700,
          content: Text(bookingVM.errorMessage ?? 'เกิดข้อผิดพลาดในการจอง'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 550, maxHeight: 720),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.event_available_rounded,
                      color: theme.colorScheme.primary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'แบบฟอร์มจองอุปกรณ์ไอที',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          widget.equipment.name,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  )
                ],
              ),
              const Divider(height: 20),

              // Form fields
              Expanded(
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Equipment location badge
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.blue.shade100),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.location_on_outlined, size: 20, color: Colors.blue.shade800),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'จุดรับอุปกรณ์: ${widget.equipment.pickupLocation}',
                                  style: TextStyle(fontSize: 13, color: Colors.blue.shade900),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Section 1: Pickup Schedule
                        Text(
                          'วันและเวลาที่นัดหมายเข้ารับอุปกรณ์',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.calendar_today, size: 18),
                                label: Text(
                                  'วันที่รับ: ${_formatDate(_pickupDate)}',
                                  style: const TextStyle(fontSize: 13),
                                ),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                onPressed: _selectPickupDate,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 2,
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.access_time, size: 18),
                                label: Text(
                                  _pickupTime.format(context),
                                  style: const TextStyle(fontSize: 13),
                                ),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                onPressed: _selectPickupTime,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Return Date
                        OutlinedButton.icon(
                          icon: const Icon(Icons.event_repeat, size: 18),
                          label: Text(
                            'กำหนดคืนอุปกรณ์: ${_formatDate(_returnDate)}',
                            style: const TextStyle(fontSize: 13),
                          ),
                          style: OutlinedButton.styleFrom(
                            alignment: Alignment.centerLeft,
                            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: _selectReturnDate,
                        ),
                        const SizedBox(height: 16),

                        // Section 2: Borrower Information
                        Text(
                          'ข้อมูลผู้ขอยืม',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _nameCtrl,
                          decoration: InputDecoration(
                            labelText: 'ชื่อ - นามสกุล *',
                            prefixIcon: const Icon(Icons.person_outline),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'กรุณากรอกชื่อ-นามสกุล' : null,
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _phoneCtrl,
                                keyboardType: TextInputType.phone,
                                decoration: InputDecoration(
                                  labelText: 'เบอร์โทรศัพท์ *',
                                  prefixIcon: const Icon(Icons.phone_outlined),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                ),
                                validator: (v) => (v == null || v.trim().isEmpty) ? 'กรุณากรอกเบอร์โทร' : null,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextFormField(
                                controller: _studentIdCtrl,
                                decoration: InputDecoration(
                                  labelText: 'รหัสนักศึกษา/บุคลากร',
                                  prefixIcon: const Icon(Icons.badge_outlined),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _purposeCtrl,
                          maxLines: 2,
                          decoration: InputDecoration(
                            labelText: 'วัตถุประสงค์การยืมใช้งาน *',
                            hintText: 'เช่น นำเสนอโครงงาน Mobile Dev, จัดสัมมนา',
                            prefixIcon: const Icon(Icons.assignment_outlined),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'กรุณาระบุวัตถุประสงค์' : null,
                        ),
                        const SizedBox(height: 12),

                        // Quantity selector
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'จำนวนที่ต้องการยืม (สูงสุด ${widget.equipment.availableQuantity} เครื่อง):',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove, size: 18),
                                    onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null,
                                  ),
                                  Text(
                                    '$_quantity',
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add, size: 18),
                                    onPressed: _quantity < widget.equipment.availableQuantity
                                        ? () => setState(() => _quantity++)
                                        : null,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),
              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('ยกเลิก'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: _isLoading ? null : _submitBooking,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.check_circle_outline),
                      label: Text(_isLoading ? 'กำลังบันทึก...' : 'ยืนยันนัดหมายจอง'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
