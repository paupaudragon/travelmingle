from django.db import models


class User(models.Model):
    id = models.AutoField(primary_key=True)
    username = models.CharField(max_length=50, unique=True)
    email = models.CharField(max_length=100, unique=True)
    password = models.CharField(max_length=100)
    bio = models.TextField(null=True, blank=True)
    profile_picture = models.ImageField(
        upload_to='profiles/', null=True, blank=True)
    created_at = models.DateTimeField()
    updated_at = models.DateTimeField()

    class Meta:
        db_table = 'users'


class Post(models.Model):
    id = models.AutoField(primary_key=True)
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    title = models.CharField(max_length=255)
    content = models.TextField()
    created_at = models.DateTimeField()
    updated_at = models.DateTimeField()

    class Meta:
        db_table = 'posts'


class PostImage(models.Model):
    id = models.AutoField(primary_key=True)
    post = models.ForeignKey(
        Post, related_name='images', on_delete=models.CASCADE)
    image = models.ImageField(upload_to='postImages/')
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'post_images'


class Comment(models.Model):
    id = models.AutoField(primary_key=True)
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    post = models.ForeignKey(Post, on_delete=models.CASCADE)
    content = models.TextField()
    created_at = models.DateTimeField()
    updated_at = models.DateTimeField()

    class Meta:
        db_table = 'comments'
