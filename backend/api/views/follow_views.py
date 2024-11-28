from rest_framework import status
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django.db import IntegrityError
from ..models import Users, Follow


class FollowView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request, user_id):
        """
        Get follow status for a user
        """
        try:
            user = Users.objects.get(id=user_id)
            is_following = Follow.objects.filter(
                follower=request.user,
                following=user
            ).exists()

            return Response({
                'is_following': is_following,
                # Changed from follower_relationships
                'followers_count': user.followers_set.count(),
                # Changed from following_relationships
                'following_count': user.following.count()
            })
        except Users.DoesNotExist:
            return Response(
                {'error': 'User not found'},
                status=status.HTTP_404_NOT_FOUND
            )

    def post(self, request, user_id):
        """
        Toggle follow status for a user
        """
        try:
            user_to_follow = Users.objects.get(id=user_id)

            # Prevent self-following
            if request.user.id == user_id:
                return Response(
                    {'error': 'Cannot follow yourself'},
                    status=status.HTTP_400_BAD_REQUEST
                )

            follow_exists = Follow.objects.filter(
                follower=request.user,
                following=user_to_follow
            ).exists()

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
                # Changed from follower_relationships
                'followers_count': user_to_follow.followers_set.count(),
                # Changed from following_relationships
                'following_count': user_to_follow.following.count()
            })

        except Users.DoesNotExist:
            return Response(
                {'error': 'User not found'},
                status=status.HTTP_404_NOT_FOUND
            )
        except IntegrityError:
            return Response(
                {'error': 'Failed to update follow status'},
                status=status.HTTP_400_BAD_REQUEST
            )
