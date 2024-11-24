from rest_framework import serializers
from django.contrib.auth.hashers import make_password
from .models import Users, Posts, Comments, PostImages, Likes, CollectionFolders, Collects, Notifications


class UserSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True, required=True)
    profile_picture_url = serializers.SerializerMethodField()

    class Meta:
        model = Users
        fields = ['id', 'username', 'email', 'password', 'bio',
                  'profile_picture', 'profile_picture_url', 'created_at', 'updated_at']
        extra_kwargs = {
            'profile_picture': {'write_only': True, 'required': False},
            'bio': {'required': False},
            'created_at': {'read_only': True},
            'updated_at': {'read_only': True},
        }

    # this filed is created on-the-fly to give the absolute url to the front end
    def get_profile_picture_url(self, obj):
        # First check if user has uploaded a picture
        if obj.profile_picture:  # If user has uploaded a picture
            request = self.context.get('request')
            if request:
                # Return full URL of uploaded picture
                return request.build_absolute_uri(obj.profile_picture.url)
            return obj.profile_picture.url  # Return relative URL of uploaded picture

    # This part only runs if obj.profile_picture is None/empty (user didn't upload)
        request = self.context.get('request')
        if request:
            # Return full URL of default picture
            return request.build_absolute_uri('/media/profile_pictures/default.png')
        # Return relative URL of default picture
        return '/media/profile_pictures/default.png'

    def create(self, validated_data):
        # Hash the password before saving
        validated_data['password'] = make_password(
            validated_data.get('password'))
        return super().create(validated_data)


class PostImageSerializer(serializers.ModelSerializer):
    class Meta:
        model = PostImages
        fields = ['id', 'post', 'image', 'created_at']


class CommentSerializer(serializers.ModelSerializer):
    user = UserSerializer(read_only=True)
    replies = serializers.SerializerMethodField()
    likes_count = serializers.SerializerMethodField()

    class Meta:
        model = Comments
        fields = ['id', 'post', 'user', 'content', 'created_at', 'updated_at',
                  'reply_to', 'replies', 'likes_count', 'mentioned_users']
        extra_kwargs = {
            'reply_to': {'required': False},
        }

    def get_replies(self, obj):
        replies = Comments.objects.filter(reply_to=obj)
        return CommentSerializer(replies, many=True).data

    def get_likes_count(self, obj):
        return obj.comment_likes.count()


class PostSerializer(serializers.ModelSerializer):
    user = UserSerializer(read_only=True)
    comments = CommentSerializer(
        many=True, read_only=True, source='comment_set')
    images = PostImageSerializer(many=True, read_only=True)
    likes_count = serializers.SerializerMethodField()
    is_collected = serializers.SerializerMethodField()

    class Meta:
        model = Posts
        fields = ['id', 'user', 'title', 'content', 'location', 'created_at',
                  'updated_at', 'status', 'visibility', 'comments', 'images',
                  'likes_count', 'is_collected']

    def get_likes_count(self, obj):
        return obj.post_likes.count()

    def get_is_collected(self, obj):
        request = self.context.get('request')
        if request and request.user.is_authenticated:
            return Collects.objects.filter(user=request.user, post=obj).exists()
        return False


class LikeSerializer(serializers.ModelSerializer):
    user = UserSerializer(read_only=True)

    class Meta:
        model = Likes
        fields = ['id', 'user', 'post', 'comment', 'created_at']
        extra_kwargs = {
            'post': {'required': False},
            'comment': {'required': False},
        }

    def validate(self, data):
        if ('post' in data and 'comment' in data and
                data['post'] and data['comment']):
            raise serializers.ValidationError(
                "A like cannot be associated with both a post and a comment.")
        if not data.get('post') and not data.get('comment'):
            raise serializers.ValidationError(
                "A like must be associated with either a post or a comment.")
        return data


class CollectionFolderSerializer(serializers.ModelSerializer):
    user = UserSerializer(read_only=True)
    collections_count = serializers.SerializerMethodField()

    class Meta:
        model = CollectionFolders
        fields = ['id', 'user', 'name', 'created_at',
                  'updated_at', 'collections_count']

    def get_collections_count(self, obj):
        return obj.collections.count()


class CollectSerializer(serializers.ModelSerializer):
    user = UserSerializer(read_only=True)
    post = PostSerializer(read_only=True)
    folder = CollectionFolderSerializer(read_only=True)

    class Meta:
        model = Collects
        fields = ['id', 'user', 'post', 'folder', 'created_at']


class NotificationSerializer(serializers.ModelSerializer):
    recipient = UserSerializer(read_only=True)
    sender = UserSerializer(read_only=True)
    post = PostSerializer(read_only=True)
    comment = CommentSerializer(read_only=True)

    class Meta:
        model = Notifications
        fields = ['id', 'recipient', 'sender', 'post', 'comment',
                  'notification_type', 'message', 'is_read', 'created_at']
        read_only_fields = ['notification_type', 'message']
