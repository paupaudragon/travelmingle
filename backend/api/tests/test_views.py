# python manage.py test api.tests.test_views
from rest_framework.test import APITestCase
from rest_framework import status
from django.contrib.auth import get_user_model
from api.models import Device, Follow, Notifications, Posts, Likes, Comments, CollectionFolders, Collects, Location
from rest_framework_simplejwt.tokens import AccessToken
from django.urls import reverse


class LikeViewsTestCase(APITestCase):
    def setUp(self):
        self.user = get_user_model().objects.create_user(
            username='testuser', email='test11@example.com', password='testpass')
        self.post = Posts.objects.create(
            user=self.user, title='Test Post', content='Some content')
        self.access_token = str(AccessToken.for_user(self.user))
        self.client.credentials(
            HTTP_AUTHORIZATION=f'Bearer {self.access_token}')
        self.like_url = reverse('post-like', kwargs={'post_id': self.post.id})

    def test_toggle_like(self):
        response = self.client.post(self.like_url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertTrue(response.data['is_liked'])

        response = self.client.post(self.like_url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertFalse(response.data['is_liked'])


class NearbyPostsTestCase(APITestCase):
    def setUp(self):
        self.user = get_user_model().objects.create_user(
            username='user', email='test22@example.com', password='pass')

        self.access_token = str(
            AccessToken.for_user(self.user))  # Generate token

        self.location = Location.objects.create(
            place_id='place123', name='Test Location', address='123 Street', latitude=40.7128, longitude=-74.0060
        )
        self.post = Posts.objects.create(
            user=self.user, title='Nearby Post', content='Content', location=self.location)

        self.url = reverse('nearby-posts')

    def test_get_nearby_posts(self):
        # Ensure authentication
        self.client.credentials(
            HTTP_AUTHORIZATION=f'Bearer {self.access_token}')
        response = self.client.get(
            self.url, {'latitude': 40.7128, 'longitude': -74.0060, 'radius': 10})

        print(response.json())  # Debugging output

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertGreaterEqual(len(response.json().get('posts', [])), 1)


class PostViewsTestCase(APITestCase):
    def setUp(self):
        self.user = get_user_model().objects.create_user(
            username='user22', email='test33@example.com', password='pass')
        self.access_token = str(AccessToken.for_user(self.user))
        self.client.credentials(
            HTTP_AUTHORIZATION=f'Bearer {self.access_token}')
        self.location = Location.objects.create(
            place_id='loc1', name='Place', address='Address', latitude=40.0, longitude=-74.0
        )
        self.post = Posts.objects.create(
            user=self.user, title='Test Post', content='Content', location=self.location)
        self.post_detail_url = reverse(
            'post-detail', kwargs={'pk': self.post.id})


def test_create_post(self):
    url = reverse('post-list-create')
    data = {
        'title': 'New Post',
        'content': 'New Content',
        'location': self.location.id,  # Ensure this is the correct format
        'category': 'adventure',  # Ensure this value is valid
        'period': 'oneday'
    }
    self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {self.access_token}')
    response = self.client.post(url, data, format='json')

    # Debugging Output to check what went wrong
    print("Response Status Code:", response.status_code)
    print("Response JSON:", response.json())

    self.assertEqual(response.status_code, status.HTTP_201_CREATED)

    def test_get_post_detail(self):
        response = self.client.get(self.post_detail_url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['title'], 'Test Post')


class UserViewsTestCase(APITestCase):
    def setUp(self):
        self.user = get_user_model().objects.create_user(
            username='user33', email='test44@example.com', password='pass')
        self.access_token = str(AccessToken.for_user(self.user))
        self.client.credentials(
            HTTP_AUTHORIZATION=f'Bearer {self.access_token}')
        self.user_detail_url = reverse(
            'user-detail', kwargs={'pk': self.user.id})

    def test_get_user_info(self):
        response = self.client.get(reverse('user-info'))
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['username'], 'user33')


class FollowListTestCase(APITestCase):
    def setUp(self):
        self.user = get_user_model().objects.create_user(
            username='user1', email='user1@example.com', password='pass')
        self.user2 = get_user_model().objects.create_user(
            username='user2', email='user2@example.com', password='pass')
        Follow.objects.create(follower=self.user, following=self.user2)
        self.access_token = str(AccessToken.for_user(self.user))
        self.client.credentials(
            HTTP_AUTHORIZATION=f'Bearer {self.access_token}')
        self.followers_url = reverse(
            'user-followers', kwargs={'user_id': self.user2.id})

    def test_get_followers_list(self):
        response = self.client.get(self.followers_url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.json()), 1)


