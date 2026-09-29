from django.db import models
from django.contrib.auth.models import User

class Equipment(models.Model):
    CATEGORY_CHOICES = [
        ('laptop', 'โน้ตบุ๊ก & คอมพิวเตอร์ (Laptop & PC)'),
        ('projector', 'โปรเจกเตอร์ & จอแสดงผล (Projector & Display)'),
        ('tablet', 'แท็บเล็ต & ไอแพด (Tablet & iPad)'),
        ('audio_video', 'กล้อง & ระบบเสียง (Camera & Audio)'),
        ('accessories', 'อุปกรณ์เสริม & หัวแปลง (Adapters & Accessories)'),
    ]

    name = models.CharField(max_length=200, verbose_name="ชื่ออุปกรณ์")
    category = models.CharField(max_length=50, choices=CATEGORY_CHOICES, default='laptop', verbose_name="หมวดหมู่")
    model_number = models.CharField(max_length=100, blank=True, null=True, verbose_name="รุ่น/รหัสครุภัณฑ์")
    description = models.TextField(blank=True, verbose_name="รายละเอียดสเปก")
    image_url = models.URLField(blank=True, verbose_name="URL รูปภาพ")
    total_quantity = models.PositiveIntegerField(default=5, verbose_name="จำนวนทั้งหมด")
    available_quantity = models.PositiveIntegerField(default=5, verbose_name="จำนวนที่พร้อมให้ยืม")
    pickup_location = models.CharField(max_length=200, default="ห้องบริการไอที อาคาร EN2 ชั้น 1", verbose_name="สถานที่รับอุปกรณ์")
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['name']
        verbose_name = "อุปกรณ์ไอที"
        verbose_name_plural = "อุปกรณ์ไอทีทั้งหมด"

    def __str__(self):
        return f"{self.name} ({self.get_category_display()})"


class Booking(models.Model):
    STATUS_CHOICES = [
        ('PENDING', 'รอดำเนินการ / นัดหมายรับ'),
        ('APPROVED', 'อนุมัติแล้ว / พร้อมรับ'),
        ('PICKED_UP', 'รับอุปกรณ์แล้ว'),
        ('RETURNED', 'คืนอุปกรณ์เรียบร้อยแล้ว'),
        ('CANCELLED', 'ยกเลิกการจอง'),
    ]

    user = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, blank=True, related_name='it_bookings')
    borrower_name = models.CharField(max_length=150, verbose_name="ชื่อ-นามสกุล ผู้ขอยืม")
    borrower_phone = models.CharField(max_length=20, verbose_name="เบอร์โทรติดต่อ")
    borrower_student_id = models.CharField(max_length=30, blank=True, verbose_name="รหัสนักศึกษา/บุคลากร")
    borrower_email = models.EmailField(blank=True, verbose_name="อีเมล")
    
    equipment = models.ForeignKey(Equipment, on_delete=models.CASCADE, related_name='bookings', verbose_name="อุปกรณ์ที่จอง")
    quantity = models.PositiveIntegerField(default=1, verbose_name="จำนวนที่จอง")
    
    pickup_date = models.DateField(verbose_name="วันที่เข้ารับอุปกรณ์")
    pickup_time = models.TimeField(verbose_name="เวลาที่เข้ารับอุปกรณ์")
    return_date = models.DateField(verbose_name="วันที่กำหนดคืนอุปกรณ์")
    
    purpose = models.TextField(verbose_name="วัตถุประสงค์ในการยืมใช้งาน")
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='PENDING', verbose_name="สถานะ")
    note = models.TextField(blank=True, verbose_name="หมายเหตุเพิ่มเติม")
    created_at = models.DateTimeField(auto_now_add=True, verbose_name="วันที่ทำรายการจอง")

    class Meta:
        ordering = ['-created_at']
        verbose_name = "รายการจองอุปกรณ์"
        verbose_name_plural = "รายการจองอุปกรณ์ทั้งหมด"

    def __str__(self):
        return f"จอง #{self.id} - {self.equipment.name} โดย {self.borrower_name} (นัดรับ {self.pickup_date} {self.pickup_time})"