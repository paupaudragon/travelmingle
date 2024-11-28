from rest_framework import status
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from ..models import Users
from ..serializers import UserSerializer


class FollowListView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request, user_id, list_type):
        """
        Get list of followers or following users
        """
        try:
            user = Users.objects.get(id=user_id)

            if list_type == 'followers':
                users = user.followers_set.all()
            elif list_type == 'following':
                users = user.following.all()
            else:
                return Response(
                    {'error': 'Invalid list type'},
                    status=status.HTTP_400_BAD_REQUEST
                )

            serializer = UserSerializer(
                users, many=True, context={'request': request})
            return Response(serializer.data)

        except Users.DoesNotExist:
            return Response(
                {'error': 'User not found'},
                status=status.HTTP_404_NOT_FOUND
            )
