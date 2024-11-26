from django.urls import path
from django.conf.urls.static import static
from django.conf import settings

from .views import (
    UserListCreateView, UserDetailView,
    PostListCreateView, PostDetailView,
    CommentListCreateView, CommentDetailView,
    LikeListCreateView, LikeDetailView,
    CollectionFolderListCreateView, CollectionFolderDetailView,
    CollectListCreateView, CollectDetailView,
    NotificationListView, NotificationDetailView, MarkNotificationAsReadView, RegisterView,
    UserInfoView,
)

from rest_framework_simplejwt.views import TokenObtainPairView, TokenRefreshView


urlpatterns = [

    # JWT Token Endpoints
    path('token/', TokenObtainPairView.as_view(), name='token_obtain_pair'),
    path('token/refresh/', TokenRefreshView.as_view(), name='token_refresh'),
    path('register/', RegisterView.as_view(), name='register'),

    # User Endpoints
    path('users/', UserListCreateView.as_view(), name='user-list-create'),
    path('users/<int:pk>/', UserDetailView.as_view(), name='user-detail'),

    # Post Endpoints
    path('posts/', PostListCreateView.as_view(), name='post-list-create'),
    path('posts/<int:pk>/', PostDetailView.as_view(), name='post-detail'),

    # Comment Endpoints
    path('comments/', CommentListCreateView.as_view(),
         name='comment-list-create'),
    path('comments/<int:pk>/',
         CommentDetailView.as_view(), name='comment-detail'),

    # Like Endpoints
    path('likes/', LikeListCreateView.as_view(), name='like-list-create'),
    path('likes/<int:pk>/', LikeDetailView.as_view(), name='like-detail'),

    # Collection Folder Endpoints
    path('collections/folders/', CollectionFolderListCreateView.as_view(),
         name='collection-folder-list-create'),
    path('collections/folders/<int:pk>/',
         CollectionFolderDetailView.as_view(), name='collection-folder-detail'),

    # Collect Endpoints
    path('collections/', CollectListCreateView.as_view(),
         name='collect-list-create'),
    path('collections/<int:pk>/',
         CollectDetailView.as_view(), name='collect-detail'),

    # Notification Endpoints
    path('notifications/', NotificationListView.as_view(),
         name='notification-list'),
    path('notifications/<int:pk>/',
         NotificationDetailView.as_view(), name='notification-detail'),
    path('notifications/<int:pk>/mark-read/',
         MarkNotificationAsReadView.as_view(), name='notification-mark-read'),
    # Only for development

     path('users/me/', UserInfoView.as_view(), name='user-info'),
] + static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
