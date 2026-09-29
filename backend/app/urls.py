from django.urls import path
from .views import (
    EquipmentListView,
    EquipmentDetailView,
    BookingListView,
    BookingDetailView,
)

urlpatterns = [
    path('equipments/', EquipmentListView.as_view(), name='equipment-list'),
    path('equipments/<int:pk>/', EquipmentDetailView.as_view(), name='equipment-detail'),
    path('bookings/', BookingListView.as_view(), name='booking-list'),
    path('bookings/<int:pk>/', BookingDetailView.as_view(), name='booking-detail'),
]