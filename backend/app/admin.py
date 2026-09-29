from django.contrib import admin
from .models import Equipment, Booking

@admin.register(Equipment)
class EquipmentAdmin(admin.ModelAdmin):
    list_display = ('name', 'category', 'available_quantity', 'total_quantity', 'pickup_location')
    list_filter = ('category',)
    search_fields = ('name', 'model_number', 'pickup_location')

@admin.register(Booking)
class BookingAdmin(admin.ModelAdmin):
    list_display = ('id', 'borrower_name', 'equipment', 'pickup_date', 'pickup_time', 'return_date', 'status')
    list_filter = ('status', 'pickup_date', 'return_date')
    search_fields = ('borrower_name', 'borrower_student_id', 'equipment__name')
