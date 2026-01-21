from django.contrib import admin
from .models import (
    UserProfile, SystemSettings,
    Purchase, PremiumSignalPayment, SignalNotification, UserProgress
)


@admin.register(UserProfile)
class UserProfileAdmin(admin.ModelAdmin):
    list_display = ('user', 'phone', 'created_at', 'updated_at')
    search_fields = ('user__username', 'user__email', 'phone')
    list_filter = ('created_at',)


@admin.register(SystemSettings)
class SystemSettingsAdmin(admin.ModelAdmin):
    list_display = ('user', 'db_engine', 'theme', 'language', 'timezone')
    search_fields = ('user__username',)
    list_filter = ('theme', 'language')


@admin.register(Purchase)
class PurchaseAdmin(admin.ModelAdmin):
    list_display = ('firebase_id', 'firebase_user_id', 'amount', 'paid', 'status', 'purchase_date', 'synced_at')
    search_fields = ('firebase_id', 'firebase_user_id', 'product_name')
    list_filter = ('status', 'purchase_date', 'synced_at')
    readonly_fields = ('firebase_id', 'synced_at', 'created_at')
    ordering = ('-purchase_date',)


@admin.register(PremiumSignalPayment)
class PremiumSignalPaymentAdmin(admin.ModelAdmin):
    list_display = ('firebase_id', 'firebase_user_id', 'amount', 'status', 'signal_type', 'payment_date', 'synced_at')
    search_fields = ('firebase_id', 'firebase_user_id', 'signal_type')
    list_filter = ('status', 'signal_type', 'payment_date', 'synced_at')
    readonly_fields = ('firebase_id', 'synced_at', 'created_at')
    ordering = ('-payment_date',)


@admin.register(SignalNotification)
class SignalNotificationAdmin(admin.ModelAdmin):
    list_display = ('firebase_id', 'firebase_user_id', 'title', 'notification_type', 'read', 'priority', 'notification_date')
    search_fields = ('firebase_id', 'firebase_user_id', 'title', 'message')
    list_filter = ('read', 'notification_type', 'priority', 'notification_date', 'synced_at')
    readonly_fields = ('firebase_id', 'synced_at', 'created_at')
    ordering = ('-notification_date',)


@admin.register(UserProgress)
class UserProgressAdmin(admin.ModelAdmin):
    list_display = ('firebase_id', 'firebase_user_id', 'total_completed', 'progress_percentage', 'last_activity', 'synced_at')
    search_fields = ('firebase_id', 'firebase_user_id')
    list_filter = ('last_activity', 'synced_at')
    readonly_fields = ('firebase_id', 'synced_at', 'created_at')
    ordering = ('-last_activity',)
