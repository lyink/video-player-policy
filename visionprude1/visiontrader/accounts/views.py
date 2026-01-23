from django.shortcuts import render, redirect
from django.contrib.auth import authenticate, login, logout
from django.contrib.auth.decorators import login_required
from django.contrib.auth.models import User
from django.contrib import messages
from django.http import JsonResponse
from .models import (
    UserProfile, SystemSettings, Purchase, PremiumSignalPayment,
    SignalNotification, UserProgress, PremiumSignal, PremiumSignalSubscription,
    Course, FCMToken, AppNotification, Testimonial, FirebaseUser
)
from django.db.models import Count
from .firebase_service import FirebaseService
from .firebase_sync import FirebaseSyncService


def calculate_collection_totals(data, fields):
    """
    Calculate totals for numeric fields in a collection

    Args:
        data (list): List of documents
        fields (list): List of field names to calculate totals for

    Returns:
        dict: Dictionary with field names and their totals
    """
    totals = {}
    for field in fields:
        total = 0
        count = 0
        for doc in data:
            value = doc.get(field, 0)
            # Try to convert to float if it's a numeric value
            try:
                if value is not None and value != '':
                    total += float(value)
                    count += 1
            except (ValueError, TypeError):
                continue

        if count > 0:
            # Format field name for display
            display_name = field.replace('_', ' ').title()
            totals[display_name] = {
                'value': total,
                'count': count,
                'average': total / count if count > 0 else 0
            }

    return totals


def login_view(request):
    if request.user.is_authenticated:
        return redirect('dashboard')

    if request.method == 'POST':
        username = request.POST.get('username')
        password = request.POST.get('password')
        user = authenticate(request, username=username, password=password)

        if user is not None:
            login(request, user)
            messages.success(request, f'Welcome back, {user.username}!')
            return redirect('dashboard')
        else:
            messages.error(request, 'Invalid username or password.')

    return render(request, 'accounts/login.html')


def register_view(request):
    if request.user.is_authenticated:
        return redirect('dashboard')

    if request.method == 'POST':
        username = request.POST.get('username')
        email = request.POST.get('email')
        password = request.POST.get('password')
        password2 = request.POST.get('password2')

        if password != password2:
            messages.error(request, 'Passwords do not match.')
        elif User.objects.filter(username=username).exists():
            messages.error(request, 'Username already exists.')
        elif User.objects.filter(email=email).exists():
            messages.error(request, 'Email already registered.')
        else:
            user = User.objects.create_user(username=username, email=email, password=password)
            user.save()
            messages.success(request, 'Account created successfully! Please login.')
            return redirect('login')

    return render(request, 'accounts/register.html')


@login_required
def logout_view(request):
    logout(request)
    messages.success(request, 'You have been logged out successfully.')
    return redirect('login')


