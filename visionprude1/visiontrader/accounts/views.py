from django.shortcuts import render, redirect
from django.contrib.auth import authenticate, login, logout
from django.contrib.auth.decorators import login_required
from django.contrib.auth.models import User
from django.contrib import messages
from django.http import JsonResponse
from .models import UserProfile, SystemSettings
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
    user = request.user
    profile = user.profile
    settings = user.settings

    # Fetch Firebase data
    all_collections_raw = FirebaseService.get_all_collections()
    all_data = {}
    total_documents = 0

    # Fetch data from all collections
    for coll in all_collections_raw:
        coll_data = FirebaseService.get_collection(coll)
        if coll_data:
            coll_display_name = coll.replace('_', ' ').title()
            all_data[coll] = {
                'data': coll_data,
                'display_name': coll_display_name,
                'count': len(coll_data)
            }
            total_documents += len(coll_data)

            # Calculate totals for specific collections
            if coll.lower() in ['purchases', 'purchases_collection']:
                all_data[coll]['totals'] = calculate_collection_totals(coll_data, ['amount', 'paid', 'total_amount'])
            elif coll.lower() in ['premium_signals_payments', 'premium_signals_payments_collection']:
                all_data[coll]['totals'] = calculate_collection_totals(coll_data, ['amount', 'paid', 'total_amount', 'price'])

    context = {
        'user': user,
        'profile': profile,
        'settings': settings,
        'total_users': User.objects.count(),
        'all_collections': all_collections_raw,
        'all_data': all_data,
        'total_collections': len(all_collections_raw),
        'total_documents': total_documents,
    }
    return render(request, 'accounts/dashboard.html', context)


@login_required
def settings_view(request):
    user = request.user
    profile = user.profile
    system_settings = user.settings

    if request.method == 'POST':
        # Handle password change
        current_password = request.POST.get('current_password', '')
        new_password = request.POST.get('new_password', '')
        confirm_password = request.POST.get('confirm_password', '')

        password_change_attempted = bool(current_password or new_password or confirm_password)
        password_changed = False

        if password_change_attempted:
            if not current_password:
                messages.error(request, 'Please enter your current password.')
            elif not new_password:
                messages.error(request, 'Please enter a new password.')
            elif not confirm_password:
                messages.error(request, 'Please confirm your new password.')
            elif not user.check_password(current_password):
                messages.error(request, 'Current password is incorrect.')
            elif new_password != confirm_password:
                messages.error(request, 'New passwords do not match.')
            elif len(new_password) < 8:
                messages.error(request, 'New password must be at least 8 characters long.')
            else:
                user.set_password(new_password)
                password_changed = True
                messages.success(request, 'Password changed successfully!')

        # Update Profile (always update if form is submitted)
        user.first_name = request.POST.get('first_name', '')
        user.last_name = request.POST.get('last_name', '')
        user.email = request.POST.get('email', '')
        profile.phone = request.POST.get('phone', '')
        profile.address = request.POST.get('address', '')
        profile.bio = request.POST.get('bio', '')

        # Update System Settings
        system_settings.db_engine = request.POST.get('db_engine', 'django.db.backends.sqlite3')
        system_settings.db_name = request.POST.get('db_name', 'db.sqlite3')
        system_settings.db_host = request.POST.get('db_host', '')
        system_settings.db_port = request.POST.get('db_port', '')
        system_settings.db_user = request.POST.get('db_user', '')
        system_settings.db_password = request.POST.get('db_password', '')

        system_settings.theme = request.POST.get('theme', 'light')
        system_settings.notifications_enabled = request.POST.get('notifications_enabled') == 'on'
        system_settings.email_notifications = request.POST.get('email_notifications') == 'on'
        system_settings.language = request.POST.get('language', 'en')
        system_settings.timezone = request.POST.get('timezone', 'UTC')

        user.save()
        profile.save()
        system_settings.save()

        # Re-authenticate the user if password was changed to maintain their session
        if password_changed:
            login(request, user)

        # Only show general success message if password wasn't changed
        if not password_change_attempted:
            messages.success(request, 'Settings updated successfully!')

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
                except Exception as e:
                    print(f"Error fetching collection {coll}: {e}")
                    error_message = f"Some collections failed to load due to quota limits. Try selecting a specific collection."

            all_data = all_data_formatted
            print(f"\nTOTAL: Fetched data from {len(all_data)} collections")
            print("-"*80 + "\n")
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
