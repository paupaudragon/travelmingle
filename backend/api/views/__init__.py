from .user_views import UserListCreateView, UserDetailView, UserInfoView
from .post_views import PostListCreateView, PostDetailView
from .comment_views import CommentListCreateView, CommentDetailView, PostCommentsView
from .like_views import LikeListCreateView, LikeDetailView
from .collection_views import CollectionFolderListCreateView, CollectionFolderDetailView, CollectListCreateView, CollectDetailView
from .notification_views import NotificationListView, NotificationDetailView, MarkNotificationAsReadView
from .register_views import RegisterView
from .login_views import LoginView
from .post_views import ToggleLikeView  # Import from the correct module