@login_required
def dashboard_view(request):
    from django.db.models import Sum, Avg
    from datetime import timedelta
    from django.utils import timezone

    user = request.user
    profile = user.profile
    settings = user.settings

    # Get database statistics
    db_stats = {
        'purchases': Purchase.objects.count(),
        'premium_payments': PremiumSignalPayment.objects.count(),
        'signal_notifications': SignalNotification.objects.count(),
        'user_progress': UserProgress.objects.count(),
        'premium_signals': PremiumSignal.objects.count(),
        'premium_signal_subscriptions': PremiumSignalSubscription.objects.count(),
        'courses': Course.objects.count(),
        'fcm_tokens': FCMToken.objects.count(),
        'app_notifications': AppNotification.objects.count(),
        'testimonials': Testimonial.objects.count(),
        'firebase_users': FirebaseUser.objects.count(),
    }

    # Calculate total records
    total_records = sum(db_stats.values())

    # Revenue statistics
    purchase_stats = Purchase.objects.aggregate(
        total_revenue=Sum('amount'),
        total_paid=Sum('paid'),
        avg_purchase=Avg('amount')
    )

    premium_stats = PremiumSignalPayment.objects.aggregate(
        total_revenue=Sum('amount'),
        total_paid=Sum('paid'),
        avg_payment=Avg('amount')
    )

    # Recent activity - last 7 days
    week_ago = timezone.now() - timedelta(days=7)

    recent_purchases = Purchase.objects.filter(
        purchase_date__gte=week_ago
    ).count() if Purchase.objects.filter(purchase_date__isnull=False).exists() else 0

    recent_payments = PremiumSignalPayment.objects.filter(
        payment_date__gte=week_ago
    ).count() if PremiumSignalPayment.objects.filter(payment_date__isnull=False).exists() else 0

    recent_notifications = SignalNotification.objects.filter(
        notification_date__gte=week_ago
    ).count() if SignalNotification.objects.filter(notification_date__isnull=False).exists() else 0

    # Latest records
    latest_purchases = Purchase.objects.all()[:5]
    latest_payments = PremiumSignalPayment.objects.all()[:5]
    latest_signals = PremiumSignal.objects.all()[:5]
    latest_users = FirebaseUser.objects.all()[:10]

    # User engagement
    active_subscriptions = PremiumSignalSubscription.objects.filter(
        status='active'
    ).count()

    unread_notifications = SignalNotification.objects.filter(
        read=False
    ).count()

    # Calculate totals
    total_revenue = (purchase_stats['total_revenue'] or 0) + (premium_stats['total_revenue'] or 0)
    total_paid = (purchase_stats['total_paid'] or 0) + (premium_stats['total_paid'] or 0)

    context = {
        'user': user,
        'profile': profile,
        'settings': settings,
        'db_stats': db_stats,
        'total_records': total_records,
        'total_revenue': total_revenue,
        'total_paid': total_paid,
        'purchase_stats': purchase_stats,
        'premium_stats': premium_stats,
        'recent_purchases': recent_purchases,
        'recent_payments': recent_payments,
        'recent_notifications': recent_notifications,
        'latest_purchases': latest_purchases,
        'latest_payments': latest_payments,
        'latest_signals': latest_signals,
        'latest_users': latest_users,
        'active_subscriptions': active_subscriptions,
        'unread_notifications': unread_notifications,
    }
    return render(request, 'accounts/dashboard.html', context)


