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
        Get follow status for a user.

        This method retrieves the follow status, followers count, and following count for a specified user.

        Args:
            request (Request): The HTTP request object.
            user_id (int): The ID of the user to get the follow status for.

        Returns:
            Response: A JSON response containing:
                - is_following (bool): Whether the authenticated user is following the specified user.
                - followers_count (int): The number of followers for the specified user.
                - following_count (int): The number of users the specified user is following.

        Raises:
            Response: HTTP 404 if the specified user is not found.
        """
        try:
            user = Users.objects.get(id=user_id)
            is_following = Follow.objects.filter(
                follower=request.user,
                following=user
            ).exists()

            return Response({
                'is_following': is_following,
                'followers_count': user.followers_set.count(),
                'following_count': user.following.count()
            })
        except Users.DoesNotExist:
            return Response(
                {'error': 'User not found'},
                status=status.HTTP_404_NOT_FOUND
            )

    def post(self, request, user_id):
        """
        Toggle follow status for a user.

        This method allows the authenticated user to follow or unfollow another user.

        Args:
            request (Request): The HTTP request object.
            user_id (int): The ID of the user to follow or unfollow.

        Returns:
            Response: A JSON response containing:
                - is_following (bool): The updated follow status.
                - followers_count (int): The updated number of followers for the target user.
                - following_count (int): The updated number of users the target user is following.

        Raises:
            Response: HTTP 400 if the user attempts to follow themselves.
            Response: HTTP 404 if the specified user is not found.
            Response: HTTP 400 if there's an integrity error while updating the follow status.
        """
        try:
            user_to_follow = Users.objects.get(id=user_id)

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
                Follow.objects.filter(
                    follower=request.user,
                    following=user_to_follow
                ).delete()
                is_following = False
            else:
                Follow.objects.create(
                    follower=request.user,
                    following=user_to_follow
                )
                is_following = True

            return Response({
                'is_following': is_following,
                'followers_count': user_to_follow.followers_set.count(),
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
