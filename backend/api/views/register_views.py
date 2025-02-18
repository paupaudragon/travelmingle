from django.contrib.auth import authenticate
from django.http import JsonResponse
from rest_framework_simplejwt.tokens import RefreshToken
from rest_framework.permissions import AllowAny
from ..serializers import UserSerializer
from rest_framework.views import APIView


class RegisterView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        try:
            serializer = UserSerializer(data=request.data)
            if serializer.is_valid():
                user = serializer.save()

                # Generate JWT tokens
                refresh = RefreshToken.for_user(user)

                return JsonResponse({
                    "status": "success",
                    "access_token": str(refresh.access_token),
                    "refresh_token": str(refresh)
                }, status=201)

            return JsonResponse({'error': serializer.errors}, status=400)

        except Exception as e:
            return JsonResponse({'error': str(e)}, status=500)
