# Firebase Integration Setup Guide

## Overview
Your VisionTrader Django app now has Firebase Firestore integration to fetch and display data from your Firebase database.

## Setup Steps

### 1. Install Firebase Admin SDK

```bash
pip install firebase-admin
```

Or install all requirements:
```bash
pip install -r requirements.txt
```

### 2. Get Firebase Service Account Key

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Click the **Settings gear icon** → **Project settings**
4. Go to **Service accounts** tab
5. Click **Generate new private key**
6. Download the JSON file

### 3. Add Firebase Credentials to Your Project

1. Rename the downloaded JSON file to `firebase-credentials.json`
2. Place it in the root directory of your project:
   ```
   visiontrader/
   ├── firebase-credentials.json  ← Place file here
   ├── manage.py
   ├── accounts/
   ├── visiontrader/
   └── ...
   ```

**IMPORTANT SECURITY NOTE:**
- Add `firebase-credentials.json` to your `.gitignore` file
- Never commit this file to version control
- Keep your credentials secure

### 4. Update .gitignore

Add this line to your `.gitignore` file:
```
firebase-credentials.json
```

## Usage

### Access Firebase Data Page

Once set up, you can access Firebase data at:
```
http://127.0.0.1:8000/firebase-data/
```

### Features

1. **View All Collections**: See all collections in your Firebase database
2. **Browse Documents**: Select a collection to view all its documents
3. **Document Details**: Each document displays all fields and values
4. **Real-time Data**: Refresh to get the latest data from Firebase

### Navigation

Add a link to the Firebase data page in your navigation menu. The URL name is `firebase_data`:

```html
<a href="{% url 'firebase_data' %}">Firebase Data</a>
```

## Firebase Service Functions

The `firebase_service.py` module provides several useful functions:

### Get All Documents from a Collection
```python
from accounts.firebase_service import FirebaseService

# Get all documents
data = FirebaseService.get_collection('users')
```

### Get a Specific Document
```python
# Get specific document
user = FirebaseService.get_document('users', 'user_id_123')
```

### Query Collection
```python
# Query with filter
active_users = FirebaseService.query_collection('users', 'active', '==', True)
```

### Get All Collections
```python
# List all collection names
collections = FirebaseService.get_all_collections()
```

## Customization

### Using Firebase Data in Other Views

You can use Firebase data in any Django view:

```python
from django.shortcuts import render
from accounts.firebase_service import FirebaseService

def my_custom_view(request):
    # Fetch data from Firebase
    products = FirebaseService.get_collection('products')

    context = {
        'products': products,
    }
    return render(request, 'my_template.html', context)
```

### Display Firebase Data in Dashboard

To show Firebase data in your dashboard, edit `accounts/views.py`:

```python
@login_required
def dashboard_view(request):
    user = request.user
    profile = user.profile
    settings = user.settings

    # Add Firebase data
    recent_activity = FirebaseService.get_collection('activity')

    context = {
        'user': user,
        'profile': profile,
        'settings': settings,
        'total_users': User.objects.count(),
        'recent_activity': recent_activity,  # Firebase data
    }
    return render(request, 'accounts/dashboard.html', context)
```

## Troubleshooting

### Error: "Firebase credentials not found"
- Make sure `firebase-credentials.json` is in the project root
- Check the file name is exactly `firebase-credentials.json`

### Error: "Permission denied"
- Verify your service account has the correct permissions
- Check Firestore security rules in Firebase Console

### No Collections Showing
- Make sure your Firebase database has collections with data
- Check that the service account has read permissions
- Verify you're using Firestore (not Realtime Database)

### Installation Error
If you get errors installing firebase-admin on Windows, try:
```bash
pip install --upgrade pip
pip install firebase-admin
```

## Security Best Practices

1. **Never commit credentials**: Always add `firebase-credentials.json` to `.gitignore`
2. **Use environment variables**: For production, consider storing credentials in environment variables
3. **Limit permissions**: Only grant necessary permissions to the service account
4. **Firestore rules**: Set up proper security rules in Firebase Console

## Example Firebase Data Structure

Your Firebase collections might look like this:

```
users/
  ├── user_id_1
  │   ├── name: "John Doe"
  │   ├── email: "john@example.com"
  │   └── active: true
  └── user_id_2
      ├── name: "Jane Smith"
      ├── email: "jane@example.com"
      └── active: false

products/
  ├── product_id_1
  │   ├── title: "Product A"
  │   ├── price: 99.99
  │   └── stock: 50
  └── product_id_2
      ├── title: "Product B"
      ├── price: 149.99
      └── stock: 25
```

All this data will be accessible through the Firebase Data page!

## Support

For more information about Firebase Admin SDK:
- [Firebase Admin Python Documentation](https://firebase.google.com/docs/admin/setup)
- [Firestore Documentation](https://firebase.google.com/docs/firestore)

Enjoy your Firebase integration with VisionTrader!
