from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from ..models import Device


class RegisterDevice(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        token = request.data.get("token")
        user = request.user  # Authenticated user

        print(f"🔥 API Call: User: {user.username}, Token: {token}")

        if not token:
            return Response({"error": "Token is required"}, status=400)

        device, created = Device.objects.get_or_create(user=user, token=token)

        if not created:
            device.token = token  # Update if token exists
            device.save()

        return Response({"message": "Device registered successfully", "user": user.username})
