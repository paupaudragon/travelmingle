from rest_framework import serializers
from .models import User, Post


class UserSerializer(serializers.ModelSerializer):
    profile_picture = serializers.SerializerMethodField()

    class Meta:
        model = User
        fields = ['id', 'username', 'email', 'bio',
                  'profile_picture', 'created_at', 'updated_at']

    def get_profile_picture(self, obj):
        # Assuming profile pictures are stored in the Flutter assets folder under "assets/images/"
        return f'assets/user{obj.id}.png'


class PostSerializer(serializers.ModelSerializer):
    user = UserSerializer(read_only=True)

    class Meta:
        model = Post
        fields = ['id', 'user', 'title', 'content', 'created_at', 'updated_at']
