from .models import Device
from rest_framework import serializers
from django.contrib.auth.hashers import make_password
from .models import Follow, Users, Posts, Location, Comments, PostImages, Likes, CollectionFolders, Collects, Notifications

from django.db.models import Prefetch

import logging
logger = logging.getLogger(__name__)

# notification


class UserSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True, required=True)

    # Custom field that will be populated by a method called get_varraibel_name
    # This naming convention is used by Django Rest Framework to populate the field
    # So the getter name has to be "get_profile_picture_url"
    profile_picture_url = serializers.SerializerMethodField()

    followers_count = serializers.IntegerField(
        # relationship defined in Follow Model
        read_only=True, source='follower_relationships.count')
    following_count = serializers.IntegerField(
        # relationship defined in Follow Model
        read_only=True, source='following_relationships.count')
    is_following = serializers.BooleanField(read_only=True, default=False)

    role = serializers.CharField(source='profile.role', read_only=True)
    # Defines what fileds and nested obj should be in the serialization

    class Meta:
        model = Users
        fields = ['id', 'username', 'email', 'password', 'bio',
                  'profile_picture', 'profile_picture_url', 'created_at',
                  'updated_at', 'followers_count', 'following_count',
                  'is_following', 'role']

        # defines the settings for each field
        extra_kwargs = {
            # write_only means field will only be used when creating/updating
            # read_only means can't be modifed
            # required means forced of not to create the obj
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

    # Add a dynamic is_following field that tells the currently authenticated user whether they are following the user being serialized.
    # Used in any serializers that has a UserSerializer field.
    def to_representation(self, instance):
        # get parent to_rep to get initial serialize data
        data = super().to_representation(instance)
        request = self.context.get('request')  # get request from context
        if request and request.user.is_authenticated:  # check request nout null and if user is authenticated
            data['is_following'] = Follow.objects.filter(
                follower=request.user,
                following=instance
            ).exists()
        return data

    #
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


# Example of how to use UserSerializer:
# 1. Serializing a user

# user = Users.objects.get(id=1)
# serializer = UserSerializer(user, context={'request': request})
# return Response(serializer.data)

# # Output would look like:
# {
#     "id": 1,
#     "username": "john_doe",
#     "email": "john@example.com",
#     "bio": "Hello world",
#     "profile_picture_url": "http://yoursite.com/media/profiles/pic.jpg",
#     "followers_count": 42,
#     "following_count": 38,
#     "is_following": true
# }

# 2. Create a new user
# serializer = UserSerializer(data={
#     "username": "new_user",
#     "email": "new@example.com",
#     "password": "secret123",
#     "bio": "Hello!"
# })
# if serializer.is_valid():
#     user = serializer.save()

# context is always context={'request': request}
# Example request attributes
# request.user  # The authenticated user object
# request.method  # 'GET', 'POST', etc.
# request.data  # Contains parsed request body for POST/PUT
# request.query_params  # GET parameters
# request.META  # Contains HTTP headers and environment info


class PostImageSerializer(serializers.ModelSerializer):
    image = serializers.SerializerMethodField()

    class Meta:
        model = PostImages
        fields = ['id', 'post', 'image', 'created_at']

    def get_image(self, obj):
        request = self.context.get('request', None)

        # ✅ Check if request exists before using it
        if request and obj.image:
            return request.build_absolute_uri(obj.image.url)

        # ✅ Return None if there's no image
        return None


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


class LocationSerializer(serializers.ModelSerializer):
    class Meta:
        model = Location
        fields = ['id', 'place_id', 'name', 'address', 'latitude', 'longitude']


class PostSerializer(serializers.ModelSerializer):
    location = LocationSerializer()
    user = UserSerializer(read_only=True)
    images = PostImageSerializer(many=True, read_only=True)
    likes_count = serializers.SerializerMethodField()
    saves_count = serializers.SerializerMethodField()
    detailed_comments = serializers.SerializerMethodField()
    is_liked = serializers.SerializerMethodField()
    is_saved = serializers.SerializerMethodField()

    childPosts = serializers.SerializerMethodField()

    class Meta:
        model = Posts
        fields = ['id', 'user', 'title', 'content', 'location', 'created_at', 'category', 'period',
                  'updated_at', 'status', 'visibility', 'images', 'likes_count',
                  'saves_count', 'detailed_comments', 'is_liked', 'is_saved',
                  'childPosts',]
        extra_kwargs = {
            'category': {'required': True},  # Ensure category is required
            'hashtags': {'required': False},  # Hashtags are optional
        }
        # Prevent users from manually modifying it
        read_only_fields = ['period']

    def validate(self, data):
        if 'location' not in data or not data['location']:
            raise serializers.ValidationError(
                {"location": "Location data is required."})
        return data

    def to_internal_value(self, data):
        """Convert incoming JSON data into a Python dictionary before validation."""
        data = super().to_internal_value(data)

        # Debug: Print received data
        print("🔍 Raw incoming data:", self.initial_data)

        # 🔹 Handle `location` JSON parsing
        location_data = self.initial_data.get('location')
        if isinstance(location_data, str):
            import json
            try:
                location_data = json.loads(location_data)
                print("📍 Parsed location:", location_data)  # Debugging line
                data['location'] = location_data
            except json.JSONDecodeError:
                raise serializers.ValidationError(
                    {'location': 'Invalid JSON format'})

        # 🔹 Handle `child_posts` JSON parsing
        child_posts_data = self.initial_data.get('child_posts', '[]')
        if isinstance(child_posts_data, str):
            try:
                data['child_posts'] = json.loads(child_posts_data)
            except json.JSONDecodeError:
                raise serializers.ValidationError(
                    {'child_posts': 'Invalid JSON format'})

        return data

    def create(self, validated_data):
        print("🚀 Backend create() method is called!")  # Debug log

        # Get request for user authentication
        request = self.context.get('request')

        location_data = validated_data.pop('location', None)
        child_posts_data = validated_data.pop(
            'child_posts', [])  # Extract child posts

        print("🚀 Received Post Data in Backend:")
        print("Title:", validated_data.get('title'))
        print("Category:", validated_data.get('category'))
        print("Period:", validated_data.get('period'))
        # Print child posts received
        print("Child Posts Data:", child_posts_data)

        # Handle the location creation
        if location_data:
            location, created = Location.objects.get_or_create(
                defaults={
                    'name': location_data['name'],
                    'address': location_data['address'],
                    'latitude': location_data['latitude'],
                    'longitude': location_data['longitude']
                }
            )
            validated_data['location'] = location

        # Assign user (since it's required)
        user = request.user if request else None
        if not user:
            raise serializers.ValidationError({"user": "User is required."})

        # Create the main post
        main_post = Posts.objects.create(user=user, **validated_data)

        # Handle child posts if the main post is multi-day
        if validated_data.get('period') == 'multipleday':
            for child_data in child_posts_data:
                print("📌 Creating Child Post:", child_data)
                child_location_data = child_data.pop('location', None)
                if child_location_data:
                    child_location, created = Location.objects.get_or_create(
                        place_id=child_location_data['place_id'],
                        defaults={
                            'name': location_data['name'],
                            'address': location_data['address'],
                            'latitude': location_data['latitude'],
                            'longitude': location_data['longitude']
                        }
                    )
                    child_data['location'] = child_location

                Posts.objects.create(parent_post=main_post, **child_data)

        return main_post

    def get_likes_count(self, obj):
        """Calculate and return the total like count for the post."""
        return obj.post_likes.count()

    def get_saves_count(self, obj):
        """Calculate and return the total count of collections for the post."""
        return obj.post_saves.count()

    def get_detailed_comments(self, obj):
        """Generate and return a detailed JSON of comments with their replies and likes."""
        comments = obj.comments_set.filter(
            reply_to=None)  # Fetch only top-level comments
        return CommentSerializer(comments, many=True).data

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
            return obj.post_saves.filter(user=request.user).exists()
        return False

    def get_childPosts(self, obj):
        if obj.period == 'multipleday':
            child_posts = Posts.objects.filter(parent_post=obj)
            print(
                f"🔎 Found {child_posts.count()} child posts for parent {obj.id}")
            return PostSerializer(child_posts, many=True, context=self.context).data
        return []


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


# Notification
class DeviceSerializer(serializers.ModelSerializer):
    class Meta:
        model = Device
        fields = ["user", "token"]
