# device_management.py
from firebase_admin import messaging
from .models import Device


class DeviceManager:
    @staticmethod
    def clean_invalid_tokens(user):
        """Remove invalid device tokens for a user"""
        devices = Device.objects.filter(user=user)
        for device in devices:
            try:
                # Try to send a test message
                message = messaging.Message(
                    data={'type': 'validation'},
                    token=device.token
                )
                messaging.send(message, dry_run=True)
            except Exception as e:
                if 'SenderId mismatch' in str(e):
                    print(
                        f"Removing token with mismatched sender ID for user {user.username}: {device.token[:20]}...")
                    device.delete()
                elif 'registration-token-not-registered' in str(e).lower():
                    print(
                        f"Removing unregistered token for user {user.username}: {device.token[:20]}...")
                    device.delete()
                else:
                    print(f"Error validating token: {str(e)}")

    @staticmethod
    def register_device(user, token):
        """Register a new device token"""
        try:
            # Validate token with dry run
            message = messaging.Message(
                data={'type': 'validation'},
                token=token
            )
            messaging.send(message, dry_run=True)

            # If validation successful, save token
            device, created = Device.objects.get_or_create(
                token=token,
                defaults={'user': user}
            )

            if not created and device.user != user:
                device.user = user
                device.save()

            return True, "Device registered successfully"
        except Exception as e:
            if 'SenderId mismatch' in str(e):
                return False, "Invalid token: Sender ID mismatch"
            return False, f"Token validation failed: {str(e)}"
