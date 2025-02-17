# notification_views.py
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.permissions import IsAuthenticated
from ..models import Notifications
from ..serializers import NotificationSerializer


class NotificationListView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        print(f"🔍 Notification Request by User: {request.user.username}")

        try:
            notifications = Notifications.objects.filter(
                recipient=request.user
            ).select_related(
                'sender',
                'post',
                'comment'
            )[:50]  # Limit to last 50 notifications

            serializer = NotificationSerializer(
                notifications,
                many=True,
                context={'request': request}
            )

            # Get count of unread notifications
            unread_count = Notifications.objects.filter(
                recipient=request.user,
                is_read=False
            ).count()

            return Response({
                'notifications': serializer.data,
                'unread_count': unread_count
            })
        except Exception as e:
            print(f"❌ Error in NotificationListView: {e}")
            return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


class NotificationMarkReadView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        """Mark notifications as read"""
        notification_ids = request.data.get('notification_ids', [])
        mark_all = request.data.get('mark_all', False)

        if mark_all:
            # Mark all notifications as read
            Notifications.objects.filter(
                recipient=request.user,
                is_read=False
            ).update(is_read=True)
        elif notification_ids:
            # Mark specific notifications as read
            Notifications.objects.filter(
                recipient=request.user,
                id__in=notification_ids,
                is_read=False
            ).update(is_read=True)

        unread_count = Notifications.objects.filter(
            recipient=request.user,
            is_read=False
        ).count()

        return Response({
            'status': 'success',
            'unread_count': unread_count
        })
