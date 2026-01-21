# VisionTrader - Django Authentication System

A complete Django web application with user authentication, dashboard, and settings management using MySQL database.

## Features

- **User Authentication**
  - Login system with username/password
  - User registration with email validation
  - Secure logout functionality
  - Password validation

- **Dashboard**
  - User profile overview
  - System statistics
  - Quick action buttons
  - Professional UI with gradient design

- **Settings Management**
  - Profile settings (name, email, phone, address, bio)
  - Database configuration (engine, host, port, credentials)
  - Application preferences (theme, language, timezone)
  - Notification settings

- **Database Models**
  - UserProfile: Extended user information
  - SystemSettings: Application and database configurations
  - Automatic profile/settings creation for new users

## Installation

1. Make sure you have Python installed (3.8+)

2. Install required packages:
```bash
pip install -r requirements.txt
```

3. **Set up MySQL Database:**

   **Option 1: Using MySQL Command Line**
   ```bash
   mysql -u root -p
   CREATE DATABASE visiontrader_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
   exit;
   ```

   **Option 2: Using phpMyAdmin**
   - Open phpMyAdmin (usually at http://localhost/phpmyadmin)
   - Click "New" to create a new database
   - Name it `visiontrader_db`
   - Set collation to `utf8mb4_unicode_ci`
   - Click "Create"

4. **Update database credentials in [settings.py](visiontrader/settings.py)** (if needed):
   ```python
   DATABASES = {
       'default': {
           'ENGINE': 'django.db.backends.mysql',
           'NAME': 'visiontrader_db',
           'USER': 'root',        # Change if different
           'PASSWORD': '',        # Add your MySQL password
           'HOST': 'localhost',
           'PORT': '3306',
       }
   }
   ```

5. **Run migrations to set up database tables:**
   ```bash
   python manage.py migrate
   ```

6. **Create a superuser account:**
   ```bash
   python manage.py createsuperuser
   ```
   Follow the prompts to create your admin account.

## Running the Application

Start the development server:
```bash
python manage.py runserver
```

The application will be available at: http://127.0.0.1:8000/

## Login Credentials

After creating your superuser, use those credentials to login.

You can also create new accounts using the registration page.

## Project Structure

```
visiontrader/
├── manage.py
├── visiontrader/          # Main project settings
│   ├── settings.py
│   ├── urls.py
│   └── ...
└── accounts/              # Authentication app
    ├── models.py          # User models
    ├── views.py           # View logic
    ├── urls.py            # URL routing
    ├── admin.py           # Admin configuration
    └── templates/         # HTML templates
        └── accounts/
            ├── base.html
            ├── login.html
            ├── register.html
            ├── dashboard.html
            └── settings.html
```

## Available URLs

- `/` or `/login/` - Login page
- `/register/` - Registration page
- `/dashboard/` - User dashboard (requires login)
- `/settings/` - Settings page (requires login)
- `/logout/` - Logout
- `/admin/` - Django admin panel

## Database Configuration

**Current Database:** MySQL (configured in [settings.py](visiontrader/settings.py))

The settings page allows you to configure database settings including:
- Database engine (SQLite, PostgreSQL, MySQL, Oracle)
- Database name
- Host and port
- User credentials

**Note:** Database settings are saved in the SystemSettings model but require manual update of [settings.py](visiontrader/settings.py) to take effect.

## Customization

### Themes
The application currently uses a gradient purple theme. You can customize colors in the template CSS sections.

### Adding More Features
The modular structure makes it easy to add more features:
1. Create new views in `accounts/views.py`
2. Add URL patterns in `accounts/urls.py`
3. Create corresponding templates in `accounts/templates/accounts/`

## Security Notes

- Change the `SECRET_KEY` in `settings.py` for production
- Set `DEBUG = False` in production
- Configure `ALLOWED_HOSTS` properly
- Use environment variables for sensitive data
- Change the default admin password

## Support

For issues or questions, refer to the Django documentation: https://docs.djangoproject.com/