@login_required
def settings_view(request):
    user = request.user
    profile = user.profile
    system_settings = user.settings

    if request.method == 'POST':
        # Handle AJAX theme update from topbar
        if request.POST.get('ajax_update') == 'true':
            theme = request.POST.get('theme', 'light')
            system_settings.theme = theme
            system_settings.save()
            return JsonResponse({'success': True, 'theme': theme})

        has_errors = False

        # Handle password change
        current_password = request.POST.get('current_password', '').strip()
        new_password = request.POST.get('new_password', '').strip()
        confirm_password = request.POST.get('confirm_password', '').strip()

        password_change_attempted = bool(current_password or new_password or confirm_password)
        password_changed = False

        if password_change_attempted:
            if not current_password:
                messages.error(request, 'Please enter your current password.')
                has_errors = True
            elif not new_password:
                messages.error(request, 'Please enter a new password.')
                has_errors = True
            elif not confirm_password:
                messages.error(request, 'Please confirm your new password.')
                has_errors = True
            elif not user.check_password(current_password):
                messages.error(request, 'Current password is incorrect.')
                has_errors = True
            elif new_password != confirm_password:
                messages.error(request, 'New passwords do not match.')
                has_errors = True
            elif len(new_password) < 8:
                messages.error(request, 'New password must be at least 8 characters long.')
                has_errors = True
            else:
                user.set_password(new_password)
                password_changed = True
                messages.success(request, 'Password changed successfully!')

        # Validate and update Profile
        first_name = request.POST.get('first_name', '').strip()
        last_name = request.POST.get('last_name', '').strip()
        email = request.POST.get('email', '').strip()
        phone = request.POST.get('phone', '').strip()
        address = request.POST.get('address', '').strip()
        bio = request.POST.get('bio', '').strip()

        # Email validation
        if email and email != user.email:
            if User.objects.filter(email=email).exclude(id=user.id).exists():
                messages.error(request, 'This email address is already in use.')
                has_errors = True

        # Only update if no errors
        if not has_errors:
            user.first_name = first_name
            user.last_name = last_name
            user.email = email
            profile.phone = phone
            profile.address = address
            profile.bio = bio[:500]  # Limit bio to 500 characters

            # Update System Settings - Database
            system_settings.db_engine = request.POST.get('db_engine', 'django.db.backends.sqlite3')
            system_settings.db_name = request.POST.get('db_name', 'db.sqlite3')
            system_settings.db_host = request.POST.get('db_host', '').strip()
            system_settings.db_port = request.POST.get('db_port', '').strip()
            system_settings.db_user = request.POST.get('db_user', '').strip()

            # Only update password if it was provided
            new_db_password = request.POST.get('db_password', '').strip()
            if new_db_password:
                system_settings.db_password = new_db_password

            # Update System Settings - Preferences
            system_settings.theme = request.POST.get('theme', 'light')
            system_settings.notifications_enabled = request.POST.get('notifications_enabled') == 'on'
            system_settings.email_notifications = request.POST.get('email_notifications') == 'on'
            system_settings.language = request.POST.get('language', 'en')
            system_settings.timezone = request.POST.get('timezone', 'UTC')

            try:
                user.save()
                profile.save()
                system_settings.save()

                # Re-authenticate the user if password was changed to maintain their session
                if password_changed:
                    login(request, user)

                # Only show general success message if password wasn't changed
                if not password_change_attempted:
                    messages.success(request, 'Settings updated successfully!')

            except Exception as e:
                messages.error(request, f'Error saving settings: {str(e)}')
                has_errors = True

        if not has_errors:
            return redirect('settings')

    db_engines = [
        ('django.db.backends.sqlite3', 'SQLite'),
        ('django.db.backends.postgresql', 'PostgreSQL'),
        ('django.db.backends.mysql', 'MySQL'),
        ('django.db.backends.oracle', 'Oracle'),
    ]

    timezones = [
        'UTC', 'US/Eastern', 'US/Central', 'US/Mountain', 'US/Pacific',
        'Europe/London', 'Europe/Paris', 'Asia/Tokyo', 'Asia/Shanghai',
        'Australia/Sydney', 'Africa/Nairobi'
    ]

    context = {
        'user': user,
        'profile': profile,
        'settings': system_settings,
        'db_engines': db_engines,
        'timezones': timezones,
    }
    return render(request, 'accounts/settings.html', context)


