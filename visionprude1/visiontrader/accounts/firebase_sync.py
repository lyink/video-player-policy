"""
Firebase to MySQL Sync Service
Handles syncing data from Firebase Firestore to local MySQL database
"""
from datetime import datetime
from django.utils import timezone
from django.db import transaction
from .models import (
    Purchase, PremiumSignalPayment, SignalNotification, UserProgress,
    PremiumSignal, PremiumSignalSubscription, Course, FCMToken,
    AppNotification, Testimonial, FirebaseUser
)
from .firebase_service import FirebaseService


class FirebaseSyncService:
    """Service to sync Firebase data to MySQL database"""

    @staticmethod
    def parse_date(date_value):
        """Parse various date formats to datetime object"""
        if not date_value:
            return None

        if isinstance(date_value, datetime):
            return timezone.make_aware(date_value) if timezone.is_naive(date_value) else date_value

        if isinstance(date_value, str):
            try:
                # Try parsing ISO format
                dt = datetime.fromisoformat(date_value.replace('Z', '+00:00'))
                return timezone.make_aware(dt) if timezone.is_naive(dt) else dt
            except (ValueError, AttributeError):
                return None

        return None

    @staticmethod
    def parse_decimal(value):
        """Safely parse decimal values"""
        if value is None or value == '':
            return None
        try:
            return float(value)
        except (ValueError, TypeError):
            return None

    @classmethod
    def sync_purchases(cls, collection_name='purchases'):
        """
        Sync purchases from Firebase to MySQL

        Returns:
            dict: Statistics about the sync operation
        """
        stats = {'created': 0, 'updated': 0, 'errors': 0, 'total': 0}

        try:
            # Fetch data from Firebase
            firebase_data = FirebaseService.get_collection(collection_name, use_cache=False)
            stats['total'] = len(firebase_data)

            for doc in firebase_data:
                try:
                    with transaction.atomic():
                        firebase_id = doc.get('id')
                        if not firebase_id:
                            stats['errors'] += 1
                            continue

                        # Get or create purchase
                        purchase, created = Purchase.objects.update_or_create(
                            firebase_id=firebase_id,
                            defaults={
                                'firebase_user_id': doc.get('userId') or doc.get('uid') or doc.get('user_id', ''),
                                'amount': cls.parse_decimal(doc.get('amount')),
                                'paid': cls.parse_decimal(doc.get('paid')),
                                'total_amount': cls.parse_decimal(doc.get('total_amount') or doc.get('totalAmount')),
                                'purchase_date': cls.parse_date(doc.get('purchase_date') or doc.get('date') or doc.get('created_at')),
                                'status': doc.get('status', ''),
                                'product_name': doc.get('product_name') or doc.get('productName', ''),
                                'description': doc.get('description', ''),
                            }
                        )

                        if created:
                            stats['created'] += 1
                        else:
                            stats['updated'] += 1

                except Exception as e:
                    print(f"Error syncing purchase {doc.get('id')}: {e}")
                    stats['errors'] += 1

        except Exception as e:
            print(f"Error fetching purchases from Firebase: {e}")

        return stats

    @classmethod
    def sync_premium_payments(cls, collection_name='premium_signals_payments'):
        """
        Sync premium signal payments from Firebase to MySQL

        Returns:
            dict: Statistics about the sync operation
        """
        stats = {'created': 0, 'updated': 0, 'errors': 0, 'total': 0}

        try:
            firebase_data = FirebaseService.get_collection(collection_name, use_cache=False)
            stats['total'] = len(firebase_data)

            for doc in firebase_data:
                try:
                    with transaction.atomic():
                        firebase_id = doc.get('id')
                        if not firebase_id:
                            stats['errors'] += 1
                            continue

                        payment, created = PremiumSignalPayment.objects.update_or_create(
                            firebase_id=firebase_id,
                            defaults={
                                'firebase_user_id': doc.get('userId') or doc.get('uid') or doc.get('user_id', ''),
                                'amount': cls.parse_decimal(doc.get('amount')),
                                'paid': cls.parse_decimal(doc.get('paid')),
                                'total_amount': cls.parse_decimal(doc.get('total_amount') or doc.get('totalAmount')),
                                'price': cls.parse_decimal(doc.get('price')),
                                'payment_date': cls.parse_date(doc.get('payment_date') or doc.get('date') or doc.get('created_at')),
                                'payment_method': doc.get('payment_method') or doc.get('paymentMethod', ''),
                                'status': doc.get('status', ''),
                                'signal_type': doc.get('signal_type') or doc.get('signalType', ''),
                                'subscription_period': doc.get('subscription_period') or doc.get('subscriptionPeriod', ''),
                            }
                        )

                        if created:
                            stats['created'] += 1
                        else:
                            stats['updated'] += 1

                except Exception as e:
                    print(f"Error syncing payment {doc.get('id')}: {e}")
                    stats['errors'] += 1

        except Exception as e:
            print(f"Error fetching premium payments from Firebase: {e}")

        return stats

    @classmethod
    def sync_signal_notifications(cls, collection_name='signal_notifications'):
        """
        Sync signal notifications from Firebase to MySQL

        Returns:
            dict: Statistics about the sync operation
        """
        stats = {'created': 0, 'updated': 0, 'errors': 0, 'total': 0}

        try:
            firebase_data = FirebaseService.get_collection(collection_name, use_cache=False, limit=500)
            stats['total'] = len(firebase_data)

            for doc in firebase_data:
                try:
                    with transaction.atomic():
                        firebase_id = doc.get('id')
                        if not firebase_id:
                            stats['errors'] += 1
                            continue

                        notification, created = SignalNotification.objects.update_or_create(
                            firebase_id=firebase_id,
                            defaults={
                                'firebase_user_id': doc.get('userId') or doc.get('uid') or doc.get('user_id', ''),
                                'title': doc.get('title', ''),
                                'message': doc.get('message', ''),
                                'notification_type': doc.get('type') or doc.get('notification_type', ''),
                                'signal_data': doc.get('signal_data') or doc.get('signalData'),
                                'read': doc.get('read', False),
                                'priority': doc.get('priority', ''),
                                'notification_date': cls.parse_date(doc.get('notification_date') or doc.get('date') or doc.get('created_at')),
                                'read_at': cls.parse_date(doc.get('read_at') or doc.get('readAt')),
                            }
                        )

                        if created:
                            stats['created'] += 1
                        else:
                            stats['updated'] += 1

                except Exception as e:
                    print(f"Error syncing notification {doc.get('id')}: {e}")
                    stats['errors'] += 1

        except Exception as e:
            print(f"Error fetching notifications from Firebase: {e}")

        return stats

    @classmethod
    def sync_user_progress(cls, collection_name='user_progress'):
        """
        Sync user progress from Firebase to MySQL

        Returns:
            dict: Statistics about the sync operation
        """
        stats = {'created': 0, 'updated': 0, 'errors': 0, 'total': 0}

        try:
            firebase_data = FirebaseService.get_collection(collection_name, use_cache=False)
            stats['total'] = len(firebase_data)

            for doc in firebase_data:
                try:
                    with transaction.atomic():
                        firebase_id = doc.get('id')
                        if not firebase_id:
                            stats['errors'] += 1
                            continue

                        completed_videos = doc.get('completed_videos') or doc.get('completedVideos')
                        total_completed = len(completed_videos) if isinstance(completed_videos, list) else doc.get('total_completed', 0)

                        progress, created = UserProgress.objects.update_or_create(
                            firebase_id=firebase_id,
                            defaults={
                                'firebase_user_id': doc.get('userId') or doc.get('uid') or doc.get('user_id', ''),
                                'completed_videos': completed_videos,
                                'video_durations': doc.get('video_durations') or doc.get('videoDurations'),
                                'total_completed': total_completed,
                                'progress_percentage': cls.parse_decimal(doc.get('progress_percentage') or doc.get('progressPercentage')),
                                'last_activity': cls.parse_date(doc.get('last_activity') or doc.get('lastActivity') or doc.get('updated_at')),
                            }
                        )

                        if created:
                            stats['created'] += 1
                        else:
                            stats['updated'] += 1

                except Exception as e:
                    print(f"Error syncing progress {doc.get('id')}: {e}")
                    stats['errors'] += 1

        except Exception as e:
            print(f"Error fetching user progress from Firebase: {e}")

        return stats

    @classmethod
    def sync_premium_signals(cls, collection_name='premium_signals'):
        """Sync premium signals from Firebase to MySQL"""
        stats = {'created': 0, 'updated': 0, 'errors': 0, 'total': 0}

        try:
            firebase_data = FirebaseService.get_collection(collection_name, use_cache=False)
            stats['total'] = len(firebase_data)

            for doc in firebase_data:
                try:
                    with transaction.atomic():
                        firebase_id = doc.get('id')
                        if not firebase_id:
                            stats['errors'] += 1
                            continue

                        signal, created = PremiumSignal.objects.update_or_create(
                            firebase_id=firebase_id,
                            defaults={
                                'signal_type': doc.get('type') or doc.get('signal_type', ''),
                                'symbol': doc.get('symbol', ''),
                                'entry_price': cls.parse_decimal(doc.get('entry_price') or doc.get('entryPrice')),
                                'stop_loss': cls.parse_decimal(doc.get('stop_loss') or doc.get('stopLoss')),
                                'take_profit': cls.parse_decimal(doc.get('take_profit') or doc.get('takeProfit')),
                                'title': doc.get('title', ''),
                                'description': doc.get('description', ''),
                                'status': doc.get('status', ''),
                                'signal_date': cls.parse_date(doc.get('signal_date') or doc.get('date') or doc.get('created_at')),
                                'expiry_date': cls.parse_date(doc.get('expiry_date') or doc.get('expiryDate')),
                            }
                        )

                        if created:
                            stats['created'] += 1
                        else:
                            stats['updated'] += 1

                except Exception as e:
                    print(f"Error syncing signal {doc.get('id')}: {e}")
                    stats['errors'] += 1

        except Exception as e:
            print(f"Error fetching premium signals from Firebase: {e}")

        return stats

    @classmethod
    def sync_premium_signal_subscriptions(cls, collection_name='premium_signals_subscriptions'):
        """Sync premium signal subscriptions from Firebase to MySQL"""
        stats = {'created': 0, 'updated': 0, 'errors': 0, 'total': 0}

        try:
            firebase_data = FirebaseService.get_collection(collection_name, use_cache=False)
            stats['total'] = len(firebase_data)

            for doc in firebase_data:
                try:
                    with transaction.atomic():
                        firebase_id = doc.get('id')
                        if not firebase_id:
                            stats['errors'] += 1
                            continue

                        subscription, created = PremiumSignalSubscription.objects.update_or_create(
                            firebase_id=firebase_id,
                            defaults={
                                'firebase_user_id': doc.get('userId') or doc.get('uid') or doc.get('user_id', ''),
                                'subscription_type': doc.get('subscription_type') or doc.get('subscriptionType', ''),
                                'status': doc.get('status', ''),
                                'start_date': cls.parse_date(doc.get('start_date') or doc.get('startDate')),
                                'end_date': cls.parse_date(doc.get('end_date') or doc.get('endDate')),
                                'auto_renew': doc.get('auto_renew', False) or doc.get('autoRenew', False),
                                'price': cls.parse_decimal(doc.get('price')),
                            }
                        )

                        if created:
                            stats['created'] += 1
                        else:
                            stats['updated'] += 1

                except Exception as e:
                    print(f"Error syncing subscription {doc.get('id')}: {e}")
                    stats['errors'] += 1

        except Exception as e:
            print(f"Error fetching subscriptions from Firebase: {e}")

        return stats

    @classmethod
    def sync_courses(cls, collection_name='courses'):
        """Sync courses from Firebase to MySQL"""
        stats = {'created': 0, 'updated': 0, 'errors': 0, 'total': 0}

        try:
            firebase_data = FirebaseService.get_collection(collection_name, use_cache=False)
            stats['total'] = len(firebase_data)

            for doc in firebase_data:
                try:
                    with transaction.atomic():
                        firebase_id = doc.get('id')
                        if not firebase_id:
                            stats['errors'] += 1
                            continue

                        course, created = Course.objects.update_or_create(
                            firebase_id=firebase_id,
                            defaults={
                                'title': doc.get('title', ''),
                                'description': doc.get('description', ''),
                                'instructor': doc.get('instructor', ''),
                                'duration': doc.get('duration'),
                                'level': doc.get('level', ''),
                                'category': doc.get('category', ''),
                                'thumbnail_url': doc.get('thumbnail_url') or doc.get('thumbnailUrl', ''),
                                'video_count': doc.get('video_count', 0) or doc.get('videoCount', 0),
                                'price': cls.parse_decimal(doc.get('price')),
                                'is_free': doc.get('is_free', False) or doc.get('isFree', False),
                                'is_published': doc.get('is_published', True) or doc.get('isPublished', True),
                            }
                        )

                        if created:
                            stats['created'] += 1
                        else:
                            stats['updated'] += 1

                except Exception as e:
                    print(f"Error syncing course {doc.get('id')}: {e}")
                    stats['errors'] += 1

        except Exception as e:
            print(f"Error fetching courses from Firebase: {e}")

        return stats

    @classmethod
    def sync_fcm_tokens(cls, collection_name='fcm_tokens'):
        """Sync FCM tokens from Firebase to MySQL"""
        stats = {'created': 0, 'updated': 0, 'errors': 0, 'total': 0}

        try:
            firebase_data = FirebaseService.get_collection(collection_name, use_cache=False, limit=500)
            stats['total'] = len(firebase_data)

            for doc in firebase_data:
                try:
                    with transaction.atomic():
                        firebase_id = doc.get('id')
                        if not firebase_id:
                            stats['errors'] += 1
                            continue

                        token, created = FCMToken.objects.update_or_create(
                            firebase_id=firebase_id,
                            defaults={
                                'firebase_user_id': doc.get('userId') or doc.get('uid') or doc.get('user_id', ''),
                                'token': doc.get('token', firebase_id),
                                'platform': doc.get('platform', ''),
                                'device_info': doc.get('device_info') or doc.get('deviceInfo', ''),
                                'is_active': doc.get('is_active', True) or doc.get('isActive', True),
                                'last_used': cls.parse_date(doc.get('last_used') or doc.get('lastUsed') or doc.get('updated_at')),
                            }
                        )

                        if created:
                            stats['created'] += 1
                        else:
                            stats['updated'] += 1

                except Exception as e:
                    print(f"Error syncing token {doc.get('id')}: {e}")
                    stats['errors'] += 1

        except Exception as e:
            print(f"Error fetching FCM tokens from Firebase: {e}")

        return stats

    @classmethod
    def sync_app_notifications(cls, collection_name='app_notifications'):
        """Sync app notifications from Firebase to MySQL"""
        stats = {'created': 0, 'updated': 0, 'errors': 0, 'total': 0}

        try:
            firebase_data = FirebaseService.get_collection(collection_name, use_cache=False)
            stats['total'] = len(firebase_data)

            for doc in firebase_data:
                try:
                    with transaction.atomic():
                        firebase_id = doc.get('id')
                        if not firebase_id:
                            stats['errors'] += 1
                            continue

                        notification, created = AppNotification.objects.update_or_create(
                            firebase_id=firebase_id,
                            defaults={
                                'title': doc.get('title', ''),
                                'message': doc.get('message', ''),
                                'notification_type': doc.get('type') or doc.get('notification_type', ''),
                                'target_audience': doc.get('target_audience') or doc.get('targetAudience', ''),
                                'priority': doc.get('priority', ''),
                                'scheduled_date': cls.parse_date(doc.get('scheduled_date') or doc.get('scheduledDate')),
                                'sent_date': cls.parse_date(doc.get('sent_date') or doc.get('sentDate')),
                                'is_sent': doc.get('is_sent', False) or doc.get('isSent', False),
                            }
                        )

                        if created:
                            stats['created'] += 1
                        else:
                            stats['updated'] += 1

                except Exception as e:
                    print(f"Error syncing app notification {doc.get('id')}: {e}")
                    stats['errors'] += 1

        except Exception as e:
            print(f"Error fetching app notifications from Firebase: {e}")

        return stats

    @classmethod
    def sync_testimonials(cls, collection_name='testimonials'):
        """Sync testimonials from Firebase to MySQL"""
        stats = {'created': 0, 'updated': 0, 'errors': 0, 'total': 0}

        try:
            firebase_data = FirebaseService.get_collection(collection_name, use_cache=False)
            stats['total'] = len(firebase_data)

            for doc in firebase_data:
                try:
                    with transaction.atomic():
                        firebase_id = doc.get('id')
                        if not firebase_id:
                            stats['errors'] += 1
                            continue

                        testimonial, created = Testimonial.objects.update_or_create(
                            firebase_id=firebase_id,
                            defaults={
                                'firebase_user_id': doc.get('userId') or doc.get('uid') or doc.get('user_id', ''),
                                'author_name': doc.get('author_name') or doc.get('authorName', ''),
                                'author_email': doc.get('author_email') or doc.get('authorEmail', ''),
                                'author_avatar': doc.get('author_avatar') or doc.get('authorAvatar', ''),
                                'content': doc.get('content', ''),
                                'rating': doc.get('rating'),
                                'is_approved': doc.get('is_approved', False) or doc.get('isApproved', False),
                                'is_featured': doc.get('is_featured', False) or doc.get('isFeatured', False),
                            }
                        )

                        if created:
                            stats['created'] += 1
                        else:
                            stats['updated'] += 1

                except Exception as e:
                    print(f"Error syncing testimonial {doc.get('id')}: {e}")
                    stats['errors'] += 1

        except Exception as e:
            print(f"Error fetching testimonials from Firebase: {e}")

        return stats

    @classmethod
    def sync_firebase_users(cls, collection_name='users'):
        """Sync Firebase users to MySQL"""
        stats = {'created': 0, 'updated': 0, 'errors': 0, 'total': 0}

        try:
            firebase_data = FirebaseService.get_collection(collection_name, use_cache=False)
            stats['total'] = len(firebase_data)

            for doc in firebase_data:
                try:
                    with transaction.atomic():
                        firebase_id = doc.get('id') or doc.get('uid')
                        if not firebase_id:
                            stats['errors'] += 1
                            continue

                        user, created = FirebaseUser.objects.update_or_create(
                            firebase_id=firebase_id,
                            defaults={
                                'email': doc.get('email', ''),
                                'display_name': doc.get('display_name') or doc.get('displayName', ''),
                                'phone_number': doc.get('phone_number') or doc.get('phoneNumber', ''),
                                'photo_url': doc.get('photo_url') or doc.get('photoUrl', ''),
                                'is_premium': doc.get('is_premium', False) or doc.get('isPremium', False),
                                'is_active': doc.get('is_active', True) or doc.get('isActive', True),
                                'last_login': cls.parse_date(doc.get('last_login') or doc.get('lastLogin') or doc.get('lastSignIn')),
                                'account_created': cls.parse_date(doc.get('account_created') or doc.get('accountCreated') or doc.get('created_at')),
                            }
                        )

                        if created:
                            stats['created'] += 1
                        else:
                            stats['updated'] += 1

                except Exception as e:
                    print(f"Error syncing user {doc.get('id')}: {e}")
                    stats['errors'] += 1

        except Exception as e:
            print(f"Error fetching users from Firebase: {e}")

        return stats

    @classmethod
    def sync_collection(cls, collection_name):
        """
        Sync a specific collection based on its name

        Args:
            collection_name (str): Name of the Firebase collection

        Returns:
            dict: Statistics about the sync operation
        """
        # Map collection names to sync methods
        collection_map = {
            'purchases': cls.sync_purchases,
            'purchases_collection': cls.sync_purchases,
            'premium_signals_payments': cls.sync_premium_payments,
            'premium_signals_payments_collection': cls.sync_premium_payments,
            'signal_notifications': cls.sync_signal_notifications,
            'signal_notifications_collection': cls.sync_signal_notifications,
            'user_progress': cls.sync_user_progress,
            'user_progress_collection': cls.sync_user_progress,
            'premium_signals': cls.sync_premium_signals,
            'premium_signals_subscriptions': cls.sync_premium_signal_subscriptions,
            'courses': cls.sync_courses,
            'fcm_tokens': cls.sync_fcm_tokens,
            'app_notifications': cls.sync_app_notifications,
            'testimonials': cls.sync_testimonials,
            'users': cls.sync_firebase_users,
        }

        # Get the appropriate sync method
        sync_method = collection_map.get(collection_name.lower())

        if sync_method:
            return sync_method(collection_name)
        else:
            return {
                'error': f"No sync method defined for collection: {collection_name}",
                'created': 0,
                'updated': 0,
                'errors': 0,
                'total': 0
            }

    @classmethod
    def sync_all_collections(cls):
        """
        Sync all supported collections from Firebase to MySQL

        Returns:
            dict: Combined statistics for all sync operations
        """
        all_stats = {}

        # Get all Firebase collections
        all_collections = FirebaseService.get_all_collections()

        for collection in all_collections:
            print(f"\nSyncing collection: {collection}")
            stats = cls.sync_collection(collection)
            all_stats[collection] = stats
            print(f"  Created: {stats['created']}, Updated: {stats['updated']}, Errors: {stats['errors']}, Total: {stats['total']}")

        return all_stats
