from drf_yasg import openapi
from drf_yasg.utils import swagger_auto_schema
from rest_framework.generics import UpdateAPIView
from rest_framework.generics import ListCreateAPIView, RetrieveUpdateDestroyAPIView
from ..models import Notifications
from ..serializers import NotificationSerializer


class NotificationListView(ListCreateAPIView):
    """
    Handles listing notifications for a user.
    """
    serializer_class = NotificationSerializer

    @swagger_auto_schema(
        operation_summary="List notifications for a user",
        operation_description=(
            "Retrieve a list of notifications for a specific user. You can optionally filter "
            "by `is_read` (true/false) and `notification_type` (e.g., reply, mention, collection)."
        ),
        manual_parameters=[
            openapi.Parameter(
                "user_id", openapi.IN_QUERY, description="ID of the recipient user", type=openapi.TYPE_INTEGER, required=True
            ),
            openapi.Parameter(
                "is_read", openapi.IN_QUERY, description="Filter by read status (true/false)", type=openapi.TYPE_BOOLEAN, required=False
            ),
            openapi.Parameter(
                "notification_type", openapi.IN_QUERY, description="Filter by notification type (e.g., reply, mention, collection)", type=openapi.TYPE_STRING, required=False
            ),
        ],
        responses={200: NotificationSerializer(many=True)}
    )
    def get(self, request, *args, **kwargs):
        return super().get(request, *args, **kwargs)

    def get_queryset(self):
        """
        Filter notifications for the current user.
        Optionally filter by `is_read` or `notification_type`.
        """
        user_id = self.request.query_params.get('user_id')
        is_read = self.request.query_params.get('is_read')
        notification_type = self.request.query_params.get('notification_type')

        if not user_id:
            return Notifications.objects.none()  # Return empty if user_id is not provided

        queryset = Notifications.objects.filter(
            recipient_id=user_id).order_by('-created_at')

        if is_read is not None:
            queryset = queryset.filter(is_read=is_read.lower() == 'true')

        if notification_type:
            queryset = queryset.filter(notification_type=notification_type)

        return queryset


class NotificationDetailView(RetrieveUpdateDestroyAPIView):
    """
    Handles retrieving, updating, or deleting a single notification.
    """
    queryset = Notifications.objects.select_related(
        'recipient', 'sender', 'post', 'comment').all()
    serializer_class = NotificationSerializer

    @swagger_auto_schema(
        operation_summary="Retrieve a notification",
        operation_description="Retrieve details of a specific notification by its ID.",
        responses={200: NotificationSerializer}
    )
    def get(self, request, *args, **kwargs):
        return super().get(request, *args, **kwargs)

    @swagger_auto_schema(
        operation_summary="Update a notification",
        operation_description="Update the fields of a notification (e.g., mark it as read).",
        request_body=NotificationSerializer,
        responses={200: NotificationSerializer}
    )
    def patch(self, request, *args, **kwargs):
        return super().patch(request, *args, **kwargs)

    @swagger_auto_schema(
        operation_summary="Delete a notification",
        operation_description="Delete a specific notification by its ID.",
        responses={204: "Notification deleted successfully."}
    )
    def delete(self, request, *args, **kwargs):
        return super().delete(request, *args, **kwargs)


class MarkNotificationAsReadView(UpdateAPIView):
    """
    Marks a single notification as read.
    """
    queryset = Notifications.objects.all()
    serializer_class = NotificationSerializer

    @swagger_auto_schema(
        operation_summary="Mark a notification as read",
        operation_description="Update the `is_read` field of a specific notification to `true`.",
        responses={
            200: openapi.Response(
                description="Notification marked as read.",
                schema=openapi.Schema(
                    type=openapi.TYPE_OBJECT,
                    properties={
                        "message": openapi.Schema(
                            type=openapi.TYPE_STRING,
                            description="Confirmation message"
                        )
                    }
                )
            )
        }
    )
    def patch(self, request, *args, **kwargs):
        """
        Update the `is_read` field for the notification.
        """
        notification = self.get_object()
        notification.is_read = True
        notification.save()

        return Response(
            {"message": f"Notification {notification.id} marked as read."},
            status=status.HTTP_200_OK
        )
