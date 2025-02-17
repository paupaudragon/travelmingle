# views.py
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from ..firebase_utils import FirebaseManager
from ..models import Device


class TestFirebaseNotification(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        try:
            # Get the user's device tokens
            device_tokens = Device.objects.filter(
                user=request.user
            ).values_list('token', flat=True)

            if not device_tokens:
                return Response({
                    'error': 'No device tokens found for user',
                    'user': request.user.username
                }, status=400)

            # Print tokens for debugging
            tokens_list = list(device_tokens)
            print(
                f"Found tokens for user {request.user.username}: {tokens_list}")

            # Initialize Firebase manager
            firebase = FirebaseManager()

            # Send test notification
            result = firebase.send_notification(
                tokens=tokens_list,
                title="Test Notification",
                body="This is a test notification",
                data={'type': 'test'}
            )

            return Response({
                'message': 'Test notification sent',
                'result': result,
                'tokens_used': tokens_list
            })

        except Exception as e:
            print(f"Test notification error: {str(e)}")
            return Response({
                'error': str(e),
                'error_type': str(type(e))
            }, status=500)
