from django.contrib.auth.models import AbstractUser
from django.db import models
from django.core.validators import FileExtensionValidator
from django.core.exceptions import ValidationError
from django.utils import timezone


class Users(AbstractUser):
    email = models.EmailField(unique=True)
    bio = models.TextField(blank=True, null=True)
    profile_picture = models.ImageField(
        upload_to='profile_pictures/',
        null=True,
        blank=True
    )
    # Automatically set when created
    created_at = models.DateTimeField(auto_now_add=True)
    # Automatically updated on save
    updated_at = models.DateTimeField(auto_now=True)

    REQUIRED_FIELDS = ['email']

    class Meta:
        db_table = 'users'
        indexes = [
            models.Index(fields=['username']),
            models.Index(fields=['email']),
        ]

    def __str__(self):
        return self.username


class Posts(models.Model):
    """
    Posts model representing a user's post in the application.
    Attributes:
        id (BigAutoField): Primary key for the post.
        user (ForeignKey): Reference to the user who created the post.
        title (CharField): Title of the post, optional.
        content (TextField): Content of the post, optional.
        created_at (DateTimeField): Timestamp when the post was created.
        updated_at (DateTimeField): Timestamp when the post was last updated.
        status (CharField): Status of the post, either 'draft' or 'published'.
        visibility (CharField): Visibility of the post, either 'public', 'private', or 'friends'.
    Meta:
        db_table (str): Name of the database table.
        indexes (list): List of indexes for the model.
    Methods:
        __str__: Returns a string representation of the post.
    """
    id = models.BigAutoField(primary_key=True)
    user = models.ForeignKey(
        Users, on_delete=models.CASCADE, related_name="posts")
    title = models.CharField(max_length=255, blank=True, null=True)
    content = models.TextField(blank=True, null=True)

    location = models.CharField(
        max_length=255, blank=True, null=True)  # forced

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    STATUS_CHOICES = [
        ('draft', 'Draft'),
        ('published', 'Published'),
    ]
    status = models.CharField(
        max_length=20, choices=STATUS_CHOICES, default='published')

    VISIBILITY_CHOICES = [
        ('public', 'Public'),
        ('private', 'Private'),
        ('friends', 'Friends Only'),
    ]
    visibility = models.CharField(
        max_length=20, choices=VISIBILITY_CHOICES, default='public')

    class Meta:
        db_table = "posts"
        indexes = [
            models.Index(fields=["user"]),
            models.Index(fields=["created_at"]),
        ]

    def __str__(self):
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
        upload_to="post_images/",
        validators=[FileExtensionValidator(
            allowed_extensions=["jpg", "jpeg", "png"])]
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
    content = models.TextField()  # The comment content, which may include @mentions
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
        Users, on_delete=models.CASCADE, related_name="collections"
    )  # The user who collected the post
    post = models.ForeignKey(
        Posts, on_delete=models.CASCADE, related_name="collected_by"
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
    """
    Notifications model to store information about notifications sent to users.
    Attributes:
        id (BigAutoField): Primary key for the notification.
        recipient (ForeignKey): The user who will receive the notification.
        sender (ForeignKey): The user who triggered this notification.
        post (ForeignKey): The post associated with the notification (optional).
        comment (ForeignKey): The comment associated with the notification (optional).
        notification_type (CharField): Type of notification (e.g., reply, mention, collection).
        message (CharField): Notification message for display.
        is_read (BooleanField): Track if the user has read the notification.
        created_at (DateTimeField): Timestamp when the notification was created.
    Meta:
        db_table (str): Name of the database table.
        indexes (list): List of indexes for the model.
    Methods:
        __str__: Returns a string representation of the notification.
    """
    id = models.BigAutoField(primary_key=True)
    recipient = models.ForeignKey(
        Users, on_delete=models.CASCADE, related_name="notifications"
    )  # The user who will receive the notification
    sender = models.ForeignKey(
        Users, on_delete=models.CASCADE, related_name="sent_notifications"
    )  # The user who triggered this notification
    post = models.ForeignKey(
        Posts, on_delete=models.CASCADE, null=True, blank=True, related_name="notifications"
    )  # The post associated with the notification
    comment = models.ForeignKey(
        Comments, on_delete=models.CASCADE, null=True, blank=True, related_name="notifications"
    )  # The comment associated with the notification (if applicable)
    notification_type = models.CharField(
        max_length=50,
        choices=[
            ("reply", "Reply"),
            ("mention", "Mention"),
            # New type for collection notifications
            ("collection", "Collection"),
        ]
    )  # Type of notification
    # Notification message for display
    message = models.CharField(max_length=255)
    # Track if the user has read the notification
    is_read = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = "notifications"
        indexes = [
            models.Index(fields=["recipient"]),
            models.Index(fields=["is_read"]),
            models.Index(fields=["created_at"]),
        ]

    def __str__(self):
        return f"Notification for {self.recipient.username}: {self.notification_type}"
