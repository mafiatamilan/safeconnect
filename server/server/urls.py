# your_django_project/urls.py

from django.contrib import admin
from django.urls import path
from rest_framework.authtoken.views import obtain_auth_token
from api.views import RegistrationView, UserProfileView

urlpatterns = [
    path('admin/', admin.site.urls),

    # --- Authentication Endpoints ---
    # For new user registration
    path('api/register/', RegistrationView.as_view(), name='register'),
    
    # For user login (returns an auth token)
    path('api/login/', obtain_auth_token, name='login'),
    
    # --- Protected Data Endpoint ---
    # Example for fetching user data
    path('api/profile/', UserProfileView.as_view(), name='profile'),
]

