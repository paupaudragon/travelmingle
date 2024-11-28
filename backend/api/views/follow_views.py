from rest_framework import status
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django.db import IntegrityError
from ..models import Users, Follow


class FollowView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request, user_id):
        """
        Toggle follow status for a user.
        POST /api/users/{user_id}/follow/
        """
        try:
            user_to_follow = Users.objects.get(id=user_id)
        except Users.DoesNotExist:
            return Response(
                {'error': 'User not found'},
                status=status.HTTP_404_NOT_FOUND
            )

        # Prevent self-following
        if request.user.id == user_id:
            return Response(
                {'error': 'Cannot follow yourself'},
                status=status.HTTP_400_BAD_REQUEST
            )

        # Check if already following
        follow_exists = Follow.objects.filter(
            follower=request.user,
            following=user_to_follow
        ).exists()

        try:
            if follow_exists:
                # Unfollow
                Follow.objects.filter(
                    follower=request.user,
                    following=user_to_follow
                ).delete()
                is_following = False
            else:
                # Follow
                Follow.objects.create(
                    follower=request.user,
                    following=user_to_follow
                )
                is_following = True

            return Response({
                'is_following': is_following,
                'followers_count': user_to_follow.followers.count(),
                'following_count': user_to_follow.following.count()
            })

        except IntegrityError:
            return Response(
                {'error': 'Failed to update follow status'},
                status=status.HTTP_400_BAD_REQUEST
            )

    def get(self, request, user_id):
        """
        Get follow status and counts for a user.
        GET /api/users/{user_id}/follow/
        """
        try:
            user = Users.objects.get(id=user_id)
        except Users.DoesNotExist:
            return Response(
                {'error': 'User not found'},
                status=status.HTTP_404_NOT_FOUND
            )

        is_following = False
        if request.user.is_authenticated:
            is_following = Follow.objects.filter(
                follower=request.user,
                following=user
            ).exists()

        return Response({
            'is_following': is_following,
            'followers_count': user.followers.count(),
            'following_count': user.following.count()
        })
