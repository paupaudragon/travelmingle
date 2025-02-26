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
        print(f"🔐 Current Auth Token: {request.auth}")  # Debug token
        try:
            notifications = Notifications.objects.filter(
                recipient=request.user
            ).select_related(
                'sender',
                'post',
                'comment',
                'message',
            ).order_by("-created_at")[:50]  # Limit to last 50 notifications

            print(f"✅ Found {notifications.count()} notifications")

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
        if (request.data.get('mark_all')== "true"):
            mark_all = True
        else:
            mark_all = False
        print(f"🔍 DEBUG: User {request.user.id} ({request.user.username}) attempting to mark notifications as read")
        print(f"📋 DEBUG: Request data: notification_ids={notification_ids}, mark_all={mark_all}")
        
        # Check initial state
        initial_unread = Notifications.objects.filter(recipient=request.user, is_read=False)
        initial_unread_count = initial_unread.count()
        print(f"📊 DEBUG: Initial unread count: {initial_unread_count}")
        
        if initial_unread_count > 0:
            print(f"💡 DEBUG: Unread notification IDs before update: {list(initial_unread.values_list('id', flat=True))}")
        
        affected_rows = 0
        
        if mark_all:
            # Mark all notifications as read
            affected_rows = Notifications.objects.filter(
                recipient=request.user,
                is_read=False
            ).update(is_read=True)
            print(f"🔄 DEBUG: Marked ALL as read. Affected rows: {affected_rows}")
        elif notification_ids:
            # Check if notifications exist and belong to user before marking
            valid_ids = list(Notifications.objects.filter(
                recipient=request.user,
                id__in=notification_ids
            ).values_list('id', flat=True))
            
            print(f"🔍 DEBUG: Requested IDs: {notification_ids}")
            print(f"✅ DEBUG: Valid notification IDs found: {valid_ids}")
            
            if len(valid_ids) < len(notification_ids):
                missing_ids = set(notification_ids) - set(valid_ids)
                print(f"⚠️ DEBUG: Some IDs not found or don't belong to user: {missing_ids}")
            
            # Check which ones are already read
            already_read = list(Notifications.objects.filter(
                recipient=request.user,
                id__in=valid_ids,
                is_read=True
            ).values_list('id', flat=True))
            
            if already_read:
                print(f"📝 DEBUG: These notifications were already marked as read: {already_read}")
            
            # Mark specific notifications as read
            affected_rows = Notifications.objects.filter(
                recipient=request.user,
                id__in=valid_ids,
                is_read=False
            ).update(is_read=True)
            print(f"🔄 DEBUG: Marked specific notifications as read. Affected rows: {affected_rows}")

        # Double-check the current state after update
        final_unread = Notifications.objects.filter(recipient=request.user, is_read=False)
        unread_count = final_unread.count()
        
        if unread_count > 0:
            print(f"🔍 DEBUG: Remaining unread notification IDs: {list(final_unread.values_list('id', flat=True))}")
        
        success = initial_unread_count != unread_count or affected_rows > 0
        print(f"{'✅' if success else '❌'} DEBUG: Mark read operation {'successful' if success else 'had no effect'}. Currently unread: {unread_count}")

        return Response({
            'status': 'success' if success else 'no change',
            'unread_count': unread_count,
            'affected_count': affected_rows,
            'debug_info': {
                'requested_ids': notification_ids,
                'valid_ids': valid_ids if 'valid_ids' in locals() else [],
                'already_read': already_read if 'already_read' in locals() else [],
                'affected_rows': affected_rows,
                'initial_unread': initial_unread_count,
                'final_unread': unread_count
            }
        })