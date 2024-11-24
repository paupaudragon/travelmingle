# from drf_yasg import openapi
# from drf_yasg.utils import swagger_auto_schema
# from rest_framework.generics import ListCreateAPIView, RetrieveUpdateDestroyAPIView, UpdateAPIView
# from rest_framework.views import APIView
# from rest_framework.response import Response
# from rest_framework import status
# from django.db.models import Q

# from .models import Users, Posts, Comments, Likes, CollectionFolders, Collects, Notifications
# from .serializers import (
#     UserSerializer, PostSerializer, CommentSerializer,
#     LikeSerializer, CollectionFolderSerializer, CollectSerializer,
#     NotificationSerializer
# )

# import logging

# # Set up logger
# logger = logging.getLogger(__name__)

# # ---------------------------------
# # User Views
# # ---------------------------------


# class UserListCreateView(ListCreateAPIView):
#     queryset = Users.objects.all()
#     serializer_class = UserSerializer

#     @swagger_auto_schema(
#         operation_summary="List all users",
#         operation_description="Retrieve a list of all registered users.",
#         responses={200: UserSerializer(many=True)},
#     )
#     def get(self, request, *args, **kwargs):
#         return super().get(request, *args, **kwargs)

#     @swagger_auto_schema(
#         operation_summary="Create a new user",
#         operation_description="Create a new user by providing the username, email, password, and optional bio or profile picture.",
#         request_body=UserSerializer,
#         responses={201: UserSerializer},
#     )
#     def post(self, request, *args, **kwargs):
#         return super().post(request, *args, **kwargs)


# class UserDetailView(RetrieveUpdateDestroyAPIView):
#     queryset = Users.objects.all()
#     serializer_class = UserSerializer

#     @swagger_auto_schema(
#         operation_summary="Retrieve a user",
#         operation_description="Retrieve details of a specific user by ID.",
#         responses={200: UserSerializer},
#     )
#     def get(self, request, *args, **kwargs):
#         return super().get(request, *args, **kwargs)

#     @swagger_auto_schema(
#         operation_summary="Update a user",
#         operation_description="Update user information such as username, email, bio, or profile picture.",
#         request_body=UserSerializer,
#         responses={200: UserSerializer},
#     )
#     def patch(self, request, *args, **kwargs):
#         return super().patch(request, *args, **kwargs)

#     @swagger_auto_schema(
#         operation_summary="Delete a user",
#         operation_description="Delete a user from the system by ID.",
#         responses={204: "User deleted successfully."},
#     )
#     def delete(self, request, *args, **kwargs):
#         return super().delete(request, *args, **kwargs)

# # ---------------------------------
# # Post Views
# # ---------------------------------


# class PostListCreateView(ListCreateAPIView):
#     queryset = Posts.objects.select_related('user').all()
#     serializer_class = PostSerializer

#     @swagger_auto_schema(
#         operation_summary="List all posts",
#         operation_description="Retrieve a list of all posts with their associated user details.",
#         responses={200: PostSerializer(many=True)},
#     )
#     def get(self, request, *args, **kwargs):
#         return super().get(request, *args, **kwargs)

#     @swagger_auto_schema(
#         operation_summary="Create a new post",
#         operation_description="Create a new post by providing the user ID, title, content, and optional visibility or status.",
#         request_body=PostSerializer,
#         responses={201: PostSerializer},
#     )
#     def post(self, request, *args, **kwargs):
#         return super().post(request, *args, **kwargs)


# class PostDetailView(RetrieveUpdateDestroyAPIView):
#     queryset = Posts.objects.select_related('user').all()
#     serializer_class = PostSerializer

#     @swagger_auto_schema(
#         operation_summary="Retrieve a post",
#         operation_description="Retrieve details of a specific post by ID, including its associated user and comments.",
#         responses={200: PostSerializer},
#     )
#     def get(self, request, *args, **kwargs):
#         return super().get(request, *args, **kwargs)

#     @swagger_auto_schema(
#         operation_summary="Update a post",
#         operation_description="Update a specific post's title, content, status, or visibility.",
#         request_body=PostSerializer,
#         responses={200: PostSerializer},
#     )
#     def patch(self, request, *args, **kwargs):
#         return super().patch(request, *args, **kwargs)

#     @swagger_auto_schema(
#         operation_summary="Delete a post",
#         operation_description="Delete a specific post by ID.",
#         responses={204: "Post deleted successfully."},
#     )
#     def delete(self, request, *args, **kwargs):
#         return super().delete(request, *args, **kwargs)

# # ---------------------------------
# # Comment Views
# # ---------------------------------


# class CommentListCreateView(ListCreateAPIView):
#     """
#     Handles listing all comments and creating new comments.
#     """
#     queryset = Comments.objects.select_related('user', 'post').all()
#     serializer_class = CommentSerializer

#     @swagger_auto_schema(
#         operation_summary="List all comments",
#         operation_description="Retrieve a list of all comments, including user details and associated posts.",
#         responses={200: CommentSerializer(many=True)}
#     )
#     def get(self, request, *args, **kwargs):
#         return super().get(request, *args, **kwargs)

#     @swagger_auto_schema(
#         operation_summary="Create a new comment",
#         operation_description="Create a new comment for a post or as a reply to another comment. "
#         "Provide `post_id` to associate the comment with a post, and optionally "
#         "provide `reply_to` to associate the comment as a reply to another comment.",
#         request_body=CommentSerializer,
#         responses={201: CommentSerializer}
#     )
#     def post(self, request, *args, **kwargs):
#         return super().post(request, *args, **kwargs)


# class CommentDetailView(RetrieveUpdateDestroyAPIView):
#     """
#     Handles retrieving, updating, and deleting a specific comment.
#     """
#     queryset = Comments.objects.select_related('user', 'post').all()
#     serializer_class = CommentSerializer

#     @swagger_auto_schema(
#         operation_summary="Retrieve a comment",
#         operation_description="Retrieve details of a specific comment by its ID.",
#         responses={200: CommentSerializer}
#     )
#     def get(self, request, *args, **kwargs):
#         return super().get(request, *args, **kwargs)

#     @swagger_auto_schema(
#         operation_summary="Update a comment",
#         operation_description="Update a comment's content or parent comment (reply_to).",
#         request_body=CommentSerializer,
#         responses={200: CommentSerializer}
#     )
#     def patch(self, request, *args, **kwargs):
#         return super().patch(request, *args, **kwargs)

#     @swagger_auto_schema(
#         operation_summary="Delete a comment",
#         operation_description="Delete a comment by its ID.",
#         responses={204: "Comment deleted successfully."}
#     )
#     def delete(self, request, *args, **kwargs):
#         return super().delete(request, *args, **kwargs)


# # ---------------------------------
# # Like Views
# # ---------------------------------


# class LikeListCreateView(ListCreateAPIView):
#     """
#     Handles listing and creating Likes.
#     """
#     queryset = Likes.objects.select_related('user', 'post', 'comment').all()
#     serializer_class = LikeSerializer

#     @swagger_auto_schema(
#         operation_summary="List all likes",
#         operation_description="Retrieve a list of all likes. Each like includes details about the user and the associated post or comment.",
#         responses={200: LikeSerializer(many=True)}
#     )
#     def get(self, request, *args, **kwargs):
#         return super().get(request, *args, **kwargs)

#     @swagger_auto_schema(
#         operation_summary="Create a new like",
#         operation_description=(
#             "Create a new like for either a post or a comment. "
#             "Provide `post_id` to like a post or `comment_id` to like a comment."
#         ),
#         request_body=openapi.Schema(
#             type=openapi.TYPE_OBJECT,
#             properties={
#                 'user_id': openapi.Schema(type=openapi.TYPE_INTEGER, description="ID of the user liking the post or comment."),
#                 'post_id': openapi.Schema(type=openapi.TYPE_INTEGER, description="ID of the post to be liked (optional)."),
#                 'comment_id': openapi.Schema(type=openapi.TYPE_INTEGER, description="ID of the comment to be liked (optional)."),
#             },
#             required=['user_id']
#         ),
#         responses={201: LikeSerializer}
#     )
#     def post(self, request, *args, **kwargs):
#         return super().post(request, *args, **kwargs)


