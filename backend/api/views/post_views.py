from rest_framework.permissions import AllowAny, IsAuthenticated
from drf_yasg import openapi
from drf_yasg.utils import swagger_auto_schema
from rest_framework.generics import ListCreateAPIView, RetrieveUpdateDestroyAPIView
from ..models import Posts
from ..serializers import PostSerializer


class PostListCreateView(ListCreateAPIView):
    queryset = Posts.objects.select_related('user').all()
    serializer_class = PostSerializer

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
    def get(self, request, *args, **kwargs):
        return super().get(request, *args, **kwargs)

    @swagger_auto_schema(
        operation_summary="Create a new post",
        operation_description="Create a new post by providing the user ID, title, content, and optional visibility or status.",
        request_body=PostSerializer,
        responses={201: PostSerializer},
    )
    def post(self, request, *args, **kwargs):
        return super().post(request, *args, **kwargs)


class PostDetailView(RetrieveUpdateDestroyAPIView):
    queryset = Posts.objects.select_related('user').all()
    serializer_class = PostSerializer

    # Require authentication for all methods in this class
    permission_classes = [IsAuthenticated]

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
