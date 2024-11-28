from drf_yasg import openapi
from drf_yasg.utils import swagger_auto_schema
from rest_framework.generics import ListCreateAPIView, RetrieveUpdateDestroyAPIView, ListAPIView
from ..models import Comments
from ..serializers import CommentSerializer
from rest_framework.permissions import IsAuthenticated

from rest_framework.parsers import MultiPartParser, FormParser, JSONParser
from rest_framework.response import Response
from rest_framework import status

import logging

# Create a logger instance
logger = logging.getLogger(__name__)

class CommentListCreateView(ListCreateAPIView):
    """
    Handles listing all comments and creating new comments.
    """
    queryset = Comments.objects.select_related('user', 'post').all()
    serializer_class = CommentSerializer
    parser_classes = (JSONParser, MultiPartParser, FormParser)

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

        logger.debug(f"Received request with content type: {request.content_type}")
        print(f"Received request with content type: {request.content_type}")  # For immediate console output

        # Check Content-Type
        if request.content_type.startswith('application/json'):
            # JSON payload (text-only comment)
            return super().post(request, *args, **kwargs)
        elif request.content_type.startswith('multipart/form-data'):
            # Multipart payload (image or mixed content)
            serializer = self.get_serializer(data=request.data, context={'request': request})
            if serializer.is_valid():
                serializer.save()
                return Response(serializer.data, status=status.HTTP_201_CREATED)
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
        else:
            # Log unrecognized Content-Type
            return Response(
                {"detail": f"Unsupported media type: {request.content_type}"},
                status=status.HTTP_415_UNSUPPORTED_MEDIA_TYPE,
            )
        


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

class PostCommentsView(ListAPIView):
    serializer_class = CommentSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        post_id = self.kwargs['post_id']
        return Comments.objects.filter(post_id=post_id, reply_to=None)        
