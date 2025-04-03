class MediaStorage(S3Boto3Storage):
    location = 'media'
    file_overwrite = True
    
    def _save(self, name, content):
        """
        Process and optimize images before saving to S3.
        Also generates a thumbnail version.
        """
        print(f"🔍 Starting to save {name} to S3")
        
        # Check if the file is an image
        if name.lower().endswith(('.png', '.jpg', '.jpeg')):
            try:
                print(f"📸 Processing image {name}")
                # Open the image
                img = Image.open(content)
                
                # Auto-orient based on EXIF
                img = ImageOps.exif_transpose(img)
                print(f"✅ EXIF orientation applied")
                
                # Resize: Max 1200x1200
                img.thumbnail((1200, 1200), Image.LANCZOS)
                print(f"✅ Image resized to max 1200x1200")
                
                # Create unique filename
                filename, ext = name.rsplit('.', 1)
                unique_name = f"{filename}_{uuid.uuid4().hex[:8]}.{ext}"
                print(f"🔄 Renamed to: {unique_name}")
                
                # Save optimized image to buffer
                output = io.BytesIO()
                if ext.lower() == 'png':
                    img.save(output, format='PNG', optimize=True)
                    content_type = 'image/png'
                else:
                    img.save(output, format='JPEG', quality=85, optimize=True)
                    content_type = 'image/jpeg'
                print(f"✅ Image optimized as {content_type}")
                
                output.seek(0)
                content = ContentFile(output.getvalue())
                
                try:
                    # Save thumbnail
                    print(f"🔍 Attempting to save thumbnail...")
                    self._save_thumbnail(unique_name, img, ext)
                    print(f"✅ Thumbnail created successfully")
                except Exception as thumb_error:
                    print(f"⚠️ Thumbnail creation failed but continuing: {thumb_error}")
                    # Continue with main image even if thumbnail fails
                
                name = unique_name
                print(f"✅ Image processed successfully, ready to upload: {name}")
                
            except Exception as e:
                print(f"❌ Error processing image: {e}")
                print(f"Error type: {type(e).__name__}")
                import traceback
                print(f"Traceback: {traceback.format_exc()}")
                if hasattr(content, 'seek'):
                    content.seek(0)
        
        # Try the actual upload to S3
        try:
            print(f"⬆️ Uploading to S3: {name}")
            result = super()._save(name, content)
            print(f"✅ Successfully saved {name} to S3")
            return result
        except Exception as upload_error:
            print(f"❌ S3 UPLOAD ERROR: {upload_error}")
            print(f"Error type: {type(upload_error).__name__}")
            import traceback
            print(f"Traceback: {traceback.format_exc()}")
            # Re-raise to let Django handle it
            raise
    
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
