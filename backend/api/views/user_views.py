from rest_framework.generics import RetrieveUpdateDestroyAPIView
from rest_framework import status
from drf_yasg.utils import swagger_auto_schema
from rest_framework.generics import ListCreateAPIView, RetrieveUpdateDestroyAPIView
from ..models import Users
from ..serializers import UserSerializer
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated


class UserListCreateView(ListCreateAPIView):
    """
    UserListCreateView is a view that provides both listing and creation of users.
    Methods:
        get(self, request, *args, **kwargs):
            Retrieve a list of all registered users.
    Attributes:
        queryset: A queryset of all User objects.
        serializer_class: The serializer class used for serializing User objects.
    Swagger Documentation:
        operation_summary: "List all users"
        operation_description: "Retrieve a list of all registered users."
        responses: {200: UserSerializer(many=True)}
    """
    queryset = Users.objects.all()
    serializer_class = UserSerializer

    @swagger_auto_schema(
        operation_summary="List all users",
        operation_description="Retrieve a list of all registered users.",
        responses={200: UserSerializer(many=True)},
    )
    def get(self, request, *args, **kwargs):
        return super().get(request, *args, **kwargs)


class UserDetailView(RetrieveUpdateDestroyAPIView):
    """
    UserDetailView handles the retrieval, update, and deletion of user details.
    Methods:
        get(request, *args, **kwargs):
            Retrieve details of a specific user by ID.
        put(request, *args, **kwargs):
            Update user information such as username, email, bio, or profile picture.
        delete(request, *args, **kwargs):
            Delete a user from the system by ID.
    """
    queryset = Users.objects.all()
    serializer_class = UserSerializer

    @swagger_auto_schema(
        operation_summary="Retrieve a user",
        operation_description="Retrieve details of a specific user by ID.",
        responses={200: UserSerializer},
    )
    def get(self, request, *args, **kwargs):
        return super().get(request, *args, **kwargs)

    @swagger_auto_schema(
        operation_summary="Update a user",
        operation_description="Update user information such as username, email, bio, or profile picture.",
        request_body=UserSerializer,
        responses={200: UserSerializer},
    )
    def put(self, request, *args, **kwargs):
        return self.patch(request, *args, **kwargs)

    @swagger_auto_schema(
        operation_summary="Delete a user",
        operation_description="Delete a user. Only admins can delete users, and they cannot delete themselves.",
        responses={
            204: "User deleted successfully.",
            403: "Permission denied - user is not an admin.",
            400: "Bad request - admin attempting to delete themselves.",
            404: "User not found."
        },
    )
    def delete(self, request, *args, **kwargs):
        if request.user.profile.role != 'admin':
            return Response(
                {"detail": "Only administrators can delete user accounts."},
                status=status.HTTP_403_FORBIDDEN
            )

        instance = self.get_object()
        if request.user.id == instance.id:
            return Response(
                {"detail": "You cannot delete your own account."},
                status=status.HTTP_400_BAD_REQUEST
            )

        return super().delete(request, *args, **kwargs)


class UserInfoView(APIView):
    """
    Retrieve the currently authenticated user's information.
    """
    permission_classes = [IsAuthenticated]

    def get(self, request):
        serializer = UserSerializer(request.user)
        return Response(serializer.data)
