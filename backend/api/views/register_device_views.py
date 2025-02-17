# views.py
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from ..device_management import DeviceManager


class RegisterDevice(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        token = request.data.get("token")
        user = request.user

        if not token:
            return Response({"error": "Token is required"}, status=400)

        try:
            # Clean up any invalid tokens first
            DeviceManager.clean_invalid_tokens(user)

            # Register new token
            success, message = DeviceManager.register_device(user, token)

            if success:
                return Response({
                    "message": message,
                    "status": "success"
                })
            else:
                return Response({
                    "error": message
                }, status=400)

        except Exception as e:
            print(f"Device registration error: {e}")
            return Response({
                "error": "Failed to register device",
                "details": str(e)
            }, status=500)
