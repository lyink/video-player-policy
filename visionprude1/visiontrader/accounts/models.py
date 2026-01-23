from django.db import models
from django.contrib.auth.models import User
from django.db.models.signals import post_save
from django.dispatch import receiver


class UserProfile(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='profile')
    phone = models.CharField(max_length=20, blank=True)
    address = models.TextField(blank=True)
    avatar = models.ImageField(upload_to='avatars/', blank=True, null=True)
    bio = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"{self.user.username}'s Profile"


class SystemSettings(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='settings')

    # Database Settings
    db_engine = models.CharField(max_length=100, default='django.db.backends.sqlite3')
    db_name = models.CharField(max_length=255, default='db.sqlite3')
    db_host = models.CharField(max_length=255, blank=True)
    db_port = models.CharField(max_length=10, blank=True)
    db_user = models.CharField(max_length=100, blank=True)
    db_password = models.CharField(max_length=255, blank=True)

    # Application Settings
    theme = models.CharField(max_length=20, choices=[('light', 'Light'), ('dark', 'Dark')], default='light')
    notifications_enabled = models.BooleanField(default=True)
    email_notifications = models.BooleanField(default=True)

    # System Preferences
    language = models.CharField(max_length=10, default='en')
    timezone = models.CharField(max_length=50, default='UTC')

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name_plural = "System Settings"

    def __str__(self):
        return f"{self.user.username}'s Settings"


@receiver(post_save, sender=User)
def create_user_profile(sender, instance, created, **kwargs):
    if created:
        UserProfile.objects.create(user=instance)
        SystemSettings.objects.create(user=instance)


@receiver(post_save, sender=User)
def save_user_profile(sender, instance, **kwargs):
    if hasattr(instance, 'profile'):
        instance.profile.save()
    if hasattr(instance, 'settings'):
        instance.settings.save()


