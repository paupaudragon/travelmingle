from django.db.models.signals import post_save
from django.dispatch import receiver
from .models import Collects, Comments, Follow, Likes, Notifications, Users, Profile


@receiver(post_save, sender=Users)
def create_or_update_user_profile(sender, instance, created, **kwargs):
    """
    Signal to create or update user profile when a user is created/updated
    """
    if not hasattr(instance, 'profile'):
        Profile.objects.create(user=instance, role='user')
    else:
        instance.profile.save()


@receiver(post_save, sender=Likes)
def create_like_notification(sender, instance, created, **kwargs):
    if created:
        if instance.post:
            # Like on post
            Notifications.objects.create(
                recipient=instance.post.user,
                sender=instance.user,
                post=instance.post,
                notification_type='like_post',
                message=f"{instance.user.username} liked your post"
            )
        elif instance.comment:
            # Like on comment
            Notifications.objects.create(
                recipient=instance.comment.user,
                sender=instance.user,
                comment=instance.comment,
                post=instance.comment.post,
                notification_type='like_comment',
                message=f"{instance.user.username} liked your comment"
            )


@receiver(post_save, sender=Comments)
def create_comment_notification(sender, instance, created, **kwargs):
    if created:
        if instance.reply_to:
            # This is a reply to another comment
            Notifications.objects.create(
                recipient=instance.reply_to.user,
                sender=instance.user,
                post=instance.post,
                comment=instance,
                notification_type='reply',
                message=f"{instance.user.username} replied to your comment"
            )
        else:
            # This is a comment on a post
            Notifications.objects.create(
                recipient=instance.post.user,
                sender=instance.user,
                post=instance.post,
                comment=instance,
                notification_type='comment',
                message=f"{instance.user.username} commented on your post"
            )

        # Handle mentions
        for mentioned_user in instance.mentioned_users.all():
            Notifications.objects.create(
                recipient=mentioned_user,
                sender=instance.user,
                post=instance.post,
                comment=instance,
                notification_type='mention',
                message=f"{instance.user.username} mentioned you in a comment"
            )


@receiver(post_save, sender=Collects)
def create_collect_notification(sender, instance, created, **kwargs):
    if created:
        Notifications.objects.create(
            recipient=instance.post.user,
            sender=instance.user,
            post=instance.post,
            notification_type='collect',
            message=f"{instance.user.username} collected your post"
        )


@receiver(post_save, sender=Follow)
def create_follow_notification(sender, instance, created, **kwargs):
    if created:
        Notifications.objects.create(
            recipient=instance.following,
            sender=instance.follower,
            notification_type='follow',
            message=f"{instance.follower.username} started following you"
        )
