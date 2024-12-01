from rest_framework.permissions import AllowAny, IsAuthenticated
from drf_yasg import openapi
from drf_yasg.utils import swagger_auto_schema

# Serializer
from ..serializers import PostSerializer

# Authentication lib
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from rest_framework.views import APIView
from rest_framework.generics import RetrieveAPIView
from rest_framework_simplejwt.exceptions import InvalidToken, TokenError
from rest_framework_simplejwt.tokens import AccessToken
from rest_framework.generics import ListCreateAPIView, RetrieveUpdateDestroyAPIView

# Always import new models
from ..models import PostImages, Posts, Likes, Comments, Collects, CollectionFolders

from rest_framework.views import APIView
from rest_framework.parsers import MultiPartParser, FormParser
from rest_framework.response import Response
from rest_framework import status
from rest_framework.permissions import IsAuthenticated


class PostListCreateView(APIView):
    parser_classes = (MultiPartParser, FormParser)
    permission_classes = [IsAuthenticated]

    @swagger_auto_schema(
        operation_summary="Create a new post",
        operation_description="Create a new post with title, content, images, location, and other metadata",
        manual_parameters=[
            openapi.Parameter(
                'title',
                openapi.IN_FORM,
                description="Post title",
                type=openapi.TYPE_STRING,
                required=True
            ),
            openapi.Parameter(
                'content',
                openapi.IN_FORM,
                description="Post content",
                type=openapi.TYPE_STRING,
                required=True
            ),
            openapi.Parameter(
                'image',
                openapi.IN_FORM,
                description="Post images (multiple files allowed)",
                type=openapi.TYPE_FILE,
                required=False
            ),
            openapi.Parameter(
                'location',
                openapi.IN_FORM,
                description="Post location",
                type=openapi.TYPE_STRING,
                required=True
            ),
            openapi.Parameter(
                'status',
                openapi.IN_FORM,
                description="Post status (published/draft)",
                type=openapi.TYPE_STRING,
                default='published',
                required=False
            ),
            openapi.Parameter(
                'visibility',
                openapi.IN_FORM,
                description="Post visibility (public/private)",
                type=openapi.TYPE_STRING,
                default='public',
                required=False
            ),
        ],
        responses={
            201: PostSerializer,
            400: "Bad Request",
            401: "Unauthorized"
        }
    )
    def post(self, request):
        try:
            # Check if location is provided
            location = request.data.get('location')
            if not location:
                return Response(
                    {'error': 'Location is required'},
                    status=status.HTTP_400_BAD_REQUEST
                )

            # Create the post with location
            post = Posts.objects.create(
                user=request.user,
                title=request.data.get('title'),
                content=request.data.get('content'),
                location=location,  # Add location field
                status=request.data.get('status', 'published'),
                visibility=request.data.get('visibility', 'public')
            )

            # Handle multiple images
            images = request.FILES.getlist('image')
            for image in images:
                PostImages.objects.create(
                    post=post,
                    image=image
                )

            # Return the created post with all its data
            serializer = PostSerializer(post, context={'request': request})
            return Response(serializer.data, status=status.HTTP_201_CREATED)

        except Exception as e:
            return Response(
                {'error': str(e)},
                status=status.HTTP_400_BAD_REQUEST
            )

    @swagger_auto_schema(
        operation_summary="List all posts",
        operation_description="Retrieve a list of all posts ordered by creation date",
        responses={
            200: PostSerializer(many=True),
            401: "Unauthorized"
        }
    )
    def get(self, request):
        posts = Posts.objects.all().order_by('-created_at')
        serializer = PostSerializer(
            posts, many=True, context={'request': request})
        return Response(serializer.data)


class PostDetailView(RetrieveUpdateDestroyAPIView):
    queryset = Posts.objects.select_related('user').all()
    serializer_class = PostSerializer

    # Require authentication for all methods in this class
    permission_classes = [IsAuthenticated]

    def get_serializer_context(self):
        """Pass request context for SerializerMethodField to work."""
        return {'request': self.request}

    @swagger_auto_schema(
        operation_summary="Retrieve a post",
        operation_description="Retrieve details of a specific post by ID, including its associated user and comments.",
        responses={200: PostSerializer},
    )
    def get(self, request, *args, **kwargs):
        return super().get(request, *args, **kwargs)

    @swagger_auto_schema(
        operation_summary="Update a post",
        operation_description="Update a specific post's title, content, status, or visibility.",
        request_body=PostSerializer,
        responses={200: PostSerializer},
    )
    def patch(self, request, *args, **kwargs):
        return super().patch(request, *args, **kwargs)

    @swagger_auto_schema(
        operation_summary="Delete a post",
        operation_description="Delete a specific post by ID.",
        responses={204: "Post deleted successfully."},
    )
    def delete(self, request, *args, **kwargs):
        return super().delete(request, *args, **kwargs)


class ToggleLikeView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request, *args, **kwargs):
        user = request.user
        post_id = kwargs.get('post_id')
        comment_id = kwargs.get('comment_id')

        if post_id and comment_id:
            return Response({"error": "Provide either post_id or comment_id, not both."}, status=400)

        if post_id:
            try:
                post = Posts.objects.get(id=post_id)
                like, created = Likes.objects.get_or_create(
                    user=user, post=post)
                if not created:
                    like.delete()  # Unlike
                    is_liked = False
                else:
                    is_liked = True
                likes_count = post.post_likes.count()
            except Posts.DoesNotExist:
                return Response({"error": "Post not found"}, status=404)

        elif comment_id:
            try:
                comment = Comments.objects.get(id=comment_id)
                like, created = Likes.objects.get_or_create(
                    user=user, comment=comment)
                if not created:
                    like.delete()  # Unlike
                    is_liked = False
                else:
                    is_liked = True
                likes_count = comment.comment_likes.count()
            except Comments.DoesNotExist:
                return Response({"error": "Comment not found"}, status=404)
        else:
            return Response({"error": "Invalid request, provide post_id or comment_id"}, status=400)

        return Response({'is_liked': is_liked, 'likes_count': likes_count}, status=200)


class ToggleSaveView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request, post_id):
        user = request.user

        # Safely access request data
        folder_name = request.data.get('folder_name') if hasattr(
            request, 'data') and request.data else 'Default'

        try:
            # Check if the post exists
            post = Posts.objects.get(id=post_id)
        except Posts.DoesNotExist:
            return Response({"error": "Post not found"}, status=status.HTTP_404_NOT_FOUND)

        # Get or create a folder for the user
        folder, _ = CollectionFolders.objects.get_or_create(
            user=user, name=folder_name)

        # Check if the post is already saved in this folder
        collect = Collects.objects.filter(
            user=user, post=post, folder=folder).first()

        if collect:
            # If the collect already exists, delete it (unsave the post)
            collect.delete()
            is_saved = False
        else:
            # If the collect doesn't exist, create it (save the post)
            Collects.objects.create(user=user, post=post, folder=folder)
            is_saved = True

        # Count the total number of users who have saved this post
        saves_count = Collects.objects.filter(post=post).count()

        return Response(
            {"is_saved": is_saved, "saves_count": saves_count},
            status=status.HTTP_200_OK
        )
