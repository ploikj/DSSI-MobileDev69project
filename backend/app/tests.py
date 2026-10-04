from django.test import TestCase
from django.contrib.auth.models import User
from rest_framework.test import APIClient
from rest_framework import status
from .models import Equipment, Booking
import datetime

class BookingPermissionTests(TestCase):
    def setUp(self):
        self.client = APIClient()
        
        # Create users
        self.admin_user = User.objects.create_superuser(
            username='admin',
            email='admin@ubu.ac.th',
            password='password123',
            is_staff=True
        )
        self.owner_user = User.objects.create_user(
            username='owner_user',
            first_name='Owner',
            email='owner@ubu.ac.th',
            password='password123'
        )
        self.other_user = User.objects.create_user(
            username='other_user',
            first_name='Other',
            email='other@ubu.ac.th',
            password='password123'
        )
        
        # Create equipment
        self.equipment = Equipment.objects.create(
            name='Test Laptop',
            category='laptop',
            total_quantity=5,
            available_quantity=5
        )
        
        # Create booking for owner
        self.booking = Booking.objects.create(
            user=self.owner_user,
            borrower_name='Owner Test',
            borrower_phone='0812345678',
            borrower_email='owner@ubu.ac.th',
            borrower_student_id='65000001',
            equipment=self.equipment,
            quantity=1,
            pickup_date=datetime.date.today(),
            pickup_time=datetime.time(10, 0),
            return_date=datetime.date.today() + datetime.timedelta(days=2),
            status='PENDING'
        )

    def test_anonymous_cannot_cancel_or_return(self):
        # Anonymous try to cancel
        res = self.client.patch(f'/api/bookings/{self.booking.id}/', {'status': 'CANCELLED'}, format='json')
        self.assertEqual(res.status_code, status.HTTP_401_UNAUTHORIZED)
        
        # Anonymous try to return
        res = self.client.patch(f'/api/bookings/{self.booking.id}/', {'status': 'RETURNED'}, format='json')
        self.assertEqual(res.status_code, status.HTTP_401_UNAUTHORIZED)

    def test_other_user_cannot_cancel_or_return(self):
        self.client.force_authenticate(user=self.other_user)
        
        # Other user tries to cancel
        res = self.client.patch(f'/api/bookings/{self.booking.id}/', {'status': 'CANCELLED'}, format='json')
        self.assertEqual(res.status_code, status.HTTP_403_FORBIDDEN)
        self.assertIn('ต้องเป็นเจ้าตัวเท่านั้น', res.data['error'])
        
        # Other user tries to return
        self.booking.status = 'PICKED_UP'
        self.booking.save()
        res = self.client.patch(f'/api/bookings/{self.booking.id}/', {'status': 'RETURNED'}, format='json')
        self.assertEqual(res.status_code, status.HTTP_403_FORBIDDEN)
        self.assertIn('ต้องเป็นเจ้าตัวเท่านั้น', res.data['error'])

    def test_owner_can_cancel_and_return(self):
        self.client.force_authenticate(user=self.owner_user)
        
        # Owner cancels
        res = self.client.patch(f'/api/bookings/{self.booking.id}/', {'status': 'CANCELLED'}, format='json')
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.booking.refresh_from_db()
        self.assertEqual(self.booking.status, 'CANCELLED')
        
        # Owner returns
        self.booking.status = 'PICKED_UP'
        self.booking.save()
        res = self.client.patch(f'/api/bookings/{self.booking.id}/', {'status': 'RETURNED'}, format='json')
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.booking.refresh_from_db()
        self.assertEqual(self.booking.status, 'RETURNED')

    def test_admin_can_cancel_and_return_any_booking(self):
        self.client.force_authenticate(user=self.admin_user)
        
        # Admin cancels
        res = self.client.patch(f'/api/bookings/{self.booking.id}/', {'status': 'CANCELLED'}, format='json')
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.booking.refresh_from_db()
        self.assertEqual(self.booking.status, 'CANCELLED')
        
        # Admin returns
        self.booking.status = 'PICKED_UP'
        self.booking.save()
        res = self.client.patch(f'/api/bookings/{self.booking.id}/', {'status': 'RETURNED'}, format='json')
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.booking.refresh_from_db()
        self.assertEqual(self.booking.status, 'RETURNED')
