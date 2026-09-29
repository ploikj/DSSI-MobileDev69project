from django.core.management.base import BaseCommand
from app.models import Equipment, Booking
from datetime import date, time, timedelta

class Command(BaseCommand):
    help = 'Seed initial IT equipment and sample bookings'

    def handle(self, *args, **kwargs):
        self.stdout.write('Seeding IT equipment data...')
        
        equipments_data = [
            {
                'name': 'Dell Latitude 5420 (Core i7 / RAM 16GB)',
                'category': 'laptop',
                'model_number': 'UBU-IT-NB-001',
                'description': 'โน้ตบุ๊กประสิทธิภาพสูง สำหรับงานเขียนโปรแกรม ออกแบบ และตัดต่อ พร้อมสายชาร์จและกระเป๋า',
                'image_url': 'https://images.unsplash.com/photo-1588872657578-7efd1f1555ed?w=800&auto=format&fit=crop&q=80',
                'total_quantity': 6,
                'available_quantity': 5,
                'pickup_location': 'ห้องบริการไอที อาคาร EN2 ชั้น 1'
            },
            {
                'name': 'Apple MacBook Air M2 (13-inch)',
                'category': 'laptop',
                'model_number': 'UBU-IT-MBA-002',
                'description': 'สำหรับพัฒนา iOS App, Flutter และงานมัลติมีเดีย ชิป M2 แบตเตอรี่ใช้งานได้ยาวนาน',
                'image_url': 'https://images.unsplash.com/photo-1517336714731-489689fd1ca8?w=800&auto=format&fit=crop&q=80',
                'total_quantity': 4,
                'available_quantity': 3,
                'pickup_location': 'ห้องบริการไอที อาคาร EN2 ชั้น 1'
            },
            {
                'name': 'Epson EB-X51 Projector (3,800 Lumens)',
                'category': 'projector',
                'model_number': 'UBU-AV-PRJ-010',
                'description': 'โปรเจกเตอร์ความสว่างสูง 3,800 lumens เหมาะสำหรับนำเสนองานในห้องสัมมนาหรือห้องเรียน พร้อมรีโมทและสาย HDMI',
                'image_url': 'https://images.unsplash.com/photo-1517604931442-7e0c8ed2963c?w=800&auto=format&fit=crop&q=80',
                'total_quantity': 3,
                'available_quantity': 2,
                'pickup_location': 'เคาน์เตอร์ยืม-คืน อาคารเรียนรวม ชั้น 2'
            },
            {
                'name': 'Apple iPad Air (Gen 5) + Apple Pencil 2',
                'category': 'tablet',
                'model_number': 'UBU-IT-IPD-005',
                'description': 'ไอแพดพร้อมปากกา สำหรับจดบันทึก ออกแบบ UI/UX และทดสอบ Mobile Application',
                'image_url': 'https://images.unsplash.com/photo-1544244015-0df4b3ffc6b0?w=800&auto=format&fit=crop&q=80',
                'total_quantity': 5,
                'available_quantity': 4,
                'pickup_location': 'ห้องบริการไอที อาคาร EN2 ชั้น 1'
            },
            {
                'name': 'Sony Alpha A6400 Mirrorless Camera + Lens',
                'category': 'audio_video',
                'model_number': 'UBU-CAM-SNY-007',
                'description': 'กล้อง Mirrorless 4K พร้อมเลนส์ 16-50mm ขาตั้งกล้อง และไมโครโฟนไร้สาย สำหรับบันทึกวิดีโองานกิจกรรม',
                'image_url': 'https://images.unsplash.com/photo-1516035069371-29a1b244cc32?w=800&auto=format&fit=crop&q=80',
                'total_quantity': 3,
                'available_quantity': 3,
                'pickup_location': 'ศูนย์ผลิตสื่อและนวัตกรรม ชั้น 3'
            },
            {
                'name': 'ชุดหัวแปลง USB-C Multiport Hub & HDMI Adapter',
                'category': 'accessories',
                'model_number': 'UBU-ACC-HUB-015',
                'description': 'อะแดปเตอร์แปลงพอร์ต USB-C เป็น HDMI, USB 3.0, LAN และ SD Card รองรับการต่อออกจอภาพทุกรุ่น',
                'image_url': 'https://images.unsplash.com/photo-1622445262464-84b1456045b6?w=800&auto=format&fit=crop&q=80',
                'total_quantity': 10,
                'available_quantity': 10,
                'pickup_location': 'ห้องบริการไอที อาคาร EN2 ชั้น 1'
            }
        ]

        created_equipments = []
        for eq_data in equipments_data:
            eq, created = Equipment.objects.update_or_create(
                model_number=eq_data['model_number'],
                defaults=eq_data
            )
            created_equipments.append(eq)
            action = 'Created' if created else 'Updated'
            self.stdout.write(f'{action}: {eq.name}')

        # Create a sample booking
        if created_equipments and not Booking.objects.exists():
            today = date.today()
            pickup = today + timedelta(days=1)
            ret = today + timedelta(days=3)
            
            b = Booking.objects.create(
                borrower_name='ณราธิป รักเรียน',
                borrower_phone='081-234-5678',
                borrower_student_id='65140001',
                borrower_email='narathip@ubu.ac.th',
                equipment=created_equipments[0],
                quantity=1,
                pickup_date=pickup,
                pickup_time=time(9, 30),
                return_date=ret,
                purpose='ใช้ในการนำเสนอโครงงานวิชา Mobile App Development 2569',
                status='PENDING',
                note='ต้องการนำเสนองานกลุ่ม คาบเช้า'
            )
            self.stdout.write(f'Sample booking created: #{b.id}')

        self.stdout.write(self.style.SUCCESS('Successfully seeded IT equipment data!'))
