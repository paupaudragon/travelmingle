from drf_yasg import openapi
from drf_yasg.utils import swagger_auto_schema
from rest_framework.generics import ListCreateAPIView, RetrieveUpdateDestroyAPIView
from ..models import Comments
from ..serializers import CommentSerializer


class CommentListCreateView(ListCreateAPIView):
    """
    Handles listing all comments and creating new comments.
    """
    queryset = Comments.objects.select_related('user', 'post').all()
    serializer_class = CommentSerializer

    @swagger_auto_schema(
        operation_summary="List all comments",
        operation_description="Retrieve a list of all comments, including user details and associated posts.",
        responses={200: CommentSerializer(many=True)}
    )
    def get(self, request, *args, **kwargs):
        return super().get(request, *args, **kwargs)

    @swagger_auto_schema(
        operation_summary="Create a new comment",
        operation_description="Create a new comment for a post or as a reply to another comment. "
        "Provide `post_id` to associate the comment with a post, and optionally "
        "provide `reply_to` to associate the comment as a reply to another comment.",
        request_body=CommentSerializer,
        responses={201: CommentSerializer}
    )
    def post(self, request, *args, **kwargs):
        return super().post(request, *args, **kwargs)


class CommentDetailView(RetrieveUpdateDestroyAPIView):
    """
    Handles retrieving, updating, and deleting a specific comment.
    """
    queryset = Comments.objects.select_related('user', 'post').all()
    serializer_class = CommentSerializer

    @swagger_auto_schema(
        operation_summary="Retrieve a comment",
        operation_description="Retrieve details of a specific comment by its ID.",
        responses={200: CommentSerializer}
    )
    def get(self, request, *args, **kwargs):
        return super().get(request, *args, **kwargs)

    @swagger_auto_schema(
        operation_summary="Update a comment",
        operation_description="Update a comment's content or parent comment (reply_to).",
        request_body=CommentSerializer,
        responses={200: CommentSerializer}
    )
    def patch(self, request, *args, **kwargs):
        return super().patch(request, *args, **kwargs)

    @swagger_auto_schema(
        operation_summary="Delete a comment",
        operation_description="Delete a comment by its ID.",
        responses={204: "Comment deleted successfully."}
    )
    def delete(self, request, *args, **kwargs):
        return super().delete(request, *args, **kwargs)