# class LikeDetailView(RetrieveUpdateDestroyAPIView):
#     """
#     Handles retrieving, updating, and deleting a single Like.
#     """
#     queryset = Likes.objects.select_related('user', 'post', 'comment').all()
#     serializer_class = LikeSerializer

#     @swagger_auto_schema(
#         operation_summary="Retrieve a specific like",
#         operation_description="Retrieve details of a specific like by its ID.",
#         responses={200: LikeSerializer}
#     )
#     def get(self, request, *args, **kwargs):
#         return super().get(request, *args, **kwargs)

#     @swagger_auto_schema(
#         operation_summary="Update a like",
#         operation_description="Update the details of an existing like (e.g., changing it from liking a post to a comment).",
#         request_body=openapi.Schema(
#             type=openapi.TYPE_OBJECT,
#             properties={
#                 'post_id': openapi.Schema(type=openapi.TYPE_INTEGER, description="ID of the post to be liked (optional)."),
#                 'comment_id': openapi.Schema(type=openapi.TYPE_INTEGER, description="ID of the comment to be liked (optional)."),
#             }
#         ),
#         responses={200: LikeSerializer}
#     )
#     def patch(self, request, *args, **kwargs):
#         return super().patch(request, *args, **kwargs)

#     @swagger_auto_schema(
#         operation_summary="Delete a specific like",
#         operation_description="Delete a like by its ID.",
#         responses={204: "Like deleted successfully."}
#     )
#     def delete(self, request, *args, **kwargs):
#         return super().delete(request, *args, **kwargs)


# # ---------------------------------
# # Collection folder Views
# # ---------------------------------


# class CollectionFolderListCreateView(ListCreateAPIView):
#     """
#     Handles listing and creating Collection Folders.
#     """
#     queryset = CollectionFolders.objects.select_related('user').all()
#     serializer_class = CollectionFolderSerializer

#     @swagger_auto_schema(
#         operation_summary="List all collection folders",
#         operation_description=(
#             "Retrieve a list of all collection folders. Each folder includes details about the user and the folder's creation time."
#         ),
#         responses={200: CollectionFolderSerializer(many=True)}
#     )
#     def get(self, request, *args, **kwargs):
#         return super().get(request, *args, **kwargs)

#     @swagger_auto_schema(
#         operation_summary="Create a new collection folder",
#         operation_description="Create a new collection folder for a user by providing the folder's name and the user's ID.",
#         request_body=openapi.Schema(
#             type=openapi.TYPE_OBJECT,
#             properties={
#                 "user_id": openapi.Schema(type=openapi.TYPE_INTEGER, description="ID of the user creating the folder."),
#                 "name": openapi.Schema(type=openapi.TYPE_STRING, description="Name of the new folder."),
#             },
#             required=["user_id", "name"]
#         ),
#         responses={201: CollectionFolderSerializer}
#     )
#     def post(self, request, *args, **kwargs):
#         return super().post(request, *args, **kwargs)


# class CollectionFolderDetailView(RetrieveUpdateDestroyAPIView):
#     """
#     Handles retrieving, updating, and deleting a single Collection Folder.
#     """
#     queryset = CollectionFolders.objects.select_related('user').all()
#     serializer_class = CollectionFolderSerializer

#     @swagger_auto_schema(
#         operation_summary="Retrieve a collection folder",
#         operation_description="Retrieve details of a specific collection folder by its ID, including the user and folder metadata.",
#         responses={200: CollectionFolderSerializer}
#     )
#     def get(self, request, *args, **kwargs):
#         return super().get(request, *args, **kwargs)

