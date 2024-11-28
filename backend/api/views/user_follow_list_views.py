from django.shortcuts import get_object_or_404
from rest_framework import status
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from ..models import Users
from ..serializers import UserSerializer


class UserFollowingListView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request, user_id):
        user = get_object_or_404(Users, id=user_id)
        following = user.following.all()
        serializer = UserSerializer(
            following, many=True, context={'request': request})
        return Response(serializer.data)


class UserFollowersListView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request, user_id):
        user = get_object_or_404(Users, id=user_id)
        followers = user.followers_set.all()
        serializer = UserSerializer(
            followers, many=True, context={'request': request})
        return Response(serializer.data)