@login_required
def firebase_data_view(request):
    """View to display Firebase data with caching and pagination"""
    collection_name = request.GET.get('collection', None)
    refresh = request.GET.get('refresh', '').lower() == 'true'

    # Check if database is empty and auto-fetch from Firebase
    total_records = (
        Purchase.objects.count() +
        PremiumSignalPayment.objects.count() +
        SignalNotification.objects.count() +
        UserProgress.objects.count()
    )

    if total_records == 0 and not refresh:
        # Database is empty, force a refresh from Firebase
        refresh = True
        messages.info(request, "Database is empty. Fetching data from Firebase...")

    # Clear cache if refresh is requested
    if refresh:
        if collection_name:
            FirebaseService.clear_cache(collection_name)
        else:
            FirebaseService.clear_cache()
        print("Cache cleared due to refresh request")

    # Get all collections (with caching)
    all_collections_raw = FirebaseService.get_all_collections(use_cache=not refresh)
    print("\n" + "="*80)
    print(f"ALL COLLECTIONS FOUND: {all_collections_raw}")
    print("="*80 + "\n")

    # Format collection names for display - [(original_name, display_name), ...]
    all_collections = [(coll, coll.replace('_', ' ').title()) for coll in all_collections_raw]

    # Get data from selected collection or all collections
    firebase_data = []
    all_data = {}
    field_names = []
    collection_display_name = collection_name.replace('_', ' ').title() if collection_name else None
    collection_totals = {}
    error_message = None

    if collection_name:
        # Fetch specific collection with caching
        try:
            firebase_data = FirebaseService.get_collection(collection_name, use_cache=not refresh)

            if firebase_data:
                print(f"\nFETCHED {len(firebase_data)} documents from '{collection_name}' collection")
                print("-"*80)
                for i, doc in enumerate(firebase_data[:5], 1):  # Only print first 5 for performance
                    print(f"\nDocument {i}: {doc.get('id', 'NO ID')}")
                    for key, value in doc.items():
                        if key != 'id':
                            print(f"  {key}: {value}")
                if len(firebase_data) > 5:
                    print(f"\n... and {len(firebase_data) - 5} more documents")
                print("-"*80 + "\n")

                # Automatically sync to database after fetching
                try:
                    sync_stats = FirebaseSyncService.sync_collection(collection_name)
                    if 'error' not in sync_stats:
                        print(f"Auto-synced {collection_name}: {sync_stats['created']} created, {sync_stats['updated']} updated")
                        messages.success(request, f"Synced {collection_name}: {sync_stats['created']} created, {sync_stats['updated']} updated")
                except Exception as e:
                    print(f"Error auto-syncing {collection_name}: {e}")

                # Format field names - remove underscores and title case
                field_names = [(key, key.replace('_', ' ').title()) for key in firebase_data[0].keys()
                              if key not in ['id', 'uid', 'userId', 'user_id']]

                # Calculate totals for specific collections
                if collection_name.lower() in ['purchases', 'purchases_collection']:
                    collection_totals = calculate_collection_totals(firebase_data, ['amount', 'paid', 'total_amount'])
                elif collection_name.lower() in ['premium_signals_payments', 'premium_signals_payments_collection']:
                    collection_totals = calculate_collection_totals(firebase_data, ['amount', 'paid', 'total_amount', 'price'])
            else:
                error_message = f"No data found in collection '{collection_name}' or request timed out."
        except Exception as e:
            error_message = f"Error loading collection '{collection_name}': {str(e)}"
            print(f"ERROR: {error_message}")
    elif not collection_name and all_collections_raw:
        # Fetch all collections if none selected (LIMIT TO 100 docs per collection)
        print(f"\nFETCHING DATA FROM ALL {len(all_collections_raw)} COLLECTIONS...")
        print("-"*80)
        all_data_formatted = {}
        total_synced = 0

        try:
            for coll in all_collections_raw:
                try:
                    # Limit to 100 documents per collection to avoid quota issues
                    coll_data = FirebaseService.get_collection(coll, use_cache=not refresh, limit=100)

                    if coll_data:
                        # Format field names for each collection
                        coll_field_names = [(key, key.replace('_', ' ').title()) for key in coll_data[0].keys()
                                           if key not in ['id', 'uid', 'userId', 'user_id']]
                        coll_display_name = coll.replace('_', ' ').title()
                        all_data_formatted[coll] = {
                            'data': coll_data,
                            'field_names': coll_field_names,
                            'display_name': coll_display_name
                        }
                        print(f"\n{coll}: {len(coll_data)} documents")
                        # Only print first 2 documents to reduce console spam
                        for i, doc in enumerate(coll_data[:2], 1):
                            print(f"  Document {i} ID: {doc.get('id', 'NO ID')}")
                        if len(coll_data) > 2:
                            print(f"  ... and {len(coll_data) - 2} more documents")

                        # Automatically sync to database
                        try:
                            sync_stats = FirebaseSyncService.sync_collection(coll)
                            if 'error' not in sync_stats:
                                print(f"  Auto-synced: {sync_stats['created']} created, {sync_stats['updated']} updated")
                                total_synced += sync_stats['created'] + sync_stats['updated']
                        except Exception as e:
                            print(f"  Error auto-syncing {coll}: {e}")

                except Exception as e:
                    print(f"Error fetching collection {coll}: {e}")
                    error_message = f"Some collections failed to load due to quota limits. Try selecting a specific collection."

            all_data = all_data_formatted
            print(f"\nTOTAL: Fetched data from {len(all_data)} collections, synced {total_synced} records")
            print("-"*80 + "\n")

            if total_synced > 0:
                messages.success(request, f"Successfully synced {total_synced} records from {len(all_data)} collections to database")

        except Exception as e:
            error_message = f"Error loading collections: {str(e)}"
            print(f"ERROR: {error_message}")
    else:
        print("\nNO COLLECTIONS FOUND OR NO DATA FETCHED")
        print("-"*80 + "\n")

    context = {
        'all_collections': all_collections,
        'selected_collection': collection_name,
        'collection_display_name': collection_display_name,
        'firebase_data': firebase_data,
        'all_data': all_data,
        'field_names': field_names,
        'collection_totals': collection_totals,
        'error_message': error_message,
    }
    return render(request, 'accounts/firebase_data.html', context)


