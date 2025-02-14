from django.contrib.auth.models import AbstractUser
from django.db import models
from django.core.validators import FileExtensionValidator
from django.core.exceptions import ValidationError
from django.utils import timezone
from django.contrib.gis.geos import Point
from django.contrib.gis.db import models


class Users(AbstractUser):
    """
    Users model that extends the AbstractUser model to include additional fields and functionality.
    Attributes:
        email (EmailField): Unique email address for the user.
        bio (TextField): Optional bio for the user.
        profile_picture (ImageField): Optional profile picture for the user, uploaded to 'profile_pictures/'.
        created_at (DateTimeField): Timestamp when the user was created, automatically set.
        updated_at (DateTimeField): Timestamp when the user was last updated, automatically set.
        REQUIRED_FIELDS (list): List of fields required for user creation, includes 'email'.
        following (ManyToManyField): Many-to-many relationship to self through the Follow model, representing users this user is following.
    Meta:
        db_table (str): Name of the database table.
        indexes (list): List of database indexes for the model.
    Methods:
        __str__(): Returns the username of the user.
    """
    email = models.EmailField(unique=True)
    bio = models.TextField(blank=True, null=True)
    profile_picture = models.ImageField(
        upload_to='profile_pictures/',
        null=True,
        blank=True
    )
    # Automatically set when created
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    REQUIRED_FIELDS = ['email']

    following = models.ManyToManyField(
        'self',
        through='Follow',
        through_fields=('follower', 'following'),
        symmetrical=False,
        related_name='followers_set'
    )

    class Meta:
        db_table = 'users'
        indexes = [
            models.Index(fields=['username']),
            models.Index(fields=['email']),
        ]

    def __str__(self):
        return self.username

##########################  NEW   ###################################


class Location(models.Model):
    """
    Represents a location from Google Maps API.
    Attributes:
        place_id (CharField): Unique identifier from Google Maps
        name (CharField): Human-readable location name
        address (CharField): Full address of the location
        latitude (DecimalField): Latitude coordinate
        longitude (DecimalField): Longitude coordinate
        point (PointField): Geographic point representation
        created_at (DateTimeField): Timestamp of creation
    """
    place_id = models.CharField(max_length=255, unique=True)
    name = models.CharField(max_length=255)
    address = models.CharField(max_length=512)
    latitude = models.DecimalField(max_digits=9, decimal_places=6)
    longitude = models.DecimalField(max_digits=9, decimal_places=6)
    point = models.PointField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def save(self, *args, **kwargs):
        # Create point field from lat/long if not set
        if self.latitude and self.longitude and not self.point:
            self.point = Point(float(self.longitude), float(self.latitude))
        super().save(*args, **kwargs)

    class Meta:
        db_table = "locations"
        indexes = [
            models.Index(fields=["place_id"]),
            models.Index(fields=["name"]),
            models.Index(fields=['latitude', 'longitude']),
        ]

    def __str__(self):
        return self.name