# Firebase Synced Models
class Purchase(models.Model):
    """Model for purchases from Firebase"""
    firebase_id = models.CharField(max_length=255, unique=True, help_text="Firebase document ID")
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='purchases', null=True, blank=True)
    firebase_user_id = models.CharField(max_length=255, blank=True, help_text="Firebase user ID")

    amount = models.DecimalField(max_digits=10, decimal_places=2, null=True, blank=True)
    paid = models.DecimalField(max_digits=10, decimal_places=2, null=True, blank=True)
    total_amount = models.DecimalField(max_digits=10, decimal_places=2, null=True, blank=True)

    purchase_date = models.DateTimeField(null=True, blank=True)
    status = models.CharField(max_length=50, blank=True)
    product_name = models.CharField(max_length=255, blank=True)
    description = models.TextField(blank=True)

    # Metadata
    synced_at = models.DateTimeField(auto_now=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-purchase_date']
        verbose_name = "Purchase"
        verbose_name_plural = "Purchases"

    def __str__(self):
        return f"Purchase {self.firebase_id} - {self.amount}"


class PremiumSignalPayment(models.Model):
    """Model for premium signal payments from Firebase"""
    firebase_id = models.CharField(max_length=255, unique=True, help_text="Firebase document ID")
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='premium_payments', null=True, blank=True)
    firebase_user_id = models.CharField(max_length=255, blank=True, help_text="Firebase user ID")

    amount = models.DecimalField(max_digits=10, decimal_places=2, null=True, blank=True)
    paid = models.DecimalField(max_digits=10, decimal_places=2, null=True, blank=True)
    total_amount = models.DecimalField(max_digits=10, decimal_places=2, null=True, blank=True)
    price = models.DecimalField(max_digits=10, decimal_places=2, null=True, blank=True)

    payment_date = models.DateTimeField(null=True, blank=True)
    payment_method = models.CharField(max_length=100, blank=True)
    status = models.CharField(max_length=50, blank=True)
    signal_type = models.CharField(max_length=100, blank=True)
    subscription_period = models.CharField(max_length=50, blank=True)

    # Metadata
    synced_at = models.DateTimeField(auto_now=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-payment_date']
        verbose_name = "Premium Signal Payment"
        verbose_name_plural = "Premium Signal Payments"

    def __str__(self):
        return f"Payment {self.firebase_id} - {self.amount}"


class SignalNotification(models.Model):
    """Model for signal notifications from Firebase"""
    firebase_id = models.CharField(max_length=255, unique=True, help_text="Firebase document ID")
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='signal_notifications', null=True, blank=True)
    firebase_user_id = models.CharField(max_length=255, blank=True, help_text="Firebase user ID")

    title = models.CharField(max_length=255, blank=True)
    message = models.TextField(blank=True)
    notification_type = models.CharField(max_length=100, blank=True)
    signal_data = models.JSONField(null=True, blank=True, help_text="Signal details as JSON")

    read = models.BooleanField(default=False)
    priority = models.CharField(max_length=20, blank=True)

    notification_date = models.DateTimeField(null=True, blank=True)
    read_at = models.DateTimeField(null=True, blank=True)

    # Metadata
    synced_at = models.DateTimeField(auto_now=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-notification_date']
        verbose_name = "Signal Notification"
        verbose_name_plural = "Signal Notifications"

    def __str__(self):
        return f"Notification {self.firebase_id} - {self.title}"


class UserProgress(models.Model):
    """Model for user progress/activity from Firebase"""
    firebase_id = models.CharField(max_length=255, unique=True, help_text="Firebase document ID")
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='progress', null=True, blank=True)
    firebase_user_id = models.CharField(max_length=255, blank=True, help_text="Firebase user ID")

    completed_videos = models.JSONField(null=True, blank=True, help_text="List of completed video IDs")
    video_durations = models.JSONField(null=True, blank=True, help_text="Video durations data")
    total_completed = models.IntegerField(default=0)

    progress_percentage = models.DecimalField(max_digits=5, decimal_places=2, null=True, blank=True)
    last_activity = models.DateTimeField(null=True, blank=True)

    # Metadata
    synced_at = models.DateTimeField(auto_now=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-last_activity']
        verbose_name = "User Progress"
        verbose_name_plural = "User Progress"

    def __str__(self):
        return f"Progress {self.firebase_id} - {self.total_completed} completed"


class PremiumSignal(models.Model):
    """Model for premium signals from Firebase"""
    firebase_id = models.CharField(max_length=255, unique=True, help_text="Firebase document ID")

    signal_type = models.CharField(max_length=100, blank=True)
    symbol = models.CharField(max_length=50, blank=True)
    entry_price = models.DecimalField(max_digits=15, decimal_places=8, null=True, blank=True)
    stop_loss = models.DecimalField(max_digits=15, decimal_places=8, null=True, blank=True)
    take_profit = models.DecimalField(max_digits=15, decimal_places=8, null=True, blank=True)

    title = models.CharField(max_length=255, blank=True)
    description = models.TextField(blank=True)
    status = models.CharField(max_length=50, blank=True)

    signal_date = models.DateTimeField(null=True, blank=True)
    expiry_date = models.DateTimeField(null=True, blank=True)

    # Metadata
    synced_at = models.DateTimeField(auto_now=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-signal_date']
        verbose_name = "Premium Signal"
        verbose_name_plural = "Premium Signals"

    def __str__(self):
        return f"Signal {self.firebase_id} - {self.symbol}"


class PremiumSignalSubscription(models.Model):
    """Model for premium signal subscriptions from Firebase"""
    firebase_id = models.CharField(max_length=255, unique=True, help_text="Firebase document ID")
    firebase_user_id = models.CharField(max_length=255, blank=True, help_text="Firebase user ID")

    subscription_type = models.CharField(max_length=100, blank=True)
    status = models.CharField(max_length=50, blank=True)

    start_date = models.DateTimeField(null=True, blank=True)
    end_date = models.DateTimeField(null=True, blank=True)
    auto_renew = models.BooleanField(default=False)

    price = models.DecimalField(max_digits=10, decimal_places=2, null=True, blank=True)

    # Metadata
    synced_at = models.DateTimeField(auto_now=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-start_date']
        verbose_name = "Premium Signal Subscription"
        verbose_name_plural = "Premium Signal Subscriptions"

    def __str__(self):
        return f"Subscription {self.firebase_id} - {self.subscription_type}"


class Course(models.Model):
    """Model for courses from Firebase"""
    firebase_id = models.CharField(max_length=255, unique=True, help_text="Firebase document ID")

    title = models.CharField(max_length=255, blank=True)
    description = models.TextField(blank=True)
    instructor = models.CharField(max_length=255, blank=True)

    duration = models.IntegerField(null=True, blank=True, help_text="Duration in minutes")
    level = models.CharField(max_length=50, blank=True)
    category = models.CharField(max_length=100, blank=True)

    thumbnail_url = models.URLField(max_length=500, blank=True)
    video_count = models.IntegerField(default=0)

    price = models.DecimalField(max_digits=10, decimal_places=2, null=True, blank=True)
    is_free = models.BooleanField(default=False)
    is_published = models.BooleanField(default=True)

    # Metadata
    synced_at = models.DateTimeField(auto_now=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-created_at']
        verbose_name = "Course"
        verbose_name_plural = "Courses"

    def __str__(self):
        return f"Course {self.firebase_id} - {self.title}"


class FCMToken(models.Model):
    """Model for FCM tokens from Firebase"""
    firebase_id = models.CharField(max_length=255, unique=True, help_text="Firebase document ID (token)")
    firebase_user_id = models.CharField(max_length=255, blank=True, help_text="Firebase user ID")

    token = models.TextField(help_text="FCM device token")
    platform = models.CharField(max_length=50, blank=True)
    device_info = models.TextField(blank=True)

    is_active = models.BooleanField(default=True)
    last_used = models.DateTimeField(null=True, blank=True)

    # Metadata
    synced_at = models.DateTimeField(auto_now=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-last_used']
        verbose_name = "FCM Token"
        verbose_name_plural = "FCM Tokens"

    def __str__(self):
        return f"Token {self.firebase_id[:20]}..."


class AppNotification(models.Model):
    """Model for app notifications from Firebase"""
    firebase_id = models.CharField(max_length=255, unique=True, help_text="Firebase document ID")

    title = models.CharField(max_length=255, blank=True)
    message = models.TextField(blank=True)
    notification_type = models.CharField(max_length=100, blank=True)

    target_audience = models.CharField(max_length=100, blank=True, help_text="all, premium, free, etc.")
    priority = models.CharField(max_length=20, blank=True)

    scheduled_date = models.DateTimeField(null=True, blank=True)
    sent_date = models.DateTimeField(null=True, blank=True)

    is_sent = models.BooleanField(default=False)

    # Metadata
    synced_at = models.DateTimeField(auto_now=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-created_at']
        verbose_name = "App Notification"
        verbose_name_plural = "App Notifications"

    def __str__(self):
        return f"Notification {self.firebase_id} - {self.title}"


class Testimonial(models.Model):
    """Model for testimonials from Firebase"""
    firebase_id = models.CharField(max_length=255, unique=True, help_text="Firebase document ID")
    firebase_user_id = models.CharField(max_length=255, blank=True, help_text="Firebase user ID")

    author_name = models.CharField(max_length=255, blank=True)
    author_email = models.EmailField(blank=True)
    author_avatar = models.URLField(max_length=500, blank=True)

    content = models.TextField(blank=True)
    rating = models.IntegerField(null=True, blank=True)

    is_approved = models.BooleanField(default=False)
    is_featured = models.BooleanField(default=False)

    # Metadata
    synced_at = models.DateTimeField(auto_now=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-created_at']
        verbose_name = "Testimonial"
        verbose_name_plural = "Testimonials"

    def __str__(self):
        return f"Testimonial by {self.author_name}"


class FirebaseUser(models.Model):
    """Model for Firebase users"""
    firebase_id = models.CharField(max_length=255, unique=True, help_text="Firebase user ID")

    email = models.EmailField(blank=True)
    display_name = models.CharField(max_length=255, blank=True)
    phone_number = models.CharField(max_length=20, blank=True)

    photo_url = models.URLField(max_length=500, blank=True)

    is_premium = models.BooleanField(default=False)
    is_active = models.BooleanField(default=True)

    last_login = models.DateTimeField(null=True, blank=True)
    account_created = models.DateTimeField(null=True, blank=True)

    # Metadata
    synced_at = models.DateTimeField(auto_now=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-created_at']
        verbose_name = "Firebase User"
        verbose_name_plural = "Firebase Users"

    def __str__(self):
        return f"User {self.email or self.firebase_id}"
