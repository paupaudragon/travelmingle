from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status, permissions
from ..models import Posts, Follow
from ..serializers import PostSerializer

import re  # regular expressions
from django.db.models import Func, F, Value

class FollowPostView(APIView):
    """
    API view to fetch posts from users the authenticated user follows.
    """
    permission_classes = [permissions.IsAuthenticated]

    def preprocess_filter_values(self, values):
        """
        Helper function to preprocess filter values by removing spaces,
        special characters, and converting to lowercase.
        """
        processed = []
        for value in values:
            value = re.sub(r'[^\w]', '', value)  # Remove non-alphanumeric characters
            value = value.strip().lower()  # Trim and convert to lowercase
            if value:  # Add only if not empty
                processed.append(value)
        return processed

    def get(self, request):
        user = request.user

        # Get users that the current user follows
        followed_users = Follow.objects.filter(follower=user).values_list('following', flat=True)

        # Fetch posts from followed users (excluding drafts)
        followed_posts = Posts.objects.filter(
            user_id__in=followed_users, 
            status="published",
            parent_post__isnull=True
        )

        # Retrieve filter parameters
        travel_types = request.query_params.get('travel_types', '').split(',')
        periods = request.query_params.get('periods', '').split(',')

        # Process filter values
        travel_types = self.preprocess_filter_values(travel_types)
        periods = self.preprocess_filter_values(periods)

        # Normalize category dynamically using annotate
        followed_posts = followed_posts.annotate(
            normalized_category=Func(F('category'), function='LOWER')
        ).annotate(
            normalized_category=Func(F('normalized_category'), Value(' '), Value(''), function='REPLACE')
        )

        # Filter by travel types if provided
        if travel_types:
            followed_posts = followed_posts.filter(normalized_category__in=travel_types)

        # Filter by periods if provided
        if periods:
            followed_posts = followed_posts.filter(period__in=periods)

        # Sort by latest posts
        followed_posts = followed_posts.order_by('-created_at')

        # Serialize posts
        serializer = PostSerializer(followed_posts, many=True, context={'request': request})

        return Response({
            "posts": serializer.data,
            "count": len(serializer.data)
        }, status=status.HTTP_200_OK)