#     @swagger_auto_schema(
#         operation_summary="Update a collection folder",
#         operation_description="Update the name of an existing collection folder. The user ID cannot be updated.",
#         request_body=openapi.Schema(
#             type=openapi.TYPE_OBJECT,
#             properties={
#                 "name": openapi.Schema(type=openapi.TYPE_STRING, description="Updated name of the folder."),
#             },
#             required=["name"]
#         ),
#         responses={200: CollectionFolderSerializer}
#     )
#     def patch(self, request, *args, **kwargs):
#         return super().patch(request, *args, **kwargs)

#     @swagger_auto_schema(
#         operation_summary="Delete a collection folder",
#         operation_description="Delete a collection folder by its ID.",
#         responses={204: "Collection folder deleted successfully."}
#     )
#     def delete(self, request, *args, **kwargs):
#         return super().delete(request, *args, **kwargs)

# # ---------------------------------
# # Collection Views
# # ---------------------------------


# class CollectListCreateView(ListCreateAPIView):
#     """
#     Handles listing and creating Collects.
#     """
#     queryset = Collects.objects.select_related('user', 'post', 'folder').all()
#     serializer_class = CollectSerializer

#     @swagger_auto_schema(
#         operation_summary="List all collects",
#         operation_description=(
#             "Retrieve a list of all collects. Each collect includes details about the user, post, and associated folder."
#         ),
#         responses={200: CollectSerializer(many=True)}
#     )
#     def get(self, request, *args, **kwargs):
#         return super().get(request, *args, **kwargs)

#     @swagger_auto_schema(
#         operation_summary="Create a new collect",
#         operation_description=(
#             "Create a new collect to save a post into a folder. "
#             "Provide `user_id` and `post_id`, and optionally `folder_id` to associate the collect with a specific folder."
#         ),
#         request_body=openapi.Schema(
#             type=openapi.TYPE_OBJECT,
#             properties={
#                 "user_id": openapi.Schema(type=openapi.TYPE_INTEGER, description="ID of the user collecting the post."),
#                 "post_id": openapi.Schema(type=openapi.TYPE_INTEGER, description="ID of the post to be collected."),
#                 "folder_id": openapi.Schema(type=openapi.TYPE_INTEGER, description="ID of the folder (optional)."),
#             },
#             required=["user_id", "post_id"]
#         ),
#         responses={201: CollectSerializer}
#     )
#     def post(self, request, *args, **kwargs):
#         return super().post(request, *args, **kwargs)


# class CollectDetailView(RetrieveUpdateDestroyAPIView):
#     """
#     Handles retrieving, updating, and deleting a single Collect.
#     """
#     queryset = Collects.objects.select_related('user', 'post', 'folder').all()
#     serializer_class = CollectSerializer

#     @swagger_auto_schema(
#         operation_summary="Retrieve a collect",
#         operation_description="Retrieve details of a specific collect by its ID, including the associated user, post, and folder.",
#         responses={200: CollectSerializer}
#     )
#     def get(self, request, *args, **kwargs):
#         return super().get(request, *args, **kwargs)

#     @swagger_auto_schema(
#         operation_summary="Update a collect",
#         operation_description="Update a collect by changing the folder or associated post.",
#         request_body=openapi.Schema(
#             type=openapi.TYPE_OBJECT,
#             properties={
#                 "folder_id": openapi.Schema(type=openapi.TYPE_INTEGER, description="ID of the folder (optional)."),
#                 "post_id": openapi.Schema(type=openapi.TYPE_INTEGER, description="ID of the post to be collected."),
#             },
#         ),
#         responses={200: CollectSerializer}
#     )
#     def patch(self, request, *args, **kwargs):
#         return super().patch(request, *args, **kwargs)

#     @swagger_auto_schema(
#         operation_summary="Delete a collect",
#         operation_description="Delete a collect by its ID.",
#         responses={204: "Collect deleted successfully."}
#     )
#     def delete(self, request, *args, **kwargs):
#         return super().delete(request, *args, **kwargs)


# # ---------------------------------
# # Notification Views
# # ---------------------------------
# class NotificationListView(ListCreateAPIView):
#     """
#     Handles listing notifications for a user.
#     """
#     serializer_class = NotificationSerializer

