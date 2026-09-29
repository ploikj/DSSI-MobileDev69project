import 'equipment.dart';

class Booking {
  final int id;
  final String borrowerName;
  final String borrowerPhone;
  final String borrowerStudentId;
  final String borrowerEmail;
  final int quantity;
  final String pickupDate;
  final String pickupTime;
  final String returnDate;
  final String purpose;
  final String status;
  final String statusDisplay;
  final String note;
  final Equipment? equipmentDetail;
  final String? createdAt;

  Booking({
    required this.id,
    required this.borrowerName,
    required this.borrowerPhone,
    required this.borrowerStudentId,
    required this.borrowerEmail,
    required this.quantity,
    required this.pickupDate,
    required this.pickupTime,
    required this.returnDate,
    required this.purpose,
    required this.status,
    required this.statusDisplay,
    required this.note,
    this.equipmentDetail,
    this.createdAt,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'] as int,
      borrowerName: json['borrower_name'] as String? ?? '',
      borrowerPhone: json['borrower_phone'] as String? ?? '',
      borrowerStudentId: json['borrower_student_id'] as String? ?? '',
      borrowerEmail: json['borrower_email'] as String? ?? '',
      quantity: json['quantity'] as int? ?? 1,
      pickupDate: json['pickup_date'] as String? ?? '',
      pickupTime: json['pickup_time'] as String? ?? '',
      returnDate: json['return_date'] as String? ?? '',
      purpose: json['purpose'] as String? ?? '',
      status: json['status'] as String? ?? 'PENDING',
      statusDisplay: json['status_display'] as String? ?? '',
      note: json['note'] as String? ?? '',
      equipmentDetail: json['equipment_detail'] != null
          ? Equipment.fromJson(json['equipment_detail'] as Map<String, dynamic>)
          : null,
      createdAt: json['created_at'] as String?,
    );
  }
}