class Posts(models.Model):
    """
    Represents a post created by a user.
    Attributes:
        id (BigAutoField): The primary key for the post.
        user (ForeignKey): The user who created the post, linked to the Users model.
        title (CharField): The title of the post, optional.
        content (TextField): The content of the post, optional.
        location (CharField): The location associated with the post, optional.
        created_at (DateTimeField): The timestamp when the post was created.
        updated_at (DateTimeField): The timestamp when the post was last updated.
        status (CharField): The publication status of the post, can be 'draft' or 'published'.
        visibility (CharField): The visibility of the post, can be 'public', 'private', or 'friends'.
    Meta:
        db_table (str): The name of the database table.
        indexes (list): The list of indexes for the model.
    Methods:
        __str__(): Returns a string representation of the post.
    """
    CATEGORY_CHOICES = [
        ('adventure', 'Adventure'),
        ('hiking', 'Hiking'),
        ('skiing', 'Skiing'),
        ('roadtrip', 'Road Trip'),
        ('foodtour', 'Food Tour'),
        ('others', 'Others')
    ]
    PERIOD_CHOICES = [
        ('oneday', 'One Day'),
        ('multipleday', 'Multiple Day'),
    ]
    STATUS_CHOICES = [
        ('draft', 'Draft'),
        ('published', 'Published'),
    ]
    VISIBILITY_CHOICES = [
        ('public', 'Public'),
        ('private', 'Private'),
        ('friends', 'Friends Only'),
    ]
    id = models.BigAutoField(primary_key=True)
    user = models.ForeignKey(
        Users, on_delete=models.CASCADE, related_name="posts")
    title = models.CharField(max_length=255, blank=True, null=True)
    content = models.TextField(blank=True, null=True)

    # New location field for Post detail view
    location = models.ForeignKey(
        Location,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='posts'
    )

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    status = models.CharField(
        max_length=20, choices=STATUS_CHOICES, default='published')

    visibility = models.CharField(
        max_length=20, choices=VISIBILITY_CHOICES, default='public')

    # New category field for Filter feature
    category = models.CharField(
        max_length=20,
        help_text="Category of the post, e.g., 'Adventure', 'Hiking'."
    )

    period = models.CharField(
        max_length=20,
        choices=PERIOD_CHOICES,
    )
    hashtags = models.TextField(
        blank=True,
        null=True,
        help_text="Comma-separated hashtags (e.g., #travel, #nature)"
    )

    parent_post = models.ForeignKey(
        'self', on_delete=models.CASCADE, null=True, blank=True, related_name="child_posts"
    )

    class Meta:
        db_table = "posts"
        indexes = [
            models.Index(fields=["user"]),
            models.Index(fields=["created_at"]),
            # New index for category filtering
            models.Index(fields=["category"]),
            models.Index(fields=["period"]),  # New index for period filtering
            models.Index(fields=["location"]),
        ]

    def __str__(self):
        if self.parent_post:
            return f"Day Post: {self.title} (Parent: {self.parent_post.title})"
        return f"Post: {self.title or 'Untitled'} by {self.user.username}"


class PostImages(models.Model):
    """
    Model representing images associated with posts.
    Attributes:
        id (BigAutoField): Primary key for the PostImages model.
        post (ForeignKey): Foreign key to the Posts model, with a cascade delete option and a related name of 'images'.
        image (ImageField): Field to store the URL/path of the image, with upload location set to 'post_images/' and 
                            validators to allow only 'jpg', 'jpeg', and 'png' file extensions.
        created_at (DateTimeField): Timestamp indicating when the image was created, automatically set to the current date and time.
    Meta:
        db_table (str): Name of the database table to use for the PostImages model.
    Methods:
        __str__: Returns a string representation of the image, including the post title (or 'Untitled' if no title) and the image name.
    """
    id = models.BigAutoField(primary_key=True)
    post = models.ForeignKey(
        Posts, on_delete=models.CASCADE, related_name="images")
    # Store the URL/path of the image
    image = models.ImageField(
        upload_to="postImages/",
        null=True,
        blank=True,
    )
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = "post_images"

    def __str__(self):
        return f"Image for Post: {self.post.title or 'Untitled'} ({self.image.name})"


