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
    user_id = serializers.IntegerField(source='user.id', read_only=True, default=None)
    username = serializers.CharField(source='user.username', read_only=True, default='')
    can_manage = serializers.SerializerMethodField()

    class Meta:
        model = Booking
        fields = [
            'id', 'user', 'user_id', 'username', 'can_manage',
            'borrower_name', 'borrower_phone', 
            'borrower_student_id', 'borrower_email',
            'equipment', 'equipment_id', 'equipment_detail',
            'quantity', 'pickup_date', 'pickup_time', 'return_date',
            'purpose', 'status', 'status_display', 'note', 'created_at'
        ]
        read_only_fields = ['id', 'user', 'user_id', 'username', 'can_manage', 'equipment', 'created_at', 'status_display']

    def get_can_manage(self, obj):
        request = self.context.get('request')
        if not request or not getattr(request, 'user', None) or not request.user.is_authenticated:
            return False
        user = request.user
        if user.is_staff or user.is_superuser or user.username.lower() == 'admin':
            return True
        if obj.user_id and obj.user_id == user.id:
            return True
        if obj.borrower_email and user.email and obj.borrower_email.strip().lower() == user.email.strip().lower():
            return True
        if obj.borrower_student_id and obj.borrower_student_id.strip().lower() == user.username.strip().lower():
            return True
        if obj.borrower_name:
            b_name = obj.borrower_name.strip().lower()
            if b_name == user.username.strip().lower():
                return True
            if user.first_name and user.first_name.strip().lower() in b_name:
                return True
        return False

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