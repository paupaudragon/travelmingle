from django.db.models.signals import post_save
from django.dispatch import receiver
from .models import Users, Profile


@receiver(post_save, sender=Users)
def create_or_update_user_profile(sender, instance, created, **kwargs):
    """
    Signal to create or update user profile when a user is created/updated
    """
    if not hasattr(instance, 'profile'):
        Profile.objects.create(user=instance, role='user')
    else:
        instance.profile.save()