@login_required
def test_database_connection(request):
    """
    Test database connection with provided settings
    """
    if request.method != 'POST':
        return JsonResponse({'error': 'POST method required'}, status=405)

    try:
        import mysql.connector
        import psycopg2
        import sqlite3

        db_engine = request.POST.get('db_engine', '')
        db_name = request.POST.get('db_name', '')
        db_host = request.POST.get('db_host', 'localhost')
        db_port = request.POST.get('db_port', '')
        db_user = request.POST.get('db_user', '')
        db_password = request.POST.get('db_password', '')

        connection_success = False
        error_message = None

        try:
            if 'sqlite' in db_engine.lower():
                # Test SQLite connection
                conn = sqlite3.connect(db_name)
                conn.close()
                connection_success = True
                message = f"Successfully connected to SQLite database: {db_name}"

            elif 'mysql' in db_engine.lower():
                # Test MySQL connection
                if not db_port:
                    db_port = '3306'
                conn = mysql.connector.connect(
                    host=db_host,
                    port=int(db_port),
                    user=db_user,
                    password=db_password,
                    database=db_name
                )
                conn.close()
                connection_success = True
                message = f"Successfully connected to MySQL database: {db_name} at {db_host}:{db_port}"

            elif 'postgresql' in db_engine.lower() or 'postgres' in db_engine.lower():
                # Test PostgreSQL connection
                if not db_port:
                    db_port = '5432'
                conn = psycopg2.connect(
                    host=db_host,
                    port=int(db_port),
                    user=db_user,
                    password=db_password,
                    database=db_name
                )
                conn.close()
                connection_success = True
                message = f"Successfully connected to PostgreSQL database: {db_name} at {db_host}:{db_port}"

            else:
                error_message = f"Unsupported database engine: {db_engine}"

        except Exception as e:
            error_message = str(e)
            connection_success = False

        if connection_success:
            return JsonResponse({
                'success': True,
                'message': message
            })
        else:
            return JsonResponse({
                'success': False,
                'error': error_message or 'Connection failed'
            }, status=400)

    except ImportError as e:
        return JsonResponse({
            'success': False,
            'error': f'Required database driver not installed: {str(e)}'
        }, status=400)
    except Exception as e:
        return JsonResponse({
            'success': False,
            'error': str(e)
        }, status=500)


