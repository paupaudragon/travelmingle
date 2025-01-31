from rest_framework.permissions import AllowAny, IsAuthenticated
from drf_yasg import openapi
from drf_yasg.utils import swagger_auto_schema
import re  # regular expressions
from django.shortcuts import get_object_or_404
import logging
import json

# Serializer
from ..serializers import PostSerializer

# Authentication lib
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from rest_framework.views import APIView
from rest_framework.generics import RetrieveAPIView
from rest_framework_simplejwt.exceptions import InvalidToken, TokenError
from rest_framework_simplejwt.tokens import AccessToken
from rest_framework.generics import ListCreateAPIView, RetrieveUpdateDestroyAPIView

# Always import new models
from ..models import Location, PostImages, Posts, Likes, Comments, Collects, CollectionFolders

from rest_framework.views import APIView
from rest_framework.parsers import MultiPartParser, FormParser, JSONParser
from rest_framework.response import Response
from rest_framework import status
from rest_framework.permissions import IsAuthenticated


class PostListCreateView(APIView):
    """
    View for creating and listing posts.
    Methods
    -------
    post(request)
        Create a new post with title, content, images, location, and other metadata.
        Parameters:
            - title (str): Post title (required)
            - content (str): Post content (required)
            - image (file): Post images (multiple files allowed) (optional)
            - location (str): Post location (required)
            - status (str): Post status (published/draft) (default: 'published') (optional)
            - visibility (str): Post visibility (public/private) (default: 'public') (optional)
        Responses:
            - 201: Post created successfully
            - 400: Bad Request
            - 401: Unauthorized
    get(request)
        Retrieve a list of all posts ordered by creation date.
        Responses:
            - 200: List of posts
            - 401: Unauthorized
    """
    parser_classes = (MultiPartParser, FormParser, JSONParser)
    permission_classes = [IsAuthenticated]

    @swagger_auto_schema(
        operation_summary="Create a new post",
        operation_description="Create a new post with title, content, images, location, and other metadata",
        request_body=PostSerializer,
        responses={
            201: PostSerializer,
            400: "Bad Request",
            401: "Unauthorized"
        }
    )
    def post(self, request):
        try:
            logger = logging.getLogger(__name__)
            # Debug request data
            print("📥 Incoming Request Data:", request.data)

            # Check if location is provided
            location = request.data.get('location')
            # Retrieve category from request data
            category = request.data.get('category')
            content = request.data.get('content', '')
            period = request.data.get('period')

            if not location:
                print("❌ Error: Location is missing in request data")
                return Response({'error': 'Location is required'}, status=status.HTTP_400_BAD_REQUEST)
            if not category:
                print("❌ Error: Category is missing in request data")
                return Response({'error': 'Category is required'}, status=status.HTTP_400_BAD_REQUEST)
            if not period:
                print("❌ Error: Period is missing in request data")
                return Response({'error': 'Period is required'}, status=status.HTTP_400_BAD_REQUEST)

            is_multi_day = period == 'multipleday'
            print(f"🔍 is_multi_day: {is_multi_day}")

            # Parse location JSON string if necessary
            if isinstance(location, str):
                location = json.loads(location)

            # Ensure required location fields are present
            required_fields = ['place_id', 'name',
                               'address', 'latitude', 'longitude']
            for field in required_fields:
                if field not in location:
                    return Response(
                        {'error': f'Missing location field: {field}'},
                        status=status.HTTP_400_BAD_REQUEST
                    )

            # Get or create location instance
            location, created = Location.objects.get_or_create(
                place_id=location['place_id'],
                defaults={
                    'name': location['name'],
                    'address': location['address'],
                    'latitude': location['latitude'],
                    'longitude': location['longitude']
                }
            )

            # Create the parent post
            parent_post = Posts.objects.create(
                user=request.user,
                title=request.data.get('title'),
                content="" if is_multi_day else request.data.get('content'),
                location=location,
                category=category,
                period=period,
                status=request.data.get('status', 'published'),
                visibility=request.data.get('visibility', 'public')
            )

            # Handle image uploads
            images = request.FILES.getlist('image')
            print(f"📸 Received {len(images)} images for post {parent_post.id}")
            for image in images:
                PostImages.objects.create(post=parent_post, image=image)
            print("✅ Images saved successfully")

            # Handle multi-day child posts
            if is_multi_day:
                print("🔄 Processing multi-day child posts...")
                child_posts = request.data.get('child_posts', '[]')

                # Convert child_posts to Python list if it's a string
                try:
                    if isinstance(child_posts, str):
                        child_posts = json.loads(child_posts)
                except json.JSONDecodeError:
                    print("❌ Error: Invalid child_posts JSON format")
                    return Response({'error': 'Invalid child_posts JSON format'}, status=status.HTTP_400_BAD_REQUEST)

                print(f"📌 Total child posts received: {len(child_posts)}")

                for i, day_content in enumerate(child_posts):
                    print(f"📍 Processing child post {i+1}: {day_content}")

                    day_title = day_content.get('title')
                    day_content_text = day_content.get('content')
                    # child_location = day_content.get('location')
                    child_location = day_content.get('location')

                    # Collect missing fields
                    missing_fields = []
                    if not day_title:
                        missing_fields.append('day_title')
                    if not day_content_text:
                        missing_fields.append('content')
                    if not child_location:
                        missing_fields.append('child_location')

                    # If any required field is missing, return an error specifying the missing fields
                    if missing_fields:
                        print(f"❌ Error: Missing fields in child post {
                              i+1}: {', '.join(missing_fields)}")
                        return Response(
                            {'error': f'Child post {
                                i+1} is missing required fields: {", ".join(missing_fields)}'},
                            status=status.HTTP_400_BAD_REQUEST
                        )

                    # Parse location JSON string if necessary
                    if isinstance(child_location, str):
                        child_location = json.loads(child_location)

                    # Ensure required location fields are present
                    required_fields = ['place_id', 'name',
                                       'address', 'latitude', 'longitude']
                    for field in required_fields:
                        if field not in child_location:
                            return Response(
                                {'error': f'Missing location field: {field}'},
                                status=status.HTTP_400_BAD_REQUEST
                            )

                    # Ensure child location is a valid `Location` instance
                    try:
                        child_location, created = Location.objects.get_or_create(
                            place_id=child_location.get('place_id'),
                            defaults={
                                'name': child_location.get('name'),
                                'address': child_location.get('address'),
                                'latitude': child_location.get('latitude'),
                                'longitude': child_location.get('longitude')
                            }
                        )
                        print(f"✅ Child location processed: {
                              child_location.name}")
                    except (ObjectDoesNotExist, KeyError, TypeError) as e:
                        print("❌ Error processing child location data:", str(e))
                        return Response({'error': 'Invalid child post location data'}, status=status.HTTP_400_BAD_REQUEST)

                    # Create the child post
                    child_post = Posts.objects.create(
                        user=request.user,
                        title=day_title,
                        content=day_content_text,
                        location=child_location,
                        category=category,
                        period='oneday',
                        status='published',
                        visibility=parent_post.visibility,
                        parent_post=parent_post
                    )

                    # ✅ Handle Child Post Images
                    child_images = request.FILES.getlist(f'childImages_{i}')
                    print(f"📸 Received {len(child_images)
                                        } images for child post {child_post.id}")
                    if child_images:
                        for image in child_images:
                            PostImages.objects.create(
                                post=child_post, image=image)
                        print("✅ Child post images saved successfully")
                    else:
                        print(f"❌ No images found for child post {
                              child_post.id}")

                    print(f"""
                    ✅ Child post {i+1} created successfully:
                        - ID: {child_post.id}
                        - Title: {child_post.title}
                        - Content: {child_post.content}
                        - Location: {child_location.name}
                        - Address: {child_location.address}
                        - Latitude: {child_location.latitude}
                        - Longitude: {child_location.longitude}
                        - Category: {child_post.category}
                        - Period: {child_post.period}
                        - Status: {child_post.status}
                        - Visibility: {child_post.visibility}
                        - Parent Post ID: {parent_post.id}
                        - Image Count: {len(child_images)}
                    """)

            # Return the created post with all its data
            serializer = PostSerializer(
                parent_post, context={'request': request})
            print("🚀 Successfully created post with child posts")

            print(
                f"🔍 Debug: childPosts Sent in Response -> {serializer.data.get('childPosts')}")

            return Response(
                {"message": "Post created successfully.", "post": serializer.data},
                status=status.HTTP_201_CREATED
            )

        except Exception as e:
            logger.error(f"Error creating post: {str(e)}")
            print("❌ Unexpected error:", str(e))

            return Response(
                {'error': 'An unexpected error occurred while creating the post'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    @swagger_auto_schema(
        operation_summary="List all posts",
        operation_description="Retrieve a list of all posts ordered by creation date",
        manual_parameters=[
            openapi.Parameter(
                'category',
                openapi.IN_QUERY,
                description="Filter posts by category (e.g., 'adventure', 'hiking')",
                type=openapi.TYPE_STRING,
                required=False
            ),
            openapi.Parameter(
                'period',
                openapi.IN_QUERY,
                description="Filter posts by period (e.g., 'oneday', 'multipleday')",
                type=openapi.TYPE_STRING,
                required=False
            ),
        ],
        responses={
            200: PostSerializer(many=True),
            401: "Unauthorized"
        }
    )
    def get(self, request):
        travel_types = request.query_params.get('travel_types', '').split(',')
        periods = request.query_params.get('periods', '').split(',')

       # Preprocess travel types and periods to remove spaces, special characters, and trim
        def preprocess_filter_values(values):
            processed = []
            for value in values:
                # Remove non-alphanumeric characters
                value = re.sub(r'[^\w]', '', value)
                value = value.strip().lower()  # Trim and convert to lowercase
                if value:  # Add only if not empty
                    processed.append(value)
            return processed

        travel_types = preprocess_filter_values(travel_types)
        periods = preprocess_filter_values(periods)

       # Debugging: Log the preprocessed values
        print("Processed Travel Types:", travel_types)
        print("Processed Periods:", periods)

        posts = Posts.objects.all().filter(
            parent_post__isnull=True).order_by('-created_at')

        # Filter by travel types if provided
        if travel_types:
            posts = posts.filter(category__in=travel_types)
            print("Posts after Travel Types Filter:",
                  posts.count())  # Debugging

        # Filter by periods if provided
        if periods:
            posts = posts.filter(period__in=periods)
            print("Posts after Periods Filter:", posts.count())  # Debugging

        serializer = PostSerializer(
            posts, many=True, context={'request': request})
<<<<<<< Updated upstream
=======

        # ✅ Debug: Ensure `childPosts` are included in response
        for post in serializer.data:
            print(f"🔍 Post {post['id']} has {
                  len(post['childPosts'])} child posts")

>>>>>>> Stashed changes
        return Response(serializer.data)


class PostDetailView(RetrieveUpdateDestroyAPIView):
    """
    PostDetailView handles the retrieval, update, and deletion of a specific post.
    Attributes:
        queryset (QuerySet): The queryset to retrieve posts with related user data.
        serializer_class (Serializer): The serializer class to use for post data.
        permission_classes (list): The list of permission classes required for accessing this view.
    Methods:
        get_serializer_context(): Returns the context for the serializer, including the request.
        get(request, *args, **kwargs): Retrieves details of a specific post by ID.
        patch(request, *args, **kwargs): Updates a specific post's title, content, status, or visibility.
        delete(request, *args, **kwargs): Deletes a specific post by ID.
    """
    queryset = Posts.objects.select_related('user').all()
    serializer_class = PostSerializer

    # Require authentication for all methods in this class
    permission_classes = [IsAuthenticated]

    def get_serializer_context(self):
        """Pass request context for SerializerMethodField to work."""
        return {'request': self.request}

    @swagger_auto_schema(
        operation_summary="Retrieve a post",
        operation_description="Retrieve details of a specific post by ID, including its associated user and comments.",
        responses={200: PostSerializer},
    )
    def get(self, request, *args, **kwargs):
        post = get_object_or_404(self.queryset, pk=kwargs['pk'])

        print(f"🔍 Fetching Post ID: {post.id}, Period: {post.period}")

        serializer = self.get_serializer(post)
        data = serializer.data

        # If the post is a multi-day post, include child_posts in the response
        if post.period == 'multipleday':
            child_posts = Posts.objects.filter(parent_post=post).order_by('id')
            print("✅ Retrieved Child Posts:", list(
                child_posts.values()))  # Print child posts
            child_posts_serializer = PostSerializer(
                child_posts, many=True, context=self.get_serializer_context()
            )
            # serializer = self.get_serializer(post)
            # data = serializer.data
            # Ensure it's `child_posts`
            data['child_posts'] = child_posts_serializer.data
            return Response(data, status=status.HTTP_200_OK)

        # For single-day posts, return the standard serialized data
        return super().get(request, *args, **kwargs)

    @swagger_auto_schema(
        operation_summary="Update a post",
        operation_description="Update a specific post's title, content, status, or visibility.",
        request_body=PostSerializer,
        responses={200: PostSerializer},
    )
    def patch(self, request, *args, **kwargs):
        return super().patch(request, *args, **kwargs)

    @swagger_auto_schema(
        operation_summary="Delete a post",
        operation_description="Delete a post. Users can delete their own posts, admins can delete any post.",
        responses={
            204: "Post deleted successfully.",
            403: "Permission denied - user is not the owner or admin.",
            404: "Post not found."
        },
    )
    def delete(self, request, *args, **kwargs):
        instance = self.get_object()
        if request.user == instance.user or request.user.profile.role == 'user':
            return super().delete(request, *args, **kwargs)
        return Response(
            {"detail": "You do not have permission to delete this post."},
            status=status.HTTP_403_FORBIDDEN
        )


class ToggleLikeView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request, *args, **kwargs):
        user = request.user
        post_id = kwargs.get('post_id')
        comment_id = kwargs.get('comment_id')

        if post_id and comment_id:
            return Response({"error": "Provide either post_id or comment_id, not both."}, status=400)

        if post_id:
            try:
                post = Posts.objects.get(id=post_id)
                like, created = Likes.objects.get_or_create(
                    user=user, post=post)
                if not created:
                    like.delete()  # Unlike
                    is_liked = False
                else:
                    is_liked = True
                likes_count = post.post_likes.count()
            except Posts.DoesNotExist:
                return Response({"error": "Post not found"}, status=404)

        elif comment_id:
            try:
                comment = Comments.objects.get(id=comment_id)
                like, created = Likes.objects.get_or_create(
                    user=user, comment=comment)
                if not created:
                    like.delete()  # Unlike
                    is_liked = False
                else:
                    is_liked = True
                likes_count = comment.comment_likes.count()
            except Comments.DoesNotExist:
                return Response({"error": "Comment not found"}, status=404)
        else:
            return Response({"error": "Invalid request, provide post_id or comment_id"}, status=400)

        return Response({'is_liked': is_liked, 'likes_count': likes_count}, status=200)


class ToggleSaveView(APIView):
    """
    ToggleSaveView handles the saving and unsaving of posts by authenticated users.
    Methods:
        post(request, post_id):
            Handles the POST request to save or unsave a post.
            - Retrieves the user from the request.
            - Safely accesses the folder name from the request data, defaults to 'Default'.
            - Checks if the post with the given post_id exists.
            - Gets or creates a folder for the user.
            - Checks if the post is already saved in the specified folder.
            - If the post is already saved, it unsaves (deletes) the collect.
            - If the post is not saved, it saves (creates) the collect.
            - Counts the total number of users who have saved this post.
            - Returns a response with the save status and the total number of saves.
    """
    permission_classes = [IsAuthenticated]

    def post(self, request, post_id):
        user = request.user

        # Safely access request data
        folder_name = request.data.get('folder_name') if hasattr(
            request, 'data') and request.data else 'Default'

        try:
            # Check if the post exists
            post = Posts.objects.get(id=post_id)
        except Posts.DoesNotExist:
            return Response({"error": "Post not found"}, status=status.HTTP_404_NOT_FOUND)

        # Get or create a folder for the user
        folder, _ = CollectionFolders.objects.get_or_create(
            user=user, name=folder_name)

        # Check if the post is already saved in this folder
        collect = Collects.objects.filter(
            user=user, post=post, folder=folder).first()

        if collect:
            # If the collect already exists, delete it (unsave the post)
            collect.delete()
            is_saved = False
        else:
            # If the collect doesn't exist, create it (save the post)
            Collects.objects.create(user=user, post=post, folder=folder)
            is_saved = True

        # Count the total number of users who have saved this post
        saves_count = Collects.objects.filter(post=post).count()

        return Response(
            {"is_saved": is_saved, "saves_count": saves_count},
            status=status.HTTP_200_OK
        )
