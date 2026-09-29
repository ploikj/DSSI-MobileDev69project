# ระบบจองอุปกรณ์ไอทีและนัดหมายเข้ารับ (IT Equipment Booking System)
**รายวิชา:** Mobile Application Development (Mobile Dev 2569) มหาวิทยาลัยอุบลราชธานี (UBU)  
**ผู้จัดทำ:** ณราธิป (`narathip-mobiledev69`)

---

## 📌 ภาพรวมโครงงาน (Project Overview)
ระบบจองอุปกรณ์ไอทีสำหรับการเรียนการสอน กิจกรรม และการทำงานวิจัย โดยรองรับการเลือกดูอุปกรณ์ นัดหมายวันและเวลาเข้ารับอุปกรณ์ล่วงหน้า และติดตามสถานะการยืม-คืน

### ✨ ฟีเจอร์หลัก (Key Features)
1. **คลังอุปกรณ์ไอที (Equipment Catalog)**
   - ค้นหาอุปกรณ์ตามชื่อและประเภท (โน้ตบุ๊ก & PC, โปรเจกเตอร์, แท็บเล็ต/iPad, กล้อง & ระบบเสียง, อุปกรณ์เสริม)
   - แสดงสถานะความพร้อม (จำนวนคงเหลือ / ถูกยืมหมดแล้ว)
   - แสดงจุดรับอุปกรณ์ (เช่น อาคาร EN2 ชั้น 1, อาคารเรียนรวม ชั้น 2)
2. **ระบบนัดหมายวัน-เวลาเข้ารับ (Pickup & Return Scheduling)**
   - ฟอร์มเลือก **วันที่เข้ารับ** (Pickup Date) และ **เวลาที่เข้ารับ** (Pickup Time)
   - กำหนดวันที่ต้องส่งคืน (Return Date)
   - บันทึกชื่อผู้ขอยืม, เบอร์โทร, รหัสนักศึกษา และวัตถุประสงค์การใช้งาน
   - ตัดสต็อกอัตโนมัติเมื่อมีการจอง
3. **ติดตามและจัดการสถานะ (Pickup Tickets & Status Tracking)**
   - บัตรนัดรับอุปกรณ์ แสดงเวลานัดและสถานที่ชัดเจน
   - สถานะการจอง: `รอดำเนินการ / นัดรับ` ➔ `รับอุปกรณ์แล้ว (Pick-Up)` ➔ `คืนอุปกรณ์แล้ว (Return)`
   - คืนสต็อกอุปกรณ์เข้าสู่ระบบทันทีเมื่อมีการส่งคืนหรือยกเลิก
4. **ระบบยืนยันตัวตน (JWT Authentication - Week 14 Demo)**
   - รองรับการล็อกอินรับ Access Token และ Refresh Token ผ่าน Django SimpleJWT
   - ปรับเปลี่ยน Base URL สำหรับทดสอบได้ทันที (Web / Android Emulator `10.0.2.2:8000` / IP เครื่องจริง)

---

## 🚀 วิธีการติดตั้งและรันโปรเจกต์ (How to Run)

### 1. ฝั่งระบบหลังบ้าน (Backend - Django)
```bash
cd backend

# รัน Server
uv run python manage.py runserver 0.0.0.0:8000
```
* **API Endpoints:**
  * `GET /api/equipments/` : ดูรายการอุปกรณ์
  * `GET /api/bookings/` : ดูรายการจองทั้งหมด
  * `POST /api/bookings/` : สร้างรายการจองใหม่
  * `PATCH /api/bookings/<id>/` : อัปเดตสถานะ (รับอุปกรณ์/คืนอุปกรณ์)
  * `POST /api/token/` : ล็อกอินรับ JWT Token
* **Admin Dashboard:** `http://127.0.0.1:8000/admin/`
  * Username: `admin`
  * Password: `admin1234`

### 2. ฝั่งแอปพลิเคชันมือถือ (Frontend - Flutter)
```bash
cd frontend

# ตรวจสอบ dependencies และรันแอป
flutter pub get
flutter run
```

---

## 🛠 เทคโนโลยีที่ใช้ (Tech Stack)
* **Backend:** Python 3, Django, Django REST Framework (DRF), SimpleJWT, SQLite, `uv`
* **Frontend:** Flutter (Dart), Material 3, HTTP Client