@login_required
def check_firebase_updates(request):
    """
    Check if there are new updates in Firebase compared to database
    """
    if request.method != 'GET':
        return JsonResponse({'error': 'GET method required'}, status=405)

    try:
        collection_name = request.GET.get('collection', None)
        updates_available = {}
        total_new = 0

        # Model mapping for supported collections
        model_map = {
            'purchases': Purchase,
            'premium_signals_payments': PremiumSignalPayment,
            'signal_notifications': SignalNotification,
            'user_progress': UserProgress,
            'premium_signals': PremiumSignal,
            'premium_signals_subscriptions': PremiumSignalSubscription,
            'courses': Course,
            'fcm_tokens': FCMToken,
            'app_notifications': AppNotification,
            'testimonials': Testimonial,
            'users': FirebaseUser,
        }

        if collection_name:
            # Check specific collection
            if collection_name.lower() in model_map:
                firebase_data = FirebaseService.get_collection(collection_name, use_cache=False)
                model = model_map[collection_name.lower()]
                db_count = model.objects.count()
                firebase_count = len(firebase_data) if firebase_data else 0
                new_records = max(0, firebase_count - db_count)

                if new_records > 0:
                    updates_available[collection_name] = {
                        'firebase_count': firebase_count,
                        'db_count': db_count,
                        'new_records': new_records
                    }
                    total_new += new_records
        else:
            # Check all collections
            all_collections = FirebaseService.get_all_collections()

            for coll in all_collections:
                if coll.lower() in model_map:
                    try:
                        firebase_data = FirebaseService.get_collection(coll, use_cache=False, limit=1000)
                        model = model_map[coll.lower()]
                        db_count = model.objects.count()
                        firebase_count = len(firebase_data) if firebase_data else 0
                        new_records = max(0, firebase_count - db_count)

                        if new_records > 0:
                            updates_available[coll] = {
                                'firebase_count': firebase_count,
                                'db_count': db_count,
                                'new_records': new_records
                            }
                            total_new += new_records
                    except Exception as e:
                        print(f"Error checking {coll}: {e}")

        return JsonResponse({
            'success': True,
            'has_updates': total_new > 0,
            'total_new': total_new,
            'updates': updates_available,
            'message': f"Found {total_new} new records in Firebase" if total_new > 0 else "Database is up to date"
        })

    except Exception as e:
        print(f"ERROR checking updates: {e}")
        return JsonResponse({
            'success': False,
            'error': str(e)
        }, status=500)


@login_required
def sync_firebase_to_db(request):
    """
    Sync Firebase data to MySQL database
    Can sync a specific collection or all collections
    """
    if request.method != 'POST':
        return JsonResponse({'error': 'POST method required'}, status=405)

    collection_name = request.POST.get('collection', None)

    try:
        if collection_name:
            # Sync specific collection
            print(f"\n{'='*80}")
            print(f"Syncing collection: {collection_name}")
            print(f"{'='*80}\n")

            stats = FirebaseSyncService.sync_collection(collection_name)

            if 'error' in stats:
                return JsonResponse({
                    'success': False,
                    'error': stats['error']
                }, status=400)

            print(f"\n{'='*80}")
            print(f"Sync completed for {collection_name}")
            print(f"Created: {stats['created']}, Updated: {stats['updated']}, Errors: {stats['errors']}")
            print(f"{'='*80}\n")

            messages.success(
                request,
                f"Synced {collection_name}: {stats['created']} created, {stats['updated']} updated, {stats['errors']} errors"
            )

            return JsonResponse({
                'success': True,
                'collection': collection_name,
                'stats': stats,
                'message': f"Successfully synced {stats['total']} documents"
            })
        else:
            # Sync all collections
            print(f"\n{'='*80}")
            print("Syncing ALL collections")
            print(f"{'='*80}\n")

            all_stats = FirebaseSyncService.sync_all_collections()

            total_created = sum(s['created'] for s in all_stats.values())
            total_updated = sum(s['updated'] for s in all_stats.values())
            total_errors = sum(s['errors'] for s in all_stats.values())

            print(f"\n{'='*80}")
            print(f"All collections synced")
            print(f"Total - Created: {total_created}, Updated: {total_updated}, Errors: {total_errors}")
            print(f"{'='*80}\n")

            messages.success(
                request,
                f"Synced all collections: {total_created} created, {total_updated} updated, {total_errors} errors"
            )

            return JsonResponse({
                'success': True,
                'all_stats': all_stats,
                'totals': {
                    'created': total_created,
                    'updated': total_updated,
                    'errors': total_errors
                },
                'message': f"Successfully synced {len(all_stats)} collections"
            })

    except Exception as e:
        print(f"ERROR syncing: {e}")
        return JsonResponse({
            'success': False,
            'error': str(e)
        }, status=500)


