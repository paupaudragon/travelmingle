from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from ..models import Device
from ..serializers import DeviceSerializer


class RegisterDevice(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        token = request.data.get("token")

        if not token:
            return Response({"error": "Token is required"}, status=400)

        user = request.user

        # Store or update the FCM token
        device, created = Device.objects.get_or_create(user=user, token=token)

        if not created:
            device.token = token  # Update token if it already exists
            device.save()

        return Response({"message": "Device registered successfully"})
