# VisionTrader Setup Guide

## Quick Setup Steps

### 1. Install Required Packages
```bash
pip install -r requirements.txt
```

### 2. Create MySQL Database

**Option A: Using MySQL Command Line**
```bash
mysql -u root -p
```
Then in MySQL:
```sql
CREATE DATABASE visiontrader CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
EXIT;
```

**Option B: Using phpMyAdmin**
1. Open phpMyAdmin (http://localhost/phpmyadmin)
2. Click "New" database
3. Name: `visiontrader`
4. Collation: `utf8mb4_unicode_ci`
5. Click "Create"

### 3. Update Database Password (if needed)
Edit `visiontrader/settings.py` line 82 if your MySQL root user has a password:
```python
'PASSWORD': 'your_mysql_password_here',
```

### 4. Run Migrations
```bash
python manage.py migrate
```

### 5. Create Superuser
```bash
python manage.py createsuperuser
```
Follow the prompts to set username, email, and password.

### 6. Run the Server
```bash
python manage.py runserver
```

### 7. Access the Application
Open your browser and go to: **http://127.0.0.1:8000/**

## Troubleshooting

### Database Connection Error
- Make sure MySQL is running
- Check database name is exactly `visiontrader`
- Verify MySQL credentials in settings.py

### mysqlclient Installation Error on Windows
If you get an error installing mysqlclient, try:
```bash
pip install mysqlclient==2.2.0
```

Or download the wheel file from: https://www.lfd.uci.edu/~gohlke/pythonlibs/#mysqlclient

### Template Error
If you see template errors, make sure the `base.html` file is properly formatted with no duplicate `{% block content %}` tags.

## Features

- User Authentication (Login/Register)
- Professional Dashboard
- Settings Management
  - Profile Settings
  - Database Configuration
  - Application Preferences
- Dark Mode Toggle
- Responsive Design

## Default Login (if you set up with the guide)

After creating your superuser, use those credentials to login.

## URLs

- `/` - Login Page
- `/register/` - Registration Page
- `/dashboard/` - Dashboard (requires login)
- `/settings/` - Settings (requires login)
- `/admin/` - Django Admin Panel
- `/logout/` - Logout

Enjoy using VisionTrader!