@login_required
def model_list_view(request, model_name):
    """Generic view to list data from any Firebase-synced model"""
    from django.core.paginator import Paginator
    from django.db.models import Q

    # Model mapping
    model_map = {
        'purchases': {
            'model': Purchase,
            'display_name': 'Purchases',
            'icon': '💰',
            'fields': ['firebase_id', 'firebase_user_id', 'product_name', 'amount', 'paid', 'status', 'purchase_date'],
            'searchable': ['firebase_user_id', 'product_name', 'status'],
        },
        'premium_payments': {
            'model': PremiumSignalPayment,
            'display_name': 'Premium Signal Payments',
            'icon': '💎',
            'fields': ['firebase_id', 'firebase_user_id', 'signal_id', 'amount', 'paid', 'status', 'payment_date'],
            'searchable': ['firebase_user_id', 'signal_id', 'status'],
        },
        'signal_notifications': {
            'model': SignalNotification,
            'display_name': 'Signal Notifications',
            'icon': '📢',
            'fields': ['firebase_id', 'firebase_user_id', 'signal_id', 'title', 'message', 'read', 'notification_date'],
            'searchable': ['firebase_user_id', 'signal_id', 'title', 'message'],
        },
        'user_progress': {
            'model': UserProgress,
            'display_name': 'User Progress',
            'icon': '📊',
            'fields': ['firebase_id', 'firebase_user_id', 'course_id', 'lesson_id', 'completed', 'progress_percentage', 'last_accessed'],
            'searchable': ['firebase_user_id', 'course_id', 'lesson_id'],
        },
        'premium_signals': {
            'model': PremiumSignal,
            'display_name': 'Premium Signals',
            'icon': '📈',
            'fields': ['firebase_id', 'signal_type', 'symbol', 'entry_price', 'target_price', 'stop_loss', 'status', 'signal_date'],
            'searchable': ['symbol', 'signal_type', 'status'],
        },
        'premium_subscriptions': {
            'model': PremiumSignalSubscription,
            'display_name': 'Premium Subscriptions',
            'icon': '⭐',
            'fields': ['firebase_id', 'firebase_user_id', 'subscription_type', 'status', 'start_date', 'end_date'],
            'searchable': ['firebase_user_id', 'subscription_type', 'status'],
        },
        'courses': {
            'model': Course,
            'display_name': 'Courses',
            'icon': '📚',
            'fields': ['firebase_id', 'title', 'instructor', 'description', 'duration', 'is_published', 'created_at'],
            'searchable': ['title', 'instructor', 'description'],
        },
        'fcm_tokens': {
            'model': FCMToken,
            'display_name': 'FCM Tokens',
            'icon': '🔔',
            'fields': ['firebase_id', 'firebase_user_id', 'token', 'platform', 'is_active', 'created_at'],
            'searchable': ['firebase_user_id', 'platform'],
        },
        'app_notifications': {
            'model': AppNotification,
            'display_name': 'App Notifications',
            'icon': '📬',
            'fields': ['firebase_id', 'title', 'message', 'notification_type', 'target_audience', 'is_sent', 'sent_at'],
            'searchable': ['title', 'message', 'notification_type', 'target_audience'],
        },
        'testimonials': {
            'model': Testimonial,
            'display_name': 'Testimonials',
            'icon': '⭐',
            'fields': ['firebase_id', 'author_name', 'author_email', 'rating', 'comment', 'is_approved', 'created_at'],
            'searchable': ['author_name', 'author_email', 'comment'],
        },
        'users': {
            'model': FirebaseUser,
            'display_name': 'Firebase Users',
            'icon': '👤',
            'fields': ['firebase_id', 'email', 'display_name', 'is_premium', 'premium_expiry', 'is_active', 'created_at'],
            'searchable': ['email', 'display_name'],
        },
    }

    # Validate model name
    if model_name not in model_map:
        messages.error(request, f"Invalid model: {model_name}")
        return redirect('dashboard')

    model_config = model_map[model_name]
    model = model_config['model']

    # Get search query
    search_query = request.GET.get('search', '').strip()

    # Build queryset
    queryset = model.objects.all().order_by('-synced_at')

    # Apply search filter
    if search_query:
        q_objects = Q()
        for field in model_config['searchable']:
            q_objects |= Q(**{f"{field}__icontains": search_query})
        queryset = queryset.filter(q_objects)

    # Pagination
    paginator = Paginator(queryset, 25)  # 25 items per page
    page_number = request.GET.get('page', 1)
    page_obj = paginator.get_page(page_number)

    context = {
        'model_name': model_name,
        'model_config': model_config,
        'page_obj': page_obj,
        'search_query': search_query,
        'total_count': queryset.count(),
    }

    return render(request, 'accounts/model_list.html', context)


