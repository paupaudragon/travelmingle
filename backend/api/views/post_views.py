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
from ..models import PostImages, Posts, Likes, Comments

from rest_framework.views import APIView
from rest_framework.parsers import MultiPartParser, FormParser
from rest_framework.response import Response
from rest_framework import status
from rest_framework.permissions import IsAuthenticated


class PostListCreateView(APIView):
    parser_classes = (MultiPartParser, FormParser)
    permission_classes = [IsAuthenticated]

    def post(self, request):
        try:
            # Create the post first
            post = Posts.objects.create(
                user=request.user,
                title=request.data.get('title'),
                content=request.data.get('content'),
                status=request.data.get('status', 'published'),
                visibility=request.data.get('visibility', 'public')
            )

            # Handle multiple images
            images = request.FILES.getlist('image')
            for image in images:
                PostImages.objects.create(
                    post=post,
                    image=image  # This will automatically save to postImages/ directory
                )

            # Return the created post with all its data
            serializer = PostSerializer(post, context={'request': request})
            return Response(serializer.data, status=status.HTTP_201_CREATED)

        except Exception as e:
            return Response(
                {'error': str(e)},
                status=status.HTTP_400_BAD_REQUEST
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
