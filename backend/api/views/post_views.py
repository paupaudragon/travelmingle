from rest_framework.permissions import AllowAny, IsAuthenticated
from drf_yasg import openapi
from drf_yasg.utils import swagger_auto_schema

#Serializer
from ..serializers import PostSerializer

#Authentication lib
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from rest_framework.views import APIView
from rest_framework.generics import RetrieveAPIView
from rest_framework_simplejwt.exceptions import InvalidToken, TokenError
from rest_framework_simplejwt.tokens import AccessToken
from rest_framework.generics import ListCreateAPIView, RetrieveUpdateDestroyAPIView

#Always import new models
from ..models import Posts, Likes, Comments

class PostListCreateView(ListCreateAPIView):
    queryset = Posts.objects.select_related('user').all()
    serializer_class = PostSerializer

    def get_serializer_context(self):
        """Pass request context for SerializerMethodField to work."""
        return {'request': self.request}

    def get_permissions(self):
        """
        Set permissions dynamically: AllowAny for GET and IsAuthenticated for POST.
        """
        if self.request.method == 'GET':
            return [AllowAny()]
        return [IsAuthenticated()]

    @swagger_auto_schema(
        operation_summary="List all posts",
        operation_description="Retrieve a list of all posts with their associated user details.",
        responses={200: PostSerializer(many=True)},
    )
    # def get(self, request, *args, **kwargs):
    #     return super().get(request, *args, **kwargs)

    def get(self, request, *args, **kwargs):
        token = request.headers.get("Authorization", "").split("Bearer ")[-1]
        try:
            decoded = AccessToken(token)
            print("Decoded Token:", decoded)
        except TokenError as e:
            print("Token Error:", e)
        return super().get(request, *args, **kwargs)

    @swagger_auto_schema(
        operation_summary="Create a new post",
        operation_description="Create a new post by providing the user ID, title, content, and optional visibility or status.",
        request_body=PostSerializer,
        responses={201: PostSerializer},
    )
    def post(self, request, *args, **kwargs):
        return super().post(request, *args, **kwargs)

    def perform_create(self, serializer):
        # Automatically associate the logged-in user with the post
        serializer.save(user=self.request.user)   


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
                like, created = Likes.objects.get_or_create(user=user, post=post)
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
                like, created = Likes.objects.get_or_create(user=user, comment=comment)
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



