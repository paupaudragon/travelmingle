import googlemaps
from django.conf import settings
import firebase_admin
from firebase_admin import credentials, messaging
from .models import Device

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
