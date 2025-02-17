
from django.http import JsonResponse
from rest_framework.permissions import AllowAny
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status

from ..models import Device
from ..serializers import UserSerializer
from drf_yasg.utils import swagger_auto_schema
from drf_yasg import openapi


class RegisterView(APIView):
    """
    RegisterView handles the registration of a new user.
    This view allows any user to register by providing a username, email, and password.
    It uses the UserSerializer to validate and save the user data.
    Methods:
        post(request, *args, **kwargs): Handles the POST request to register a new user.
        - Request Body: UserSerializer
        - Responses:
            201: User successfully created
            400: Validation error
    Attributes:
        permission_classes (list): Specifies the permission classes that this view requires.
    """
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
    def post(self, request):
        try:
            user = request.user
            token = request.POST.get('token')

            # Try to find existing device
            device = Device.objects.filter(token=token).first()

            if device:
                # Update existing device if needed
                device.user = user
                device.save()
            else:
                # Create new device
                Device.objects.create(user=user, token=token)

            return JsonResponse({'status': 'success'})

        except Exception as e:
            return JsonResponse({'error': str(e)}, status=500)
