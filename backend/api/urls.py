from . import views
from django.urls import path
from django.conf import settings
from django.conf.urls.static import static

# urlpatterns = [
#     # Example route for a simple view

#     # Routes for users, posts, and comments
#     path('users/', views.user_list, name='user_list'),
#     path('posts/', views.post_list, name='post_list'),
#     path('comments/', views.comment_list, name='comment_list'),
# ] + static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)

urlpatterns = [
    path('api/', views.myapp, name='myapp'),
]
