from datetime import timedelta, timezone
import googlemaps
from django.conf import settings
import firebase_admin
from firebase_admin import credentials, messaging
from .models import Device, Notifications
from django.db import transaction

gmaps = googlemaps.Client(key=settings.GOOGLE_MAPS_API_KEY)


def geocode_address(address):
    try:
        result = gmaps.geocode(address)
        if result:
            location = result[0]['geometry']['location']
            return {
                'lat': location['lat'],
                'lng': location['lng']
            }
    except Exception as e:
        print(f"Geocoding error: {e}")
    return None


##### Notifications #####
def send_push_notification(user, title, body):
    """
    Send push notifications via Firebase Cloud Messaging (FCM).
    """
    devices = Device.objects.filter(user=user)

    for device in devices:
        message = messaging.Message(
            notification=messaging.Notification(title=title, body=body),
            token=device.token,
        )
        response = messaging.send(message)
        print(f"Notification sent to {user.username}: {response}")


@transaction.atomic
def create_notification(recipient, sender, notification_type, message, post=None, comment=None):
    """
    Create a notification with built-in deduplication
    """
    try:
        # Check for recent duplicate notifications (last 5 minutes)
        recent_time = timezone.now() - timedelta(minutes=5)
        existing_notification = Notifications.objects.filter(
            recipient=recipient,
            sender=sender,
            notification_type=notification_type,
            post=post,
            comment=comment,
            created_at__gte=recent_time
        ).first()

        if not existing_notification:
            return Notifications.objects.create(
                recipient=recipient,
                sender=sender,
                notification_type=notification_type,
                message=message,
                post=post,
                comment=comment
            )
        return existing_notification

    except IntegrityError:
        # Log the duplicate attempt
        logger.warning(f"Duplicate notification attempt: {notification_type}")
        return None
