from storages.backends.s3boto3 import S3Boto3Storage
from django.core.files.base import ContentFile
from PIL import Image, ImageOps
import io
import uuid

class MediaStorage(S3Boto3Storage):
    location = 'media'
    file_overwrite = False

    def _save(self, name, content):
        """
        Process and optimize images before saving to S3.
        Also generates a thumbnail version.
        """
        # Check if the file is an image
        if name.lower().endswith(('.png', '.jpg', '.jpeg')):
            try:
                # Open the image
                img = Image.open(content)

                # Auto-orient based on EXIF
                img = ImageOps.exif_transpose(img)

                # Resize: Max 1200x1200
                img.thumbnail((1200, 1200), Image.LANCZOS)

                # Create unique filename
                filename, ext = name.rsplit('.', 1)
                unique_name = f"{filename}_{uuid.uuid4().hex[:8]}.{ext}"

                # Save optimized image to buffer
                output = io.BytesIO()
                if ext.lower() == 'png':
                    img.save(output, format='PNG', optimize=True)
                    content_type = 'image/png'
                else:
                    img.save(output, format='JPEG', quality=85, optimize=True)
                    content_type = 'image/jpeg'

                output.seek(0)
                content = ContentFile(output.getvalue())

                # Save thumbnail
                self._save_thumbnail(unique_name, img, ext)

                name = unique_name
                print(f"✅ Image optimized and uploaded: {name}")

            except Exception as e:
                print(f"❌ Error processing image: {e}")
                if hasattr(content, 'seek'):
                    content.seek(0)

        # Save original or processed file
        return super()._save(name, content)

    def _save_thumbnail(self, name, img, ext):
        """Create and upload thumbnail version."""
        try:
            thumb = img.copy()
            thumb.thumbnail((400, 400), Image.LANCZOS)

            thumb_output = io.BytesIO()
            if ext.lower() == 'png':
                thumb.save(thumb_output, format='PNG', optimize=True)
                content_type = 'image/png'
            else:
                thumb.save(thumb_output, format='JPEG', quality=75, optimize=True)
                content_type = 'image/jpeg'

            thumb_output.seek(0)

            self.connection.meta.client.put_object(
                Bucket=self.bucket_name,
                Key=f"{self.location}/thumb_{name}",
                Body=thumb_output.getvalue(),
                ContentType=content_type,
            )

            print(f"✅ Thumbnail saved: thumb_{name}")

        except Exception as e:
            print(f"❌ Error saving thumbnail: {e}")
