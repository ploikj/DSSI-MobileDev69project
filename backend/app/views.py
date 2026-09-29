from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from .models import Equipment, Booking
from .serializers import EquipmentSerializer, BookingSerializer

class EquipmentListView(APIView):
    def get(self, request):
        category = request.query_params.get('category')
        search = request.query_params.get('search')
        
        queryset = Equipment.objects.all()
        if category and category != 'all':
            queryset = queryset.filter(category=category)
        if search:
            queryset = queryset.filter(name__icontains=search)
            
        serializer = EquipmentSerializer(queryset, many=True)
        return Response(serializer.data)

class EquipmentDetailView(APIView):
    def get(self, request, pk):
        try:
            eq = Equipment.objects.get(pk=pk)
            return Response(EquipmentSerializer(eq).data)
        except Equipment.DoesNotExist:
            return Response({'error': 'Equipment not found'}, status=status.HTTP_404_NOT_FOUND)

class BookingListView(APIView):
    def get(self, request):
        status_param = request.query_params.get('status')
        search = request.query_params.get('search')
        queryset = Booking.objects.all().select_related('equipment')
        if status_param and status_param != 'ALL':
            queryset = queryset.filter(status=status_param)
        if search:
            queryset = queryset.filter(borrower_name__icontains=search)
        serializer = BookingSerializer(queryset, many=True)
        return Response(serializer.data)

    def post(self, request):
        serializer = BookingSerializer(data=request.data)
        if serializer.is_valid():
            booking = serializer.save()
            return Response(BookingSerializer(booking).data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

class BookingDetailView(APIView):
    def get(self, request, pk):
        try:
            booking = Booking.objects.select_related('equipment').get(pk=pk)
            return Response(BookingSerializer(booking).data)
        except Booking.DoesNotExist:
            return Response({'error': 'Booking not found'}, status=status.HTTP_404_NOT_FOUND)

    def patch(self, request, pk):
        try:
            booking = Booking.objects.select_related('equipment').get(pk=pk)
            new_status = request.data.get('status')
            if new_status:
                old_status = booking.status
                booking.status = new_status
                # คืน stock ถ้ามีการยกเลิกหรือคืนอุปกรณ์
                if new_status in ['RETURNED', 'CANCELLED'] and old_status not in ['RETURNED', 'CANCELLED']:
                    booking.equipment.available_quantity += booking.quantity
                    booking.equipment.save()
                elif old_status in ['RETURNED', 'CANCELLED'] and new_status not in ['RETURNED', 'CANCELLED']:
                    if booking.equipment.available_quantity >= booking.quantity:
                        booking.equipment.available_quantity -= booking.quantity
                        booking.equipment.save()
                booking.save()
            return Response(BookingSerializer(booking).data)
        except Booking.DoesNotExist:
            return Response({'error': 'Booking not found'}, status=status.HTTP_404_NOT_FOUND)

    def delete(self, request, pk):
        try:
            booking = Booking.objects.select_related('equipment').get(pk=pk)
            if booking.status not in ['RETURNED', 'CANCELLED']:
                booking.equipment.available_quantity += booking.quantity
                booking.equipment.save()
            booking.delete()
            return Response({'message': 'Booking deleted successfully'}, status=status.HTTP_204_NO_CONTENT)
        except Booking.DoesNotExist:
            return Response({'error': 'Booking not found'}, status=status.HTTP_404_NOT_FOUND)
