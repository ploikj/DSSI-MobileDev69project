from rest_framework import serializers
from django.contrib.auth.models import User
from rest_framework_simplejwt.serializers import TokenObtainPairSerializer
from .models import Equipment, Booking

class EquipmentSerializer(serializers.ModelSerializer):
    category_display = serializers.CharField(source='get_category_display', read_only=True)
    
    class Meta:
        model = Equipment
        fields = [
            'id', 'name', 'category', 'category_display', 
            'model_number', 'description', 'image_url', 
            'total_quantity', 'available_quantity', 
            'pickup_location', 'created_at'
        ]

class BookingSerializer(serializers.ModelSerializer):
    equipment_detail = EquipmentSerializer(source='equipment', read_only=True)
    equipment_id = serializers.PrimaryKeyRelatedField(
        queryset=Equipment.objects.all(), 
        source='equipment', 
        write_only=True
    )
    status_display = serializers.CharField(source='get_status_display', read_only=True)

    class Meta:
        model = Booking
        fields = [
            'id', 'user', 'borrower_name', 'borrower_phone', 
            'borrower_student_id', 'borrower_email',
            'equipment', 'equipment_id', 'equipment_detail',
            'quantity', 'pickup_date', 'pickup_time', 'return_date',
            'purpose', 'status', 'status_display', 'note', 'created_at'
        ]
        read_only_fields = ['id', 'equipment', 'created_at', 'status_display']

    def create(self, validated_data):
        booking = super().create(validated_data)
        eq = booking.equipment
        if eq.available_quantity >= booking.quantity:
            eq.available_quantity -= booking.quantity
            eq.save()
        return booking

class MyTokenObtainPairSerializer(TokenObtainPairSerializer):
    @classmethod
    def get_token(cls, user):
        token = super().get_token(user)
        token['name'] = user.username
        return token