# signals.py
from django.db.models.signals import post_save
from django.dispatch import receiver
from .device_management import DeviceManager
from .models import Collects, Comments, Follow, Likes, Notifications, Users, Profile, Device
from .firebase_utils import FirebaseManager

firebase = FirebaseManager()


def send_push_notification(recipient, notification_data):
    """Helper function to send push notification to a user's devices"""
    # Clean up invalid tokens first
    DeviceManager.clean_invalid_tokens(recipient)

    # Get all device tokens for the recipient
    device_tokens = Device.objects.filter(
        user=recipient
    ).values_list('token', flat=True)

    if device_tokens:
        # Send notification via Firebase
        result = firebase.send_notification(
            tokens=list(device_tokens),
            title=notification_data['title'],
            body=notification_data['message'],
            data={
                'type': notification_data['type'],
                'notification_id': str(notification_data['notification_id']),
                'post_id': str(notification_data.get('post_id', '')),
                'comment_id': str(notification_data.get('comment_id', ''))
            }
        )

        # If there were any failures, clean up those tokens
        if result.get('failed_tokens'):
            for failed_token in result['failed_tokens']:
                Device.objects.filter(token=failed_token['token']).delete()


@receiver(post_save, sender=Users)
def create_or_update_user_profile(sender, instance, created, **kwargs):
    """Signal to create or update user profile when a user is created/updated"""
    if not hasattr(instance, 'profile'):
        Profile.objects.create(user=instance, role='user')
    else:
        instance.profile.save()


@receiver(post_save, sender=Likes)
def create_like_notification(sender, instance, created, **kwargs):
    """Signal to handle notifications for likes on posts and comments"""
    if created:
        if instance.post:
            # Create database notification for post like
            notification = Notifications.objects.create(
                recipient=instance.post.user,
                sender=instance.user,
                post=instance.post,
                notification_type='like_post',
                message=f"{instance.user.username} liked your post"
            )

            # Send push notification
            send_push_notification(instance.post.user, {
                'title': 'New Like',
                'message': f"{instance.user.username} liked your post",
                'type': 'like_post',
                'notification_id': notification.id,
                'post_id': instance.post.id
            })

        elif instance.comment:
            # Create database notification for comment like
            notification = Notifications.objects.create(
                recipient=instance.comment.user,
                sender=instance.user,
                comment=instance.comment,
                post=instance.comment.post,
                notification_type='like_comment',
                message=f"{instance.user.username} liked your comment"
            )

            send_push_notification(instance.comment.user, {
                'title': 'New Like',
                'message': f"{instance.user.username} liked your comment",
                'type': 'like_comment',
                'notification_id': notification.id,
                'post_id': instance.comment.post.id,
                'comment_id': instance.comment.id
            })


@receiver(post_save, sender=Comments)
def create_comment_notification(sender, instance, created, **kwargs):
    """Signal to handle notifications for comments and replies"""
    if created:
        if instance.reply_to:
            # Create database notification for reply
            notification = Notifications.objects.create(
                recipient=instance.reply_to.user,
                sender=instance.user,
                post=instance.post,
                comment=instance,
                notification_type='reply',
                message=f"{instance.user.username} replied to your comment"
            )

            # Send push notification for reply
            send_push_notification(instance.reply_to.user, {
                'title': 'New Reply',
                'message': f"{instance.user.username} replied to your comment",
                'type': 'reply',
                'notification_id': notification.id,
                'post_id': instance.post.id,
                'comment_id': instance.id
            })
        else:
            # Create database notification for comment on post
            notification = Notifications.objects.create(
                recipient=instance.post.user,
                sender=instance.user,
                post=instance.post,
                comment=instance,
                notification_type='comment',
                message=f"{instance.user.username} commented on your post"
            )

            # Send push notification for comment
            send_push_notification(instance.post.user, {
                'title': 'New Comment',
                'message': f"{instance.user.username} commented on your post",
                'type': 'comment',
                'notification_id': notification.id,
                'post_id': instance.post.id,
                'comment_id': instance.id
            })

        # Handle mentions in comments
        for mentioned_user in instance.mentioned_users.all():
            # Create database notification for mention
            notification = Notifications.objects.create(
                recipient=mentioned_user,
                sender=instance.user,
                post=instance.post,
                comment=instance,
                notification_type='mention',
                message=f"{instance.user.username} mentioned you in a comment"
            )

            # Send push notification for mention
            send_push_notification(mentioned_user, {
                'title': 'New Mention',
                'message': f"{instance.user.username} mentioned you in a comment",
                'type': 'mention',
                'notification_id': notification.id,
                'post_id': instance.post.id,
                'comment_id': instance.id
            })


@receiver(post_save, sender=Collects)
def create_collect_notification(sender, instance, created, **kwargs):
    """Signal to handle notifications for post collections"""
    if created:
        # Create database notification
        notification = Notifications.objects.create(
            recipient=instance.post.user,
            sender=instance.user,
            post=instance.post,
            notification_type='collect',
            message=f"{instance.user.username} collected your post"
        )

        # Send push notification
        send_push_notification(instance.post.user, {
            'title': 'New Collection',
            'message': f"{instance.user.username} collected your post",
            'type': 'collect',
            'notification_id': notification.id,
            'post_id': instance.post.id
        })


@receiver(post_save, sender=Follow)
def create_follow_notification(sender, instance, created, **kwargs):
    """Signal to handle notifications for new followers"""
    if created:
        # Create database notification
        notification = Notifications.objects.create(
            recipient=instance.following,
            sender=instance.follower,
            notification_type='follow',
            message=f"{instance.follower.username} started following you"
        )

        # Send push notification
        send_push_notification(instance.following, {
            'title': 'New Follower',
            'message': f"{instance.follower.username} started following you",
            'type': 'follow',
            'notification_id': notification.id
        })
