from django.core.files.storage import FileSystemStorage
from django.core.files.base import ContentFile
from PIL import Image, ImageOps
import io
import os
import uuid

class MediaStorage(FileSystemStorage):
    """
    Custom storage backend that optimizes images before saving them.
    This implementation properly handles Django's file upload process
    while applying optimization techniques to images.
    """
    location = 'media/'
    file_overwrite = False
    
    def _save(self, name, content):
        """
        Override the _save method to optimize images before storage.
        Args:
            name: The name of the file
            content: The file content (an UploadedFile or similar object)
        Returns:
            The saved file name
        """
        # Check if the file is an image
        if name.lower().endswith(('.png', '.jpg', '.jpeg')):
            try:
                # Open the image
                img = Image.open(content)
                
                # Automatically orient the image correctly
                img = ImageOps.exif_transpose(img)
                
                # Calculate new dimensions while maintaining aspect ratio
                max_size = (1200, 1200)
                img.thumbnail(max_size, Image.Resampling.LANCZOS)
                
                # Create output buffer
                output = io.BytesIO()
                
                # Generate a unique filename to prevent cache issues
                filename, ext = os.path.splitext(name)
                unique_name = f"{filename}_{uuid.uuid4().hex[:8]}{ext}"
                
                # Apply format-specific optimizations
                if name.lower().endswith('.png'):
                    # For PNG files, optimize and reduce colors where possible
                    img = img.convert('RGBA')
                    img.save(output, format='PNG', optimize=True)
                else:
                    # For JPEG files, use quality reduction and optimization
                    # Quality 85 provides excellent visual results with smaller file size
                    img = img.convert('RGB')
                    img.save(output, format='JPEG', quality=85, optimize=True)
                
                # Convert BytesIO to ContentFile which has the required chunks() method
                content = ContentFile(output.getvalue())
                name = unique_name
                
                print(f"✅ Image optimized: {name}")
                
            except Exception as e:
                # Log the error but continue with original file if something goes wrong
                print(f"❌ Error processing image: {e}")
                if hasattr(content, 'seek') and callable(content.seek):
                    content.seek(0)
        
        # Continue with the standard save
        return super()._save(name, content)