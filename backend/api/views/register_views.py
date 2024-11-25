
from rest_framework.permissions import AllowAny
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from ..serializers import UserSerializer
from drf_yasg.utils import swagger_auto_schema
from drf_yasg import openapi


class RegisterView(APIView):
    permission_classes = [AllowAny]

    @swagger_auto_schema(
        operation_summary="Register a new user",
        operation_description="Create a new user by providing a username, email, and password.",
        request_body=UserSerializer,  # Automatically documents the input schema
        responses={
            201: openapi.Response(description="User successfully created", schema=UserSerializer),
            400: openapi.Response(description="Validation error")
        }
    )
    def post(self, request, *args, **kwargs):
        serializer = UserSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save()
            return Response({'message': 'User registered successfully'}, status=status.HTTP_201_CREATED)
        errors = serializer.errors
        if 'username' in errors:
            return Response({'error': errors['username'][0]}, status=status.HTTP_400_BAD_REQUEST)
        if 'email' in errors:
            return Response({'error': errors['email'][0]}, status=status.HTTP_400_BAD_REQUEST)
        return Response({'error': 'Validation error'}, status=status.HTTP_400_BAD_REQUEST)
