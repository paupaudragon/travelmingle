from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from ..models import Device


class RegisterDevice(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        token = request.data.get("token")
        user = request.user  # Authenticated user

        if not token:
            return Response({"error": "Token is required"}, status=400)

        try:
            # Instead of get_or_create, try to update existing device
            device, created = Device.objects.get_or_create(
                token=token,
                defaults={'user': user}
            )

            if not created:
                # If device exists, update the user if different
                if device.user != user:
                    device.user = user
                    device.save()

            return Response({
                "message": "Device registered successfully",
                "status": "created" if created else "updated"
            })

        except Exception as e:
            print(f"Device registration error: {e}")
            return Response({
                "error": "Failed to register device",
                "details": str(e)
            }, status=500)
