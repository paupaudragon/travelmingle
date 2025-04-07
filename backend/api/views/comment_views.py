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

from PIL import Image
from io import BytesIO
from django.core.files.uploadedfile import InMemoryUploadedFile
import sys

import boto3
from botocore.exceptions import ClientError

from ..tasks import upload_comment_image

# Create a logger instance
logger = logging.getLogger(__name__)


class CommentListCreateView(ListCreateAPIView):
    """
    Handles listing all comments and creating new comments.
    """
    queryset = Comments.objects.select_related('user', 'post').all()
    serializer_class = CommentSerializer
    parser_classes = (JSONParser, MultiPartParser, FormParser)

    

    @staticmethod
    def resize_and_compress_image(image_file, max_width=1024, quality=75):
        """
        Resize and compress an uploaded image using Pillow.
        Returns an InMemoryUploadedFile ready for upload.
        """
        img = Image.open(image_file)

        # Convert to RGB to avoid issues with PNG/Transparency
        if img.mode in ("RGBA", "P"):
            img = img.convert("RGB")

        # Resize if too wide
        if img.width > max_width:
            ratio = max_width / float(img.width)
            new_height = int((float(img.height) * float(ratio)))
            img = img.resize((max_width, new_height), Image.Resampling.LANCZOS)

        # Save to BytesIO buffer
        buffer = BytesIO()
        img.save(buffer, format='JPEG', quality=quality)
        buffer.seek(0)

        return InMemoryUploadedFile(
            buffer,
            None,
            f"{image_file.name.split('.')[0]}.jpg",
            'image/jpeg',
            sys.getsizeof(buffer),
            None
        )

    @staticmethod
    def upload_comment_image_to_s3(file_obj, bucket_name, object_key):
        """
        Uploads a compressed image file to S3.
        Returns the S3 object key or full URL if successful, otherwise None.
        """
        try:
            s3_client = boto3.client('s3')
            s3_client.upload_fileobj(file_obj, bucket_name, object_key)
            print(f"✅ Uploaded to S3: {object_key}")
            return object_key  # or return full URL: f"https://{bucket_name}.s3.amazonaws.com/{object_key}"
        except ClientError as e:
            print(f"❌ S3 Upload Error: {e}")
            return None



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

        logger.debug(f"Received request with content type: {
                     request.content_type}")
        print(f"Received request with content type: {request.content_type}")

        # Check Content-Type
        if request.content_type.startswith('application/json'):
            # JSON payload (text-only comment)
            return super().post(request, *args, **kwargs)

        elif request.content_type.startswith('multipart/form-data'):
            image = request.FILES.get('comment_image')

            # Pass a flag to help validation know an image exists
            serializer = self.get_serializer(
                data=request.data,
                context={'request': request, 'has_image': bool(image)}
            )

            if serializer.is_valid():
                comment = serializer.save()

                # Send image to Celery after comment is saved
                if image:
                    upload_comment_image.delay(
                        comment.id,
                        image.read(),
                        image.name
                    )

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
        operation_description="Delete a comment. Users can delete their own comments, admins can delete any comment.",
        responses={
            204: "Comment deleted successfully.",
            403: "Permission denied - user is not the owner or admin.",
            404: "Comment not found."
        },
    )
    def delete(self, request, *args, **kwargs):
        instance = self.get_object()
        if request.user == instance.user or request.user.profile.role == 'user':
            return super().delete(request, *args, **kwargs)
        return Response(
            {"detail": "You do not have permission to delete this comment."},
            status=status.HTTP_403_FORBIDDEN
        )


class PostCommentsView(ListAPIView):
    serializer_class = CommentSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        post_id = self.kwargs['post_id']
        return Comments.objects.filter(post_id=post_id, reply_to=None)
