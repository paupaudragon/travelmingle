from rest_framework import serializers
from django.contrib.auth.hashers import make_password
from .models import Follow, Users, Posts, Comments, PostImages, Likes, CollectionFolders, Collects, Notifications

from django.db.models import Prefetch


class UserSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True, required=True)
    profile_picture_url = serializers.SerializerMethodField()

    followers_count = serializers.IntegerField(
        read_only=True, source='follower_relationships.count')
    following_count = serializers.IntegerField(
        read_only=True, source='following_relationships.count')
    is_following = serializers.BooleanField(read_only=True, default=False)

    class Meta:
        model = Users
        fields = ['id', 'username', 'email', 'password', 'bio',
                  'profile_picture', 'profile_picture_url', 'created_at',
                  'updated_at', 'followers_count', 'following_count',
                  'is_following']
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

    def to_representation(self, instance):
        data = super().to_representation(instance)
        request = self.context.get('request')
        if request and request.user.is_authenticated:
            data['is_following'] = Follow.objects.filter(
                follower=request.user,
                following=instance
            ).exists()
        return data

    def create(self, validated_data):
        # Hash the password before saving
        validated_data['password'] = make_password(
            validated_data.get('password'))
        return super().create(validated_data)

    def get_followers_count(self, obj):
        return obj.followers.count()

    def get_following_count(self, obj):
        return obj.following.count()

    def get_is_following(self, obj):
        request = self.context.get('request')
        if request and request.user.is_authenticated:
            return Follow.objects.filter(follower=request.user, following=obj).exists()
        return False


class PostImageSerializer(serializers.ModelSerializer):
    class Meta:
        model = PostImages
        fields = ['id', 'post', 'image', 'created_at']


class CommentSerializer(serializers.ModelSerializer):
    user = UserSerializer(read_only=True)
    replies = serializers.SerializerMethodField()
    likes_count = serializers.SerializerMethodField()
    is_liked = serializers.SerializerMethodField()
    comment_image_url = serializers.SerializerMethodField()

    class Meta:
        model = Comments
        fields = ['id', 'post', 'user', 'content', 'created_at', 'updated_at',
                  'reply_to', 'replies', 'likes_count', 'mentioned_users', 'is_liked',
                  'comment_image', 'comment_image_url',]
        extra_kwargs = {
            'reply_to': {'required': False},
            'content': {'required': False},
            'comment_image': {'write_only': True, 'required': False},
        }

    def validate(self, data):
        # Ensure at least one of `content` or `comment_image` is provided
        if not data.get('content') and not data.get('comment_image'):
            raise serializers.ValidationError(
                "At least one of 'content' or 'comment_image' must be provided.")
        return data

    def get_comment_image_url(self, obj):
        # First check if user has uploaded a picture
        if obj.comment_image:  # If user has uploaded a picture
            request = self.context.get('request')
            if request:
                # Return full URL of uploaded picture
                return request.build_absolute_uri(obj.comment_image.url)
            return obj.comment_image.url  # Return relative URL of uploaded picture

    def get_user(self, obj):
        return {
            "id": obj.user.id,
            "username": obj.user.username,
            "profile_picture_url": obj.user.profile_picture.url if obj.user.profile_picture else None,
        }

    def get_replies(self, obj):
        # Preload replies for all comments in the view using prefetch_related
        replies = Comments.objects.filter(reply_to=obj)
        return CommentSerializer(replies, many=True, context=self.context).data

    def get_likes_count(self, obj):
        return obj.comment_likes.count()

    ###
    def get_is_liked(self, obj):
        """Check if the logged-in user liked the comment."""
        request = self.context.get('request', None)
        if request and request.user.is_authenticated:
            return obj.comment_likes.filter(user=request.user).exists()
        return False

    def create(self, validated_data):
        validated_data['user'] = self.context['request'].user
        return super().create(validated_data)

    def get_comments_queryset(post_id):
        # Prefetch replies for all comments in one query
        return Comments.objects.filter(post_id=post_id, reply_to=None).prefetch_related(
            Prefetch('comments_set', queryset=Comments.objects.all())
        )


class PostSerializer(serializers.ModelSerializer):
    user = UserSerializer(read_only=True)
    images = PostImageSerializer(many=True, read_only=True)
    likes_count = serializers.SerializerMethodField()
    collected_count = serializers.SerializerMethodField()
    detailed_comments = serializers.SerializerMethodField()
    is_liked = serializers.SerializerMethodField()
    is_saved = serializers.SerializerMethodField()

    class Meta:
        model = Posts
        fields = ['id', 'user', 'title', 'content', 'location', 'created_at',
                  'updated_at', 'status', 'visibility', 'images', 'likes_count',
                  'collected_count', 'detailed_comments', 'is_liked', 'is_saved',]

    def get_likes_count(self, obj):
        """Calculate and return the total like count for the post."""
        return obj.post_likes.count()

    def get_collected_count(self, obj):
        """Calculate and return the total count of collections for the post."""
        return Collects.objects.filter(post=obj).count()

    def get_detailed_comments(self, obj):
        """Generate and return a detailed JSON of comments with their replies and likes."""
        comments = obj.comments_set.filter(
            reply_to=None)  # Fetch only top-level comments
        return CommentSerializer(comments, many=True).data

    ##
    def get_is_liked(self, obj):
        """Check if the logged-in user liked the post."""
        request = self.context.get('request', None)
        if request and request.user.is_authenticated:
            return obj.post_likes.filter(user=request.user).exists()
        return False

    def get_is_saved(self, obj):
        """Check if the logged-in user saved the post."""
        request = self.context.get('request', None)
        if request and request.user.is_authenticated:
            return obj.collected_by.filter(user=request.user).exists()
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


class FollowSerializer(serializers.ModelSerializer):
    class Meta:
        model = Follow
        fields = ['id', 'follower', 'following', 'created_at']
        read_only_fields = ['created_at']
