/// Service สำหรับจัดเก็บพจนานุกรมแปลภาษาไทยและภาษาอังกฤษ (i18n)
class LocalizationService {
  static const Map<String, Map<String, String>> _translations = {
    // --- Navigation ---
    'nav_equipment': {
      'th': 'อุปกรณ์ไอที',
      'en': 'IT Equipments',
    },
    'nav_schedule': {
      'th': 'กำหนดการรับ',
      'en': 'Pickups & Schedule',
    },
    'nav_oidc': {
      'th': 'ข้อมูล OIDC',
      'en': 'OIDC & Settings',
    },
    'app_title': {
      'th': 'ระบบจองอุปกรณ์ไอที',
      'en': 'IT Equipment Booking',
    },
    'app_subtitle': {
      'th': 'คณะวิศวกรรมศาสตร์ มหาวิทยาลัยอุบลราชธานี',
      'en': 'Faculty of Engineering, Ubon Ratchathani University',
    },

    // --- Equipment Catalog ---
    'catalog_title': {
      'th': 'ระบบจองอุปกรณ์ไอที',
      'en': 'IT Equipment Catalog',
    },
    'catalog_subtitle': {
      'th': 'เลือกอุปกรณ์และนัดหมายวัน-เวลารับ',
      'en': 'Select items and schedule pickup appointment',
    },
    'search_hint': {
      'th': 'ค้นหาอุปกรณ์ไอที (ชื่อ, รุ่น, รหัส, สถานที่)...',
      'en': 'Search equipments (name, model, location)...',
    },
    'found_items': {
      'th': 'พบ {count} รายการ',
      'en': 'Found {count} items',
    },
    'filter_available_only': {
      'th': 'เฉพาะที่พร้อมยืม',
      'en': 'Available Only',
    },
    'sort_by': {
      'th': 'เรียงลำดับ:',
      'en': 'Sort by:',
    },
    'sort_name_asc': {
      'th': 'ชื่อ ก-ฮ (Name A-Z)',
      'en': 'Name (A to Z)',
    },
    'sort_name_desc': {
      'th': 'ชื่อ ฮ-ก (Name Z-A)',
      'en': 'Name (Z to A)',
    },
    'sort_qty_desc': {
      'th': 'จำนวนพร้อมยืมมากสุด',
      'en': 'Highest Available',
    },
    'sort_newest': {
      'th': 'อุปกรณ์มาใหม่ล่าสุด',
      'en': 'Newest Items',
    },
    'cat_all': {
      'th': 'ทั้งหมด',
      'en': 'All Categories',
    },
    'cat_laptop': {
      'th': 'โน้ตบุ๊ก & PC',
      'en': 'Laptop & PC',
    },
    'cat_projector': {
      'th': 'โปรเจกเตอร์',
      'en': 'Projector',
    },
    'cat_tablet': {
      'th': 'แท็บเล็ต/iPad',
      'en': 'Tablet / iPad',
    },
    'cat_audio_video': {
      'th': 'กล้อง & ระบบเสียง',
      'en': 'Audio & Video',
    },
    'cat_accessories': {
      'th': 'อุปกรณ์เสริม',
      'en': 'Accessories',
    },
    'btn_book': {
      'th': 'จองอุปกรณ์',
      'en': 'Book Now',
    },
    'out_of_stock': {
      'th': 'ของหมด',
      'en': 'Out of Stock',
    },
    'available_count': {
      'th': 'พร้อมให้ยืม {avail}/{total} เครื่อง',
      'en': 'Available {avail}/{total} units',
    },
    'pickup_location_label': {
      'th': 'สถานที่รับ:',
      'en': 'Pickup Location:',
    },
    'pending_pickup_banner': {
      'th': 'คุณมีรายการอุปกรณ์รอนัดรับ {count} รายการ',
      'en': 'You have {count} pending equipment pickup(s)',
    },
    'check_pickup_btn': {
      'th': 'ตรวจสอบวันนัดรับ',
      'en': 'Check Schedule',
    },
    'empty_equipments': {
      'th': 'ไม่พบอุปกรณ์ตามเงื่อนไขที่ค้นหา',
      'en': 'No equipment matches the search criteria',
    },
    'empty_equipments_sub': {
      'th': 'ลองเปลี่ยนหมวดหมู่หรือคำค้นหา',
      'en': 'Try changing category or search terms',
    },

    // --- Bookings & Schedule ---
    'schedule_title': {
      'th': 'กำหนดการรับอุปกรณ์ไอที',
      'en': 'Equipment Pickup Schedule',
    },
    'schedule_subtitle': {
      'th': 'ตรวจสอบวัน-เวลานัดรับ และจัดการสถานะ',
      'en': 'Verify date & time schedule and manage status',
    },
    'search_booking_hint': {
      'th': 'ค้นหารหัสจอง, ชื่ออุปกรณ์ หรือชื่อผู้ยืม...',
      'en': 'Search booking ID, equipment, borrower...',
    },
    'tab_all': {
      'th': 'ทั้งหมด',
      'en': 'All',
    },
    'tab_pending': {
      'th': 'รอนัดรับ',
      'en': 'Awaiting Pickup',
    },
    'tab_picked_up': {
      'th': 'รับอุปกรณ์แล้ว',
      'en': 'Picked Up',
    },
    'tab_returned': {
      'th': 'คืนแล้ว',
      'en': 'Returned',
    },
    'stat_pending': {
      'th': 'รอนัดรับ',
      'en': 'To Pick Up',
    },
    'stat_picked_up': {
      'th': 'รับแล้ว',
      'en': 'Picked Up',
    },
    'stat_returned': {
      'th': 'คืนเรียบร้อย',
      'en': 'Returned',
    },
    'sort_pickup_asc': {
      'th': 'วันนัดรับเร็วสุด (Soonest)',
      'en': 'Soonest Pickup Date',
    },
    'sort_pickup_desc': {
      'th': 'วันนัดรับหลังสุด (Latest)',
      'en': 'Latest Pickup Date',
    },
    'sort_booking_newest': {
      'th': 'รายการจองล่าสุด (Newest)',
      'en': 'Newest Bookings',
    },
    'booking_id': {
      'th': 'รหัสการจอง',
      'en': 'Booking ID',
    },
    'pickup_schedule_label': {
      'th': 'นัดหมายเข้ารับ:',
      'en': 'Pickup Date & Time:',
    },
    'return_schedule_label': {
      'th': 'กำหนดคืนอุปกรณ์:',
      'en': 'Return Deadline:',
    },
    'borrower_label': {
      'th': 'ผู้ยืม:',
      'en': 'Borrower:',
    },
    'phone_label': {
      'th': 'เบอร์โทร:',
      'en': 'Phone:',
    },
    'quantity_label': {
      'th': 'จำนวน:',
      'en': 'Quantity:',
    },
    'purpose_label': {
      'th': 'วัตถุประสงค์:',
      'en': 'Purpose:',
    },
    'btn_cancel_booking': {
      'th': 'ยกเลิกการจอง',
      'en': 'Cancel Booking',
    },
    'btn_confirm_pickup': {
      'th': 'รับอุปกรณ์แล้ว',
      'en': 'Mark as Picked Up',
    },
    'btn_confirm_return': {
      'th': 'คืนอุปกรณ์แล้ว',
      'en': 'Mark as Returned',
    },
    'status_completed': {
      'th': 'ดำเนินการเสร็จสิ้นเรียบร้อยแล้ว',
      'en': 'Completed Successfully',
    },
    'empty_bookings': {
      'th': 'ยังไม่มีรายการจองตามเงื่อนไขที่เลือก',
      'en': 'No bookings match selected filters',
    },
    'empty_bookings_sub': {
      'th': 'คุณสามารถไปที่แท็บ "อุปกรณ์ไอที" เพื่อเลือกจองอุปกรณ์ได้',
      'en': 'You can visit the "IT Equipments" tab to reserve an item',
    },

    // --- Booking Dialog ---
    'dialog_booking_title': {
      'th': 'แบบฟอร์มจองอุปกรณ์ไอที',
      'en': 'Reserve IT Equipment',
    },
    'dialog_pickup_section': {
      'th': 'วันและเวลาที่นัดหมายเข้ารับอุปกรณ์',
      'en': 'Pickup Date & Time Appointment',
    },
    'dialog_pickup_date': {
      'th': 'วันที่รับ:',
      'en': 'Pickup Date:',
    },
    'dialog_return_date': {
      'th': 'กำหนดคืนอุปกรณ์:',
      'en': 'Return Date:',
    },
    'dialog_borrower_section': {
      'th': 'ข้อมูลผู้ขอยืม',
      'en': 'Borrower Information',
    },
    'dialog_fullname': {
      'th': 'ชื่อ - นามสกุล *',
      'en': 'Full Name *',
    },
    'dialog_phone': {
      'th': 'เบอร์โทรศัพท์ *',
      'en': 'Phone Number *',
    },
    'dialog_student_id': {
      'th': 'รหัสนักศึกษา/บุคลากร',
      'en': 'Student/Staff ID',
    },
    'dialog_purpose': {
      'th': 'วัตถุประสงค์การยืมใช้งาน *',
      'en': 'Borrowing Purpose *',
    },
    'dialog_quantity_label': {
      'th': 'จำนวนที่ต้องการยืม (สูงสุด {max} เครื่อง):',
      'en': 'Quantity to borrow (max {max} units):',
    },
    'btn_cancel': {
      'th': 'ยกเลิก',
      'en': 'Cancel',
    },
    'btn_confirm_booking': {
      'th': 'ยืนยันนัดหมายจอง',
      'en': 'Confirm Booking',
    },

    // --- Settings & OIDC ---
    'settings_title': {
      'th': 'ระบบยืนยันตัวตน & ตั้งค่า (OIDC & JWT)',
      'en': 'Authentication & Settings (OIDC & JWT)',
    },
    'settings_subtitle': {
      'th': 'Real OIDC Provider Architecture (Week 15)',
      'en': 'Real OIDC Provider Architecture (Week 15)',
    },
    'language_switch': {
      'th': 'เปลี่ยนภาษา / Language',
      'en': 'Language / เปลี่ยนภาษา',
    },
    'booking_overview_card': {
      'th': 'ภาพรวมรายการจอง & วันนัดรับของคุณ',
      'en': 'Your Booking & Pickup Overview',
    },
    'server_endpoint_card': {
      'th': 'Backend & OIDC Issuer Endpoint',
      'en': 'Backend & OIDC Issuer Endpoint',
    },
    'server_endpoint_sub': {
      'th': 'สลับ IP ให้ตรงกับอุปกรณ์ที่ใช้ทดสอบ:',
      'en': 'Switch IP address to match test device:',
    },
    'btn_save': {
      'th': 'บันทึก',
      'en': 'Save',
    },
    'oidc_discovery_title': {
      'th': 'OIDC Discovery (/.well-known/openid-configuration)',
      'en': 'OIDC Discovery (/.well-known/openid-configuration)',
    },
    'btn_show': {
      'th': 'แสดง',
      'en': 'Show',
    },
    'btn_hide': {
      'th': 'ซ่อน',
      'en': 'Hide',
    },
    'login_oidc_title': {
      'th': 'ล็อกอินผ่าน OIDC 1.0 Provider',
      'en': 'Log In via OIDC 1.0 Provider',
    },
    'online_status': {
      'th': 'ออนไลน์:',
      'en': 'Online:',
    },
    'test_users_title': {
      'th': 'คลิกเลือกผู้ใช้งานทดสอบในระบบ:',
      'en': 'Quick select test user account:',
    },
    'btn_login': {
      'th': 'เข้าสู่ระบบ (ขอรับ OIDC Tokens)',
      'en': 'Sign In (Obtain OIDC Tokens)',
    },
    'btn_logout': {
      'th': 'ออกจากระบบ',
      'en': 'Log Out',
    },
    'confirm_logout_title': {
      'th': 'ยืนยันออกจากระบบ',
      'en': 'Confirm Logout',
    },
    'confirm_logout_msg': {
      'th': 'คุณต้องการออกจากระบบและล้าง Token จาก Secure Storage ใช่หรือไม่?',
      'en': 'Do you want to log out and clear all tokens from Secure Storage?',
    },
    'decoded_claims_title': {
      'th': 'Decoded OIDC Claims (ข้อมูลผู้ใช้ที่ได้รับ)',
      'en': 'Decoded OIDC Claims (User Identity)',
    },
    'active_tokens_title': {
      'th': 'Active Tokens (บันทึกใน Secure Storage)',
      'en': 'Active Tokens (Stored in Secure Storage)',
    },

    // --- Login Screen ---
    'login_screen_title': {
      'th': 'เข้าสู่ระบบผ่าน OIDC Server',
      'en': 'Log In via OIDC Server',
    },
    'login_screen_sub': {
      'th': 'Authorization Code Flow (RFC 8252)',
      'en': 'Authorization Code Flow (RFC 8252)',
    },
    'login_browser_btn': {
      'th': 'เปิดหน้าล็อกอิน OIDC บนเบราว์เซอร์',
      'en': 'Open OIDC Login in Browser',
    },
    'fast_test_label': {
      'th': 'หรือทดสอบแบบรวดเร็ว',
      'en': 'Or Quick Test Login',
    },
  };

  /// แปลข้อความตาม key และภาษา
  static String translate(String key, String langCode, [Map<String, String>? params]) {
    final entry = _translations[key];
    String text = entry?[langCode] ?? entry?['th'] ?? key;
    if (params != null) {
      params.forEach((paramKey, paramVal) {
        text = text.replaceAll('{$paramKey}', paramVal);
      });
    }
    return text;
  }
}