@login_required
def model_detail_view(request, model_name, pk):
    """Generic view to display detail of a single record"""
    from django.shortcuts import get_object_or_404

    # Model mapping (same as above)
    model_map = {
        'purchases': {'model': Purchase, 'display_name': 'Purchase', 'icon': '💰'},
        'premium_payments': {'model': PremiumSignalPayment, 'display_name': 'Premium Payment', 'icon': '💎'},
        'signal_notifications': {'model': SignalNotification, 'display_name': 'Signal Notification', 'icon': '📢'},
        'user_progress': {'model': UserProgress, 'display_name': 'User Progress', 'icon': '📊'},
        'premium_signals': {'model': PremiumSignal, 'display_name': 'Premium Signal', 'icon': '📈'},
        'premium_subscriptions': {'model': PremiumSignalSubscription, 'display_name': 'Premium Subscription', 'icon': '⭐'},
        'courses': {'model': Course, 'display_name': 'Course', 'icon': '📚'},
        'fcm_tokens': {'model': FCMToken, 'display_name': 'FCM Token', 'icon': '🔔'},
        'app_notifications': {'model': AppNotification, 'display_name': 'App Notification', 'icon': '📬'},
        'testimonials': {'model': Testimonial, 'display_name': 'Testimonial', 'icon': '⭐'},
        'users': {'model': FirebaseUser, 'display_name': 'Firebase User', 'icon': '👤'},
    }

    # Validate model name
    if model_name not in model_map:
        messages.error(request, f"Invalid model: {model_name}")
        return redirect('dashboard')

    model_config = model_map[model_name]
    model = model_config['model']

    # Get the object
    obj = get_object_or_404(model, pk=pk)

    # Get all fields and their values
    field_data = []
    for field in obj._meta.fields:
        field_name = field.name
        field_value = getattr(obj, field_name)
        field_verbose_name = field.verbose_name.title()

        # Format field value
        if field_value is None:
            field_value = '-'
        elif isinstance(field_value, bool):
            field_value = '✓' if field_value else '✗'

        field_data.append({
            'name': field_name,
            'verbose_name': field_verbose_name,
            'value': field_value,
            'type': field.get_internal_type()
        })

    context = {
        'model_name': model_name,
        'model_config': model_config,
        'object': obj,
        'field_data': field_data,
    }

    return render(request, 'accounts/model_detail.html', context)