class NotificationTestCase(APITestCase):
    def setUp(self):
        self.user = get_user_model().objects.create_user(
            username='user77', email='test77@example.com', password='pass')
        self.user2 = get_user_model().objects.create_user(
            username='user88', email='test88@example.com', password='pass')
        Notifications.objects.create(recipient=self.user, sender=self.user2,
                                     notification_type='follow', message='User2 followed you')
        self.access_token = str(AccessToken.for_user(self.user))
        self.client.credentials(
            HTTP_AUTHORIZATION=f'Bearer {self.access_token}')
        self.notifications_url = reverse('notification-list')

    def test_get_notifications(self):
        response = self.client.get(self.notifications_url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data['notifications']), 1)


class CommentViewsTestCase(APITestCase):
    def setUp(self):
        self.user = get_user_model().objects.create_user(username='commentuser',
                                                         email='comment@example.com', password='pass')
        self.access_token = str(AccessToken.for_user(self.user))
        self.client.credentials(
            HTTP_AUTHORIZATION=f'Bearer {self.access_token}')

        self.post = Posts.objects.create(
            user=self.user, title='Test Post', content='Some content')
        # Ensure this URL is correct
        self.comment_url = reverse('comment-list-create')

    def test_create_comment(self):
        data = {
            'post': self.post.id,  # Ensure the post ID is included
            'content': 'This is a test comment'
        }
        response = self.client.post(self.comment_url, data, format='json')

        # Debugging output to check API response
        print(response.json())

        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertIn('id', response.json())  # Ensure a comment ID is returned
        self.assertEqual(response.json()['content'], 'This is a test comment')

    def test_create_comment_without_content_or_image(self):
        data = {
            'post': self.post.id  # Missing content and image, should fail validation
        }
        response = self.client.post(self.comment_url, data, format='json')

        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn("At least one of 'content' or 'comment_image' must be provided.",
                      response.json()['non_field_errors'])


class LoginTestCase(APITestCase):
    def setUp(self):
        self.user = get_user_model().objects.create_user(
            username='loginuser', email='login@example.com', password='pass')
        self.login_url = reverse('token_obtain_pair')

    def test_login_user(self):
        data = {'username': 'loginuser', 'password': 'pass'}
        response = self.client.post(self.login_url, data, format='json')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn('access', response.json())


class RegisterDeviceTestCase(APITestCase):
    def setUp(self):
        self.user = get_user_model().objects.create_user(username='deviceuser',
                                                         email='deviceuser@example.com', password='pass')
        self.access_token = str(AccessToken.for_user(self.user))
        self.client.credentials(
            HTTP_AUTHORIZATION=f'Bearer {self.access_token}')
        self.device_url = reverse('register-device')


def test_register_device(self):
    # Replace with a valid FCM token
    data = {'token': 'VALID_FCM_TOKEN_EXAMPLE'}
    self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {self.access_token}')
    response = self.client.post(self.device_url, data, format='json')

    # Debugging Output
    print("Response Status Code:", response.status_code)
    print("Response JSON:", response.json())

    self.assertEqual(response.status_code, status.HTTP_201_CREATED)
    self.assertEqual(response.json()['status'], 'success')

    def test_unregister_device(self):
        data = {'token': 'valid-device-token'}
        self.client.credentials(
            HTTP_AUTHORIZATION=f'Bearer {self.access_token}')
        response = self.client.delete(self.device_url, data, format='json')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.json()['status'], 'success')


class RegisterUserTestCase(APITestCase):
    def setUp(self):
        self.register_url = reverse('register')

    def test_register_user(self):
        data = {'username': 'newuser',
                'email': 'newuser@example.com', 'password': 'newpass'}
        response = self.client.post(self.register_url, data, format='json')
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertIn('access_token', response.json())


class SendNotificationTestCase(APITestCase):
    def setUp(self):
        self.user = get_user_model().objects.create_user(username='notifyuser',
                                                         email='notify@example.com', password='pass')
        self.recipient = get_user_model().objects.create_user(
            username='recipient', email='recipient@example.com', password='pass')
        Device.objects.create(user=self.recipient, token='test-fcm-token')
        self.access_token = str(AccessToken.for_user(self.user))
        self.client.credentials(
            HTTP_AUTHORIZATION=f'Bearer {self.access_token}')
        self.notification_url = reverse('send-notification')


def test_send_notification(self):
    data = {
        'title': 'Test Notification',
        'body': 'This is a test',
        'recipient': 'recipient'
    }
    self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {self.access_token}')
    response = self.client.post(self.notification_url, data, format='json')

    # Debugging Output
    print("Response Status Code:", response.status_code)
    print("Response JSON:", response.json())

    self.assertEqual(response.status_code, status.HTTP_200_OK)
    self.assertEqual(response.json()['message'],
                     'Notification sent successfully!')