#     @swagger_auto_schema(
#         operation_summary="List notifications for a user",
#         operation_description=(
#             "Retrieve a list of notifications for a specific user. You can optionally filter "
#             "by `is_read` (true/false) and `notification_type` (e.g., reply, mention, collection)."
#         ),
#         manual_parameters=[
#             openapi.Parameter(
#                 "user_id", openapi.IN_QUERY, description="ID of the recipient user", type=openapi.TYPE_INTEGER, required=True
#             ),
#             openapi.Parameter(
#                 "is_read", openapi.IN_QUERY, description="Filter by read status (true/false)", type=openapi.TYPE_BOOLEAN, required=False
#             ),
#             openapi.Parameter(
#                 "notification_type", openapi.IN_QUERY, description="Filter by notification type (e.g., reply, mention, collection)", type=openapi.TYPE_STRING, required=False
#             ),
#         ],
#         responses={200: NotificationSerializer(many=True)}
#     )
#     def get(self, request, *args, **kwargs):
#         return super().get(request, *args, **kwargs)

#     def get_queryset(self):
#         """
#         Filter notifications for the current user.
#         Optionally filter by `is_read` or `notification_type`.
#         """
#         user_id = self.request.query_params.get('user_id')
#         is_read = self.request.query_params.get('is_read')
#         notification_type = self.request.query_params.get('notification_type')

#         if not user_id:
#             return Notifications.objects.none()  # Return empty if user_id is not provided

#         queryset = Notifications.objects.filter(
#             recipient_id=user_id).order_by('-created_at')

#         if is_read is not None:
#             queryset = queryset.filter(is_read=is_read.lower() == 'true')

#         if notification_type:
#             queryset = queryset.filter(notification_type=notification_type)

#         return queryset


# class NotificationDetailView(RetrieveUpdateDestroyAPIView):
#     """
#     Handles retrieving, updating, or deleting a single notification.
#     """
#     queryset = Notifications.objects.select_related(
#         'recipient', 'sender', 'post', 'comment').all()
#     serializer_class = NotificationSerializer

#     @swagger_auto_schema(
#         operation_summary="Retrieve a notification",
#         operation_description="Retrieve details of a specific notification by its ID.",
#         responses={200: NotificationSerializer}
#     )
#     def get(self, request, *args, **kwargs):
#         return super().get(request, *args, **kwargs)

#     @swagger_auto_schema(
#         operation_summary="Update a notification",
#         operation_description="Update the fields of a notification (e.g., mark it as read).",
#         request_body=NotificationSerializer,
#         responses={200: NotificationSerializer}
#     )
#     def patch(self, request, *args, **kwargs):
#         return super().patch(request, *args, **kwargs)

#     @swagger_auto_schema(
#         operation_summary="Delete a notification",
#         operation_description="Delete a specific notification by its ID.",
#         responses={204: "Notification deleted successfully."}
#     )
#     def delete(self, request, *args, **kwargs):
#         return super().delete(request, *args, **kwargs)


# class MarkNotificationAsReadView(UpdateAPIView):
#     """
#     Marks a single notification as read.
#     """
#     queryset = Notifications.objects.all()
#     serializer_class = NotificationSerializer

#     @swagger_auto_schema(
#         operation_summary="Mark a notification as read",
#         operation_description="Update the `is_read` field of a specific notification to `true`.",
#         responses={
#             200: openapi.Response(
#                 description="Notification marked as read.",
#                 schema=openapi.Schema(
#                     type=openapi.TYPE_OBJECT,
#                     properties={
#                         "message": openapi.Schema(
#                             type=openapi.TYPE_STRING,
#                             description="Confirmation message"
#                         )
#                     }
#                 )
#             )
#         }
#     )
#     def patch(self, request, *args, **kwargs):
#         """
#         Update the `is_read` field for the notification.
#         """
#         notification = self.get_object()
#         notification.is_read = True
#         notification.save()

#         return Response(
#             {"message": f"Notification {notification.id} marked as read."},
#             status=status.HTTP_200_OK
#         )
