# C:\Users\Owner\Desktop\CS4000\travelmingle\backend> python manage.py test api.tests.test_models

from django.test import TestCase
from django.contrib.auth import get_user_model
from api.models import (
    Location, Posts, PostImages, Comments, Likes,
    CollectionFolders, Collects, Notifications, Follow, Device
)
from django.contrib.gis.geos import Point


class UsersModelTest(TestCase):
    def setUp(self):
        self.user = get_user_model().objects.create_user(
            username='testuser',
            email='test@example.com',
            password='testpassword'
        )

    def test_user_creation(self):
        self.assertEqual(self.user.username, 'testuser')
        self.assertEqual(self.user.email, 'test@example.com')
        self.assertTrue(self.user.check_password('testpassword'))


class LocationModelTest(TestCase):
    def setUp(self):
        self.location = Location.objects.create(
            place_id='place123',
            name='Test Location',
            address='123 Test Street',
            latitude=40.7128,
            longitude=-74.0060,
            point=Point(-74.0060, 40.7128)
        )

    def test_location_creation(self):
        self.assertEqual(self.location.name, 'Test Location')
        self.assertEqual(self.location.address, '123 Test Street')
        self.assertIsNotNone(self.location.point)


class PostsModelTest(TestCase):
    def setUp(self):
        self.user = get_user_model().objects.create_user(
            username='postuser', email='post@example.com', password='postpassword'
        )
        self.location = Location.objects.create(
            place_id='place456', name='Post Location', address='456 Post Ave',
            latitude=37.7749, longitude=-122.4194
        )
        self.post = Posts.objects.create(
            user=self.user,
            title='My Test Post',
            content='This is a test post',
            location=self.location,
            status='published',
            visibility='public',
            category='adventure',
            period='oneday'
        )

    def test_post_creation(self):
        self.assertEqual(self.post.title, 'My Test Post')
        self.assertEqual(self.post.content, 'This is a test post')
        self.assertEqual(self.post.status, 'published')
        self.assertEqual(self.post.visibility, 'public')
        self.assertEqual(self.post.category, 'adventure')
        self.assertEqual(self.post.period, 'oneday')


class CommentsModelTest(TestCase):
    def setUp(self):
        self.user = get_user_model().objects.create_user(
            username='commentuser', email='comment@example.com', password='commentpassword'
        )
        self.post = Posts.objects.create(
            user=self.user, title='Post with Comments', content='Content here',
            status='published', visibility='public', category='hiking', period='oneday'
        )
        self.comment = Comments.objects.create(
            user=self.user, post=self.post, content='This is a test comment'
        )

    def test_comment_creation(self):
        self.assertEqual(self.comment.content, 'This is a test comment')
        self.assertEqual(self.comment.user.username, 'commentuser')
        self.assertEqual(self.comment.post.title, 'Post with Comments')


class LikesModelTest(TestCase):
    def setUp(self):
        self.user = get_user_model().objects.create_user(
            username='likeuser', email='like@example.com', password='likepassword'
        )
        self.post = Posts.objects.create(
            user=self.user, title='Likeable Post', content='Like content',
            status='published', visibility='public', category='skiing', period='oneday'
        )
        self.like = Likes.objects.create(user=self.user, post=self.post)

    def test_like_creation(self):
        self.assertEqual(self.like.user.username, 'likeuser')
        self.assertEqual(self.like.post.title, 'Likeable Post')


class NotificationsModelTest(TestCase):
    def setUp(self):
        self.sender = get_user_model().objects.create_user(
            username='sender', email='sender@example.com', password='senderpassword'
        )
        self.recipient = get_user_model().objects.create_user(
            username='recipient', email='recipient@example.com', password='recipientpassword'
        )
        self.notification = Notifications.objects.create(
            recipient=self.recipient,
            sender=self.sender,
            notification_type='follow',
            message='You have a new follower'
        )

    def test_notification_creation(self):
        self.assertEqual(self.notification.recipient.username, 'recipient')
        self.assertEqual(self.notification.sender.username, 'sender')
        self.assertEqual(self.notification.notification_type, 'follow')
        self.assertEqual(self.notification.message, 'You have a new follower')


class DeviceModelTest(TestCase):
    def setUp(self):
        self.user = get_user_model().objects.create_user(
            username='deviceuser', email='device@example.com', password='devicepassword'
        )
        self.device = Device.objects.create(
            user=self.user, token='device-token-123')

    def test_device_creation(self):
        self.assertEqual(self.device.user.username, 'deviceuser')
        self.assertEqual(self.device.token, 'device-token-123')
