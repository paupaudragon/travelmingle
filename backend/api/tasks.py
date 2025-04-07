from celery import shared_task
import boto3
from botocore.exceptions import ClientError
from PIL import Image
from io import BytesIO
import uuid
import sys
from django.core.files.uploadedfile import InMemoryUploadedFile
from .models import Comments

@shared_task
def upload_comment_image(comment_id, image_bytes, image_name):
    print(f"🎯 Background upload for comment {comment_id}")

    try:
        # Compress image from bytes
        img = Image.open(BytesIO(image_bytes))
        if img.mode in ("RGBA", "P"):
            img = img.convert("RGB")

        if img.width > 1024:
            ratio = 1024 / float(img.width)
            new_height = int((float(img.height) * float(ratio)))
            img = img.resize((1024, new_height), Image.Resampling.LANCZOS)

        buffer = BytesIO()
        img.save(buffer, format='JPEG', quality=75)
        buffer.seek(0)

        object_key = f"media/commentImages/{uuid.uuid4()}.jpg"

        s3 = boto3.client('s3')
        s3.upload_fileobj(buffer, 'travelmingle-media', object_key)

        # Update comment with image key
        comment = Comments.objects.get(id=comment_id)
        comment.comment_image = object_key
        comment.save()
        print(f"✅ S3 upload + comment update complete: {object_key}")
    except Exception as e:
        print(f"❌ Failed to upload comment image: {str(e)}")

@shared_task
def upload_post_image(post_id, image_bytes, image_name, is_child=False):
    print(f"📤 Starting upload_post_image for post {post_id}")

    try:
        print("🔧 Opening image...")
        img = Image.open(BytesIO(image_bytes))
        if img.mode in ("RGBA", "P"):
            img = img.convert("RGB")

        if img.width > 1024:
            ratio = 1024 / float(img.width)
            new_height = int(float(img.height) * ratio)
            img = img.resize((1024, new_height), Image.Resampling.LANCZOS)

        buffer = BytesIO()
        img.save(buffer, format='JPEG', quality=75)
        buffer.seek(0)

        object_key = f"media/postImages/{uuid.uuid4()}.jpg"
        print(f"🚀 Uploading to S3: {object_key}")
        s3 = boto3.client('s3')
        s3.upload_fileobj(buffer, 'travelmingle-media', object_key)
        print("✅ S3 upload complete")

        from api.models import PostImages
        PostImages.objects.create(post_id=post_id, image=object_key)
        print(f"✅ PostImages saved for post {post_id}")

    except Exception as e:
        print(f"❌ upload_post_image failed: {str(e)}")
