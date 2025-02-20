from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status, permissions
from django.db.models import Q, Max
from ..models import Message, Users
from ..serializers import MessageSerializer

from drf_yasg.utils import swagger_auto_schema
from drf_yasg import openapi

class MessageListView(APIView):
    """
    Fetch messages between the authenticated user and another user.
    """
    permission_classes = [permissions.IsAuthenticated]

    @swagger_auto_schema(
        manual_parameters=[
            openapi.Parameter(
                'other_user_id', openapi.IN_QUERY,
                description="ID of the other user in the conversation",
                type=openapi.TYPE_INTEGER,
                required=True
            )
        ],
        responses={200: MessageSerializer(many=True)}
    )

    def get(self, request):
        other_user_id = request.query_params.get('other_user_id')
        
        if not other_user_id:
            return Response({"error": "Missing other_user_id parameter"}, status=status.HTTP_400_BAD_REQUEST)

        try:
            other_user = Users.objects.get(id=other_user_id)
        except Users.DoesNotExist:
            return Response({"error": "User not found"}, status=status.HTTP_404_NOT_FOUND)

        user = request.user
        messages = Message.objects.filter(
            Q(sender=user, receiver=other_user) | Q(sender=other_user, receiver=user)
        ).order_by('timestamp')

        serializer = MessageSerializer(messages, many=True)
        return Response(serializer.data, status=status.HTTP_200_OK)


class SendMessageView(APIView):
    """
    Send a message from the authenticated user to another user.
    """
    permission_classes = [permissions.IsAuthenticated]

    @swagger_auto_schema(
        request_body=openapi.Schema(
            type=openapi.TYPE_OBJECT,
            required=['receiver', 'content'],
            properties={
                'receiver': openapi.Schema(type=openapi.TYPE_INTEGER, description="ID of the receiver"),
                'content': openapi.Schema(type=openapi.TYPE_STRING, description="Message content"),
            },
        ),
        responses={201: MessageSerializer()},
    )

    def post(self, request):
        receiver_id = request.data.get("receiver")
        content = request.data.get("content")

        if not receiver_id or not content:
            return Response({"error": "Missing receiver or content"}, status=status.HTTP_400_BAD_REQUEST)

        try:
            receiver = Users.objects.get(id=receiver_id)
        except Users.DoesNotExist:
            return Response({"error": "Receiver not found"}, status=status.HTTP_404_NOT_FOUND)

        message = Message.objects.create(sender=request.user, receiver=receiver, content=content)
        serializer = MessageSerializer(message)
        return Response(serializer.data, status=status.HTTP_201_CREATED)


class MarkMessageReadView(APIView):
    """
    Mark a message as read.
    """
    permission_classes = [permissions.IsAuthenticated]

    @swagger_auto_schema(
        manual_parameters=[
            openapi.Parameter(
                'message_id', openapi.IN_PATH,
                description="ID of the message to mark as read",
                type=openapi.TYPE_INTEGER,
                required=True
            )
        ],
        responses={200: openapi.Response("Message marked as read")}
    )

    def patch(self, request, message_id):
        try:
            message = Message.objects.get(id=message_id, receiver=request.user)
            message.is_read = True
            message.save()
            return Response({"message": "Message marked as read"}, status=status.HTTP_200_OK)
        except Message.DoesNotExist:
            return Response({"error": "Message not found"}, status=status.HTTP_404_NOT_FOUND)


class ConversationsListView(APIView):
    """
    Fetch a list of users the authenticated user has messaged, showing the latest message with each user.
    """
    permission_classes = [permissions.IsAuthenticated]

    @swagger_auto_schema(
        responses={200: MessageSerializer(many=True)}
    )

    def get(self, request):
        user = request.user

        # Get latest messages in each conversation
        latest_messages = Message.objects.filter(
            Q(sender=user) | Q(receiver=user)
        ).order_by('-timestamp').distinct('sender', 'receiver')

        serializer = MessageSerializer(latest_messages, many=True)
        return Response(serializer.data, status=status.HTTP_200_OK)