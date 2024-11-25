from drf_yasg import openapi
from drf_yasg.utils import swagger_auto_schema
from rest_framework.generics import ListCreateAPIView, RetrieveUpdateDestroyAPIView
from ..models import Likes
from ..serializers import LikeSerializer


class LikeListCreateView(ListCreateAPIView):
    """
    Handles listing and creating Likes.
    """
    queryset = Likes.objects.select_related('user', 'post', 'comment').all()
    serializer_class = LikeSerializer

    @swagger_auto_schema(
        operation_summary="List all likes",
        operation_description="Retrieve a list of all likes. Each like includes details about the user and the associated post or comment.",
        responses={200: LikeSerializer(many=True)}
    )
    def get(self, request, *args, **kwargs):
        return super().get(request, *args, **kwargs)

    @swagger_auto_schema(
        operation_summary="Create a new like",
        operation_description=(
            "Create a new like for either a post or a comment. "
            "Provide `post_id` to like a post or `comment_id` to like a comment."
        ),
        request_body=openapi.Schema(
            type=openapi.TYPE_OBJECT,
            properties={
                'user_id': openapi.Schema(type=openapi.TYPE_INTEGER, description="ID of the user liking the post or comment."),
                'post_id': openapi.Schema(type=openapi.TYPE_INTEGER, description="ID of the post to be liked (optional)."),
                'comment_id': openapi.Schema(type=openapi.TYPE_INTEGER, description="ID of the comment to be liked (optional)."),
            },
            required=['user_id']
        ),
        responses={201: LikeSerializer}
    )
    def post(self, request, *args, **kwargs):
        return super().post(request, *args, **kwargs)


class LikeDetailView(RetrieveUpdateDestroyAPIView):
    """
    Handles retrieving, updating, and deleting a single Like.
    """
    queryset = Likes.objects.select_related('user', 'post', 'comment').all()
    serializer_class = LikeSerializer

    @swagger_auto_schema(
        operation_summary="Retrieve a specific like",
        operation_description="Retrieve details of a specific like by its ID.",
        responses={200: LikeSerializer}
    )
    def get(self, request, *args, **kwargs):
        return super().get(request, *args, **kwargs)

    @swagger_auto_schema(
        operation_summary="Update a like",
        operation_description="Update the details of an existing like (e.g., changing it from liking a post to a comment).",
        request_body=openapi.Schema(
            type=openapi.TYPE_OBJECT,
            properties={
                'post_id': openapi.Schema(type=openapi.TYPE_INTEGER, description="ID of the post to be liked (optional)."),
                'comment_id': openapi.Schema(type=openapi.TYPE_INTEGER, description="ID of the comment to be liked (optional)."),
            }
        ),
        responses={200: LikeSerializer}
    )
    def patch(self, request, *args, **kwargs):
        return super().patch(request, *args, **kwargs)

    @swagger_auto_schema(
        operation_summary="Delete a specific like",
        operation_description="Delete a like by its ID.",
        responses={204: "Like deleted successfully."}
    )
    def delete(self, request, *args, **kwargs):
        return super().delete(request, *args, **kwargs)
