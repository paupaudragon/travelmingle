import os
from django.core.management.base import BaseCommand
from django.conf import settings
from django.core.files.storage import default_storage
from api.models import Users, PostImages, Comments
import boto3
from botocore.exceptions import ClientError

class Command(BaseCommand):
    help = 'Migrates existing media files to S3'

    def handle(self, *args, **kwargs):
        if not settings.USE_S3:
            self.stdout.write(self.style.ERROR('S3 storage is not enabled. Please set USE_S3=True in your .env file.'))
            return

        self.stdout.write(self.style.SUCCESS('Starting migration of media files to S3...'))
        
        # Connect to S3
        s3_client = boto3.client(
            's3',
            aws_access_key_id=settings.AWS_ACCESS_KEY_ID,
            aws_secret_access_key=settings.AWS_SECRET_ACCESS_KEY,
        )
        
        # Migrate profile pictures
        self.migrate_profile_pictures(s3_client)
        
        # Migrate post images
        self.migrate_post_images(s3_client)
        
        # Migrate comment images
        self.migrate_comment_images(s3_client)
        
        self.stdout.write(self.style.SUCCESS('Migration completed successfully!'))
    
    def migrate_profile_pictures(self, s3_client):
        self.stdout.write(self.style.SUCCESS('Migrating profile pictures...'))
        for user in Users.objects.all():
            if user.profile_picture and not user.profile_picture.name.startswith('http'):
                try:
                    local_path = os.path.join(settings.MEDIA_ROOT, user.profile_picture.name)
                    if os.path.exists(local_path):
                        s3_path = f"{settings.AWS_LOCATION}/{user.profile_picture.name}"
                        
                        # Check if file already exists in S3
                        try:
                            s3_client.head_object(Bucket=settings.AWS_STORAGE_BUCKET_NAME, Key=s3_path)
                            self.stdout.write(f"File already exists in S3: {s3_path}")
                        except ClientError:
                            # Upload file to S3
                            with open(local_path, 'rb') as file:
                                s3_client.upload_fileobj(
                                    file,
                                    settings.AWS_STORAGE_BUCKET_NAME,
                                    s3_path,
                                    ExtraArgs={'ACL': 'public-read'}
                                )
                            self.stdout.write(f"Uploaded {user.profile_picture.name} to S3")
                except Exception as e:
                    self.stdout.write(self.style.ERROR(f"Error migrating {user.profile_picture.name}: {e}"))
    
    def migrate_post_images(self, s3_client):
        self.stdout.write(self.style.SUCCESS('Migrating post images...'))
        for image in PostImages.objects.all():
            if image.image and not image.image.name.startswith('http'):
                try:
                    local_path = os.path.join(settings.MEDIA_ROOT, image.image.name)
                    if os.path.exists(local_path):
                        s3_path = f"{settings.AWS_LOCATION}/{image.image.name}"
                        
                        # Check if file already exists in S3
                        try:
                            s3_client.head_object(Bucket=settings.AWS_STORAGE_BUCKET_NAME, Key=s3_path)
                            self.stdout.write(f"File already exists in S3: {s3_path}")
                        except ClientError:
                            # Upload file to S3
                            with open(local_path, 'rb') as file:
                                s3_client.upload_fileobj(
                                    file,
                                    settings.AWS_STORAGE_BUCKET_NAME,
                                    s3_path,
                                    ExtraArgs={'ACL': 'public-read'}
                                )
                            self.stdout.write(f"Uploaded {image.image.name} to S3")
                except Exception as e:
                    self.stdout.write(self.style.ERROR(f"Error migrating {image.image.name}: {e}"))
    
    def migrate_comment_images(self, s3_client):
        self.stdout.write(self.style.SUCCESS('Migrating comment images...'))
        for comment in Comments.objects.all():
            if comment.comment_image and not comment.comment_image.name.startswith('http'):
                try:
                    local_path = os.path.join(settings.MEDIA_ROOT, comment.comment_image.name)
                    if os.path.exists(local_path):
                        s3_path = f"{settings.AWS_LOCATION}/{comment.comment_image.name}"
                        
                        # Check if file already exists in S3
                        try:
                            s3_client.head_object(Bucket=settings.AWS_STORAGE_BUCKET_NAME, Key=s3_path)
                            self.stdout.write(f"File already exists in S3: {s3_path}")
                        except ClientError:
                            # Upload file to S3
                            with open(local_path, 'rb') as file:
                                s3_client.upload_fileobj(
                                    file,
                                    settings.AWS_STORAGE_BUCKET_NAME,
                                    s3_path,
                                    ExtraArgs={'ACL': 'public-read'}
                                )
                            self.stdout.write(f"Uploaded {comment.comment_image.name} to S3")
                except Exception as e:
                    self.stdout.write(self.style.ERROR(f"Error migrating {comment.comment_image.name}: {e}"))