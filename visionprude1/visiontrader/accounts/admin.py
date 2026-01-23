from django.contrib import admin
from .models import (
    UserProfile, SystemSettings,
    Purchase, PremiumSignalPayment, SignalNotification, UserProgress,
    PremiumSignal, PremiumSignalSubscription, Course, FCMToken,
    AppNotification, Testimonial, FirebaseUser
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


@admin.register(PremiumSignal)
class PremiumSignalAdmin(admin.ModelAdmin):
    list_display = ('firebase_id', 'symbol', 'signal_type', 'entry_price', 'status', 'signal_date', 'synced_at')
    search_fields = ('firebase_id', 'symbol', 'title')
    list_filter = ('signal_type', 'status', 'signal_date', 'synced_at')
    readonly_fields = ('firebase_id', 'synced_at', 'created_at')
    ordering = ('-signal_date',)


@admin.register(PremiumSignalSubscription)
class PremiumSignalSubscriptionAdmin(admin.ModelAdmin):
    list_display = ('firebase_id', 'firebase_user_id', 'subscription_type', 'status', 'start_date', 'end_date', 'synced_at')
    search_fields = ('firebase_id', 'firebase_user_id')
    list_filter = ('subscription_type', 'status', 'auto_renew', 'synced_at')
    readonly_fields = ('firebase_id', 'synced_at', 'created_at')
    ordering = ('-start_date',)


@admin.register(Course)
class CourseAdmin(admin.ModelAdmin):
    list_display = ('firebase_id', 'title', 'instructor', 'level', 'category', 'video_count', 'is_published', 'synced_at')
    search_fields = ('firebase_id', 'title', 'instructor')
    list_filter = ('level', 'category', 'is_free', 'is_published', 'synced_at')
    readonly_fields = ('firebase_id', 'synced_at', 'created_at')
    ordering = ('-created_at',)


@admin.register(FCMToken)
class FCMTokenAdmin(admin.ModelAdmin):
    list_display = ('firebase_id', 'firebase_user_id', 'platform', 'is_active', 'last_used', 'synced_at')
    search_fields = ('firebase_id', 'firebase_user_id', 'token')
    list_filter = ('platform', 'is_active', 'synced_at')
    readonly_fields = ('firebase_id', 'synced_at', 'created_at')
    ordering = ('-last_used',)


@admin.register(AppNotification)
class AppNotificationAdmin(admin.ModelAdmin):
    list_display = ('firebase_id', 'title', 'notification_type', 'target_audience', 'priority', 'is_sent', 'synced_at')
    search_fields = ('firebase_id', 'title', 'message')
    list_filter = ('notification_type', 'target_audience', 'priority', 'is_sent', 'synced_at')
    readonly_fields = ('firebase_id', 'synced_at', 'created_at')
    ordering = ('-created_at',)


@admin.register(Testimonial)
class TestimonialAdmin(admin.ModelAdmin):
    list_display = ('firebase_id', 'author_name', 'author_email', 'rating', 'is_approved', 'is_featured', 'synced_at')
    search_fields = ('firebase_id', 'author_name', 'author_email', 'content')
    list_filter = ('rating', 'is_approved', 'is_featured', 'synced_at')
    readonly_fields = ('firebase_id', 'synced_at', 'created_at')
    ordering = ('-created_at',)


@admin.register(FirebaseUser)
class FirebaseUserAdmin(admin.ModelAdmin):
    list_display = ('firebase_id', 'email', 'display_name', 'is_premium', 'is_active', 'last_login', 'synced_at')
    search_fields = ('firebase_id', 'email', 'display_name', 'phone_number')
    list_filter = ('is_premium', 'is_active', 'synced_at')
    readonly_fields = ('firebase_id', 'synced_at', 'created_at')
    ordering = ('-created_at',)
