from django.urls import path
from .views import (
    EquipmentListView,
    EquipmentDetailView,
    BookingListView,
    BookingDetailView,
    OIDCLoginView,
)

urlpatterns = [
    path('oidc/login/', OIDCLoginView.as_view(), name='oidc-login'),
    path('equipments/', EquipmentListView.as_view(), name='equipment-list'),
    path('equipments/<int:pk>/', EquipmentDetailView.as_view(), name='equipment-detail'),
    path('bookings/', BookingListView.as_view(), name='booking-list'),
    path('bookings/<int:pk>/', BookingDetailView.as_view(), name='booking-detail'),
]