from django.shortcuts import get_object_or_404
from rest_framework import status
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from ..models import Users
from ..serializers import UserSerializer


class UserFollowingListView(APIView):
    """
    UserFollowingListView handles the retrieval of the list of users that a specific user is following.
    Attributes:
        permission_classes (list): A list of permission classes that are required to access this view.
    Methods:
        get(request, user_id):
            Handles GET requests to retrieve the list of users that the specified user is following.
            Args:
                request (Request): The HTTP request object.
                user_id (int): The ID of the user whose following list is to be retrieved.
            Returns:
                Response: A Response object containing the serialized data of the users that the specified user is following.
    """
    permission_classes = [IsAuthenticated]

    def get(self, request, user_id):
        user = get_object_or_404(Users, id=user_id)
        following = user.following.all()
        serializer = UserSerializer(
            following, many=True, context={'request': request})
        return Response(serializer.data)


class UserFollowersListView(APIView):
    """
    UserFollowersListView handles the retrieval of a list of followers for a specific user.
    Methods:
        get(request, user_id):
            Retrieves the list of followers for the user specified by user_id.
            Returns a JSON response containing the serialized follower data.
    Attributes:
        permission_classes (list): Specifies the permission classes that this view requires.
    """
    permission_classes = [IsAuthenticated]

    def get(self, request, user_id):
        user = get_object_or_404(Users, id=user_id)
        followers = user.followers_set.all()
        serializer = UserSerializer(
            followers, many=True, context={'request': request})
        return Response(serializer.data)