class Comments(models.Model):
    """
    Comments model represents user comments on posts within the application.
    Attributes:
        id (AutoField): Primary key for the comment.
        user (ForeignKey): The user who made the comment, linked to the Users model.
        post (ForeignKey): The post to which the comment belongs, linked to the Posts model.
        content (TextField): The content of the comment, which may include @mentions.
        mentioned_users (ManyToManyField): Users mentioned in the comment, linked to the Users model.
        reply_to (ForeignKey): Tracks if this comment is a reply to another comment, linked to the Comments model itself.
        created_at (DateTimeField): Timestamp when the comment was created.
        updated_at (DateTimeField): Timestamp when the comment was last updated.
    Meta:
        db_table (str): Name of the database table.
        indexes (list): List of indexes for efficient querying.
    Methods:
        __str__(): Returns a string representation of the comment, indicating whether it is a reply or a standalone comment.
    """
    id = models.AutoField(primary_key=True)
    # The user who made the comment
    user = models.ForeignKey(
        Users, on_delete=models.CASCADE, related_name="comments")
    # Every comment belongs to a post
    post = models.ForeignKey(Posts, on_delete=models.CASCADE)
    # The comment content, which may include @mentions
    content = models.TextField(blank=True, null=True)
    mentioned_users = models.ManyToManyField(  # Users mentioned in the comment
        Users,
        related_name="mentioned_in",
        blank=True,
        help_text="Users mentioned in the comment",
    )
    reply_to = models.ForeignKey(  # Tracks if this comment is a reply to another comment
        'self',
        null=True,
        blank=True,
        on_delete=models.CASCADE,
        related_name="replies",
        help_text="The comment this comment is replying to",
    )
    comment_image = models.ImageField(
        upload_to='comment_images/',
        null=True,
        blank=True,
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'comments'
        indexes = [
            models.Index(fields=["post"]),  # For efficient filtering by post
            models.Index(fields=["user"]),  # For filtering comments by a user
            # For efficient filtering of replies
            models.Index(fields=["reply_to"]),
        ]

    def __str__(self):
        if self.parent:
            return f"Reply by {self.user.username} to Comment {self.parent.id}"
        return f"Comment by {self.user.username} on Post {self.post.title if self.post else 'Unknown'}"


class Likes(models.Model):
    """
    Represents a 'Like' in the system, which can be associated with either a post or a comment.
    Attributes:
        id (BigAutoField): The primary key for the like.
        user (ForeignKey): The user who liked the post or comment.
        post (ForeignKey): The post that was liked (nullable).
        comment (ForeignKey): The comment that was liked (nullable).
        created_at (DateTimeField): The timestamp when the like was created.
    Methods:
        clean(): Validates that a like is associated with either a post or a comment, but not both.
        __str__(): Returns a string representation of the like, indicating the user and the liked post or comment.
    Meta:
        db_table (str): The name of the database table to use for this model.
    """
    id = models.BigAutoField(primary_key=True)
    user = models.ForeignKey(
        Users, on_delete=models.CASCADE, related_name="likes")
    post = models.ForeignKey(Posts, on_delete=models.CASCADE,
                             blank=True, null=True, related_name="post_likes")
    comment = models.ForeignKey(
        Comments, on_delete=models.CASCADE, blank=True, null=True, related_name="comment_likes")
    created_at = models.DateTimeField(auto_now_add=True)

    def clean(self):
        if not self.post and not self.comment:
            raise ValidationError(
                "A like must be associated with either a post or a comment.")
        if self.post and self.comment:
            raise ValidationError(
                "A like cannot be associated with both a post and a comment.")

    class Meta:
        db_table = "likes"

    def __str__(self):
        if self.post:
            return f"Like by {self.user.username} on Post {self.post.title}"
        return f"Like by {self.user.username} on Comment {self.comment.content[:20]}"


class CollectionFolders(models.Model):
    """
    CollectionFolders model represents a folder that groups collections for a specific user.
    Attributes:
        id (BigAutoField): The primary key for the folder.
        user (ForeignKey): A reference to the user who owns the folder.
        name (CharField): The name of the folder.
        created_at (DateTimeField): The timestamp when the folder was created.
        updated_at (DateTimeField): The timestamp when the folder was last updated.
    Meta:
        db_table (str): The name of the database table.
        unique_together (tuple): Ensures that each user can have folders with unique names.
    Methods:
        __str__(): Returns a string representation of the folder, including its name and the username of the owner.
    """
    id = models.BigAutoField(primary_key=True)
    user = models.ForeignKey(
        Users, on_delete=models.CASCADE, related_name="folders"
    )  # The user who owns the folder
    name = models.CharField(max_length=255)  # Folder name
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = "collection_folders"
        unique_together = ("user", "name")

    def __str__(self):
        return f"Folder: {self.name} (User: {self.user.username})"


class Collects(models.Model):
    """
    Represents a collection of posts by users, optionally organized into folders.
    Attributes:
        id (BigAutoField): The primary key for the collection.
        user (ForeignKey): The user who collected the post, related to the Users model.
        post (ForeignKey): The collected post, related to the Posts model.
        folder (ForeignKey): The folder where the post is organized, related to the CollectionFolders model. Can be null or blank.
        created_at (DateTimeField): The timestamp when the collection was created.
    Meta:
        db_table (str): The name of the database table.
        unique_together (tuple): Ensures that the combination of user, post, and folder is unique.
    Methods:
        __str__(): Returns a string representation of the collection, including the post title, folder name (if any), and username.
    """
    id = models.BigAutoField(primary_key=True)
    user = models.ForeignKey(
        Users, on_delete=models.CASCADE, related_name="collecter"
    )  # The user who collected the post
    post = models.ForeignKey(
        Posts, on_delete=models.CASCADE,
        blank=True, null=True, related_name="post_saves"
    )  # The collected post
    folder = models.ForeignKey(
        CollectionFolders, on_delete=models.CASCADE, related_name="collections", null=True, blank=True
    )  # Folder where the post is organized
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = "collects"
        unique_together = ("user", "post", "folder")

    def __str__(self):
        if self.folder:
            return f"Post {self.post.title or 'Untitled'} collected in Folder {self.folder.name} by {self.user.username}"
        return f"Post {self.post.title or 'Untitled'} collected by {self.user.username}"


class Notifications(models.Model):
    id = models.BigAutoField(primary_key=True)
    recipient = models.ForeignKey(
        Users,
        on_delete=models.CASCADE,
        related_name="notifications"
    )
    sender = models.ForeignKey(
        Users,
        on_delete=models.CASCADE,
        related_name="sent_notifications"
    )
    post = models.ForeignKey(
        Posts,
        on_delete=models.CASCADE,
        null=True,
        blank=True,
        related_name="notifications"
    )
    comment = models.ForeignKey(
        Comments,
        on_delete=models.CASCADE,
        null=True,
        blank=True,
        related_name="notifications"
    )
    notification_type = models.CharField(
        max_length=50,
        choices=[
            ("like_post", "Like Post"),
            ("like_comment", "Like Comment"),
            ("comment", "Comment"),
            ("reply", "Reply"),
            ("mention", "Mention"),
            ("collect", "Collect"),
            ("follow", "Follow"),
        ]
    )
    message = models.CharField(max_length=255)
    is_read = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = "notifications"
        indexes = [
            models.Index(fields=["recipient"]),
            models.Index(fields=["is_read"]),
            models.Index(fields=["created_at"]),
        ]
        ordering = ['-created_at']  # Show newest notifications first

    def __str__(self):
        return f"Notification for {self.recipient.username}: {self.notification_type}"


class Follow(models.Model):
    """
    Model representing a follow relationship between users.
    Attributes:
        follower (ForeignKey): The user who is following another user.
        following (ForeignKey): The user who is being followed.
        created_at (DateTimeField): The timestamp when the follow relationship was created.
    Meta:
        db_table (str): The name of the database table.
        unique_together (tuple): Ensures that a user cannot follow another user more than once.
        indexes (list): Database indexes for the follower and following fields.
    Methods:
        __str__(): Returns a string representation of the follow relationship.
    """
    follower = models.ForeignKey(
        Users, on_delete=models.CASCADE, related_name='following_relationships')
    following = models.ForeignKey(
        Users, on_delete=models.CASCADE, related_name='follower_relationships')
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'follows'
        unique_together = ('follower', 'following')
        indexes = [
            models.Index(fields=['follower']),
            models.Index(fields=['following']),
        ]

    def __str__(self):
        return f"{self.follower.username} follows {self.following.username}"

# Add for role-based relationship


class Profile(models.Model):
    user = models.OneToOneField(
        Users, on_delete=models.CASCADE, related_name='profile')
    ROLE_CHOICES = [
        ('admin', 'Admin'),
        ('user', 'User'),
    ]
    role = models.CharField(
        max_length=10,
        choices=ROLE_CHOICES,
        default='user'
    )

    class Meta:
        db_table = 'profiles'

    def __str__(self):
        return f"{self.user.username} - {self.role}"


############ Notifications ##################
class Device(models.Model):
    user = models.ForeignKey(Users, on_delete=models.CASCADE)
    token = models.CharField(max_length=255, unique=True)  # Store FCM token
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.user.username} - {self.token}"
