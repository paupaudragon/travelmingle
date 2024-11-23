from rest_framework import serializers
from .models import User, Post, Comment


class UserSerializer(serializers.ModelSerializer):
    profile_picture = serializers.SerializerMethodField()

    class Meta:
        model = User
        fields = ['id', 'username', 'email', 'bio',
                  'profile_picture', 'created_at', 'updated_at']

    def get_profile_picture(self, obj):
        # Assuming profile pictures are stored in the Flutter assets folder under "assets/images/"
        return f'assets/user{obj.id}.png'


class CommentSerializer(serializers.ModelSerializer):
    user = UserSerializer(read_only=True)

    class Meta:
        model = Comment
        fields = ['id', 'post', 'user', 'content', 'created_at', 'updated_at', 'parent']
        # fields = ['id', 'post', 'user', 'content', 'created_at', 'updated_at', 'parent', 'image', 'image_path']
        extra_kwargs = {
            'parent': {'required': False},  # Allow `parent` to be optional
            # 'image': {'write_only': True},  # Prevent raw image exposure
        }

    # def get_image_path(self, obj):
    #     request = self.context.get('request')
    #     if obj.image and request:
    #         return request.build_absolute_uri(obj.image.url)
    #     return None

class PostSerializer(serializers.ModelSerializer):
    user = UserSerializer(read_only=True)
    comments = CommentSerializer(many=True, read_only=True, source='comment_set')  # Include related comments

    class Meta:
        model = Post
        fields = ['id', 'user', 'title', 'content', 'created_at', 'updated_at', 'likes', 'saves', 'comments']

