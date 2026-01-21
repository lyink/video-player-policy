from django.urls import path
from . import views

urlpatterns = [
    path('', views.login_view, name='login'),
    path('login/', views.login_view, name='login'),
    path('register/', views.register_view, name='register'),
    path('logout/', views.logout_view, name='logout'),
    path('dashboard/', views.dashboard_view, name='dashboard'),
    path('settings/', views.settings_view, name='settings'),
    path('firebase-data/', views.firebase_data_view, name='firebase_data'),
    path('sync-firebase/', views.sync_firebase_to_db, name='sync_firebase'),
]
