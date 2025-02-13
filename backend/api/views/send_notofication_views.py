from firebase_admin import messaging
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from ..models import Device


class SendNotification(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        title = request.data.get("title", "New Notification")
        body = request.data.get("body", "You have a new message!")
        recipient_username = request.data.get("recipient")

        if not recipient_username:
            return Response({"error": "Recipient username is required"}, status=400)

        try:
            # Get the recipient's device token
            device = Device.objects.filter(
                user__username=recipient_username).first()
            if not device:
                return Response({"error": "Recipient has no registered device"}, status=404)

            fcm_token = device.token  # The Firebase Cloud Messaging token

            # 🔥 Make sure we are sending a "notification" message, NOT just "data"
            message = messaging.Message(
                notification=messaging.Notification(
                    title=title,
                    body=body,
                ),
                token=fcm_token,
            )

            # Send the notification
            response = messaging.send(message)

            return Response({"message": "Notification sent successfully!", "firebase_response": response})
        except Exception as e:
            return Response({"error": str(e)}, status=500)
