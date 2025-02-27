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
    NotificationListView,  RegisterView,
    UserInfoView, UserDetailView,
    ToggleLikeView, PostCommentsView, ToggleSaveView,
    FollowView, UserFollowingListView, UserFollowersListView, PostListByLocationView, NearbyPostsView, FollowPostView,
    NotificationMarkReadView, RegisterDevice, SendNotification, TestFirebaseNotification,
    MessageListView, SendMessageView, MarkMessageReadView, ConversationsListView,
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
    path('posts/<int:post_id>/comments/',
         PostCommentsView.as_view(), name='post-comments'),
    path('posts/<int:post_id>/like/', ToggleLikeView.as_view(), name='post-like'),
    path('posts/<int:post_id>/save/', ToggleSaveView.as_view(), name='post-save'),
    #Followed User's Post
    path('posts/follow/', FollowPostView.as_view(), name='follow-posts'),
    #Nearby Post
    path('posts/nearby/', NearbyPostsView.as_view(), name='nearby-posts'),
    #By Location Post
    path('posts/by-location/', PostListByLocationView.as_view(),
         name='posts-by-location'),
    
     

    # Comment Endpoints
    path('comments/', CommentListCreateView.as_view(),
         name='comment-list-create'),
    path('comments/<int:pk>/',
         CommentDetailView.as_view(), name='comment-detail'),

    # Added this lines
    path('comments/<int:comment_id>/like/',
         ToggleLikeView.as_view(), name='comment-like'),

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
    path('notifications/mark-read/', NotificationMarkReadView.as_view(),
         name='notification-mark-read'),
    # Only for development

     path('users/me/', UserInfoView.as_view(), name='user-info'),
     path('users/<int:user_id>/', UserDetailView.as_view(), name='user-detail'),
     path('users/<int:user_id>/follow/',
         FollowView.as_view(), name='follow-user'),
     path('users/<int:user_id>/following/',
         UserFollowingListView.as_view(), name='user-following'),
     path('users/<int:user_id>/followers/',
         UserFollowersListView.as_view(), name='user-followers'),

    # Notification
    path("register-device/", RegisterDevice.as_view(), name="register-device"),
    path("send-notification/", SendNotification.as_view(),
         name="send-notification"),
    path('test-notification/', TestFirebaseNotification.as_view(),
         name='test-notification'),

     # Messenger
     path("messages/", MessageListView.as_view(), name="message-list"),
     path("messages/send/", SendMessageView.as_view(), name="send-message"),
     path("messages/<int:message_id>/mark-read/", MarkMessageReadView.as_view(), name="mark-message-read"),
     path("messages/conversations/", ConversationsListView.as_view(), name="conversations-list"),
] + static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
