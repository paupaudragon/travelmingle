from celery import shared_task

# 1. First, fix the upload_post_image task in tasks.py
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

        # Generate a clean filename using only alphanumeric characters
        clean_filename = ''.join(c for c in str(uuid.uuid4()) if c.isalnum())
        object_key = f"media/postImages/{clean_filename}.jpg"
        print(f"🚀 Uploading to S3: {object_key}")
        
        # Configure S3 client with proper settings
        s3 = boto3.client(
            's3',
            region_name='us-east-1',  # Set your actual region
            config=boto3.session.Config(signature_version='s3v4')
        )
        
        # Set proper content type and ACL
        s3.upload_fileobj(
            buffer, 
            'travelmingle-media', 
            object_key,
            ExtraArgs={
                'ContentType': 'image/jpeg',
                'ACL': 'public-read'  # Make sure bucket permissions allow this
            }
        )
        print("✅ S3 upload complete")

        from api.models import PostImages
        PostImages.objects.create(post_id=post_id, image=object_key)
        print(f"✅ PostImages saved for post {post_id}")

    except Exception as e:
        print(f"❌ upload_post_image failed: {str(e)}")

# 2. Apply the same fix to upload_comment_image
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

        # Generate a clean filename using only alphanumeric characters
        clean_filename = ''.join(c for c in str(uuid.uuid4()) if c.isalnum())
        object_key = f"media/commentImages/{clean_filename}.jpg"

        # Configure S3 client with proper settings
        s3 = boto3.client(
            's3',
            region_name='us-east-1',  # Set your actual region
            config=boto3.session.Config(signature_version='s3v4')
        )
        
        # Set proper content type and ACL
        s3.upload_fileobj(
            buffer, 
            'travelmingle-media', 
            object_key,
            ExtraArgs={
                'ContentType': 'image/jpeg',
                'ACL': 'public-read'  # Make sure bucket permissions allow this
            }
        )

        # Update comment with image key
        comment = Comments.objects.get(id=comment_id)
        comment.comment_image = object_key
        comment.save()
        print(f"✅ S3 upload + comment update complete: {object_key}")
    except Exception as e:
        print(f"❌ Failed to upload comment image: {str(e)}")