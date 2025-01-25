# Generated by Django 5.1.3 on 2025-01-25 00:54

import django.contrib.auth.models
import django.contrib.auth.validators
import django.contrib.gis.db.models.fields
import django.db.models.deletion
import django.utils.timezone
from django.conf import settings
from django.db import migrations, models


class Migration(migrations.Migration):

    initial = True

    dependencies = [
        ('auth', '0012_alter_user_first_name_max_length'),
    ]

    operations = [
        migrations.CreateModel(
            name='Users',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('password', models.CharField(max_length=128, verbose_name='password')),
                ('last_login', models.DateTimeField(blank=True, null=True, verbose_name='last login')),
                ('is_superuser', models.BooleanField(default=False, help_text='Designates that this user has all permissions without explicitly assigning them.', verbose_name='superuser status')),
                ('username', models.CharField(error_messages={'unique': 'A user with that username already exists.'}, help_text='Required. 150 characters or fewer. Letters, digits and @/./+/-/_ only.', max_length=150, unique=True, validators=[django.contrib.auth.validators.UnicodeUsernameValidator()], verbose_name='username')),
                ('first_name', models.CharField(blank=True, max_length=150, verbose_name='first name')),
                ('last_name', models.CharField(blank=True, max_length=150, verbose_name='last name')),
                ('is_staff', models.BooleanField(default=False, help_text='Designates whether the user can log into this admin site.', verbose_name='staff status')),
                ('is_active', models.BooleanField(default=True, help_text='Designates whether this user should be treated as active. Unselect this instead of deleting accounts.', verbose_name='active')),
                ('date_joined', models.DateTimeField(default=django.utils.timezone.now, verbose_name='date joined')),
                ('email', models.EmailField(max_length=254, unique=True)),
                ('bio', models.TextField(blank=True, null=True)),
                ('profile_picture', models.ImageField(blank=True, null=True, upload_to='profile_pictures/')),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('updated_at', models.DateTimeField(auto_now=True)),
                ('groups', models.ManyToManyField(blank=True, help_text='The groups this user belongs to. A user will get all permissions granted to each of their groups.', related_name='user_set', related_query_name='user', to='auth.group', verbose_name='groups')),
                ('user_permissions', models.ManyToManyField(blank=True, help_text='Specific permissions for this user.', related_name='user_set', related_query_name='user', to='auth.permission', verbose_name='user permissions')),
            ],
            options={
                'db_table': 'users',
            },
            managers=[
                ('objects', django.contrib.auth.models.UserManager()),
            ],
        ),
        migrations.CreateModel(
            name='CollectionFolders',
            fields=[
                ('id', models.BigAutoField(primary_key=True, serialize=False)),
                ('name', models.CharField(max_length=255)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('updated_at', models.DateTimeField(auto_now=True)),
                ('user', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='folders', to=settings.AUTH_USER_MODEL)),
            ],
            options={
                'db_table': 'collection_folders',
                'unique_together': {('user', 'name')},
            },
        ),
        migrations.CreateModel(
            name='Comments',
            fields=[
                ('id', models.AutoField(primary_key=True, serialize=False)),
                ('content', models.TextField(blank=True, null=True)),
                ('comment_image', models.ImageField(blank=True, null=True, upload_to='comment_images/')),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('updated_at', models.DateTimeField(auto_now=True)),
                ('mentioned_users', models.ManyToManyField(blank=True, help_text='Users mentioned in the comment', related_name='mentioned_in', to=settings.AUTH_USER_MODEL)),
                ('reply_to', models.ForeignKey(blank=True, help_text='The comment this comment is replying to', null=True, on_delete=django.db.models.deletion.CASCADE, related_name='replies', to='api.comments')),
                ('user', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='comments', to=settings.AUTH_USER_MODEL)),
            ],
            options={
                'db_table': 'comments',
            },
        ),
        migrations.CreateModel(
            name='Follow',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('follower', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='following_relationships', to=settings.AUTH_USER_MODEL)),
                ('following', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='follower_relationships', to=settings.AUTH_USER_MODEL)),
            ],
            options={
                'db_table': 'follows',
            },
        ),
        migrations.AddField(
            model_name='users',
            name='following',
            field=models.ManyToManyField(related_name='followers_set', through='api.Follow', to=settings.AUTH_USER_MODEL),
        ),
        migrations.CreateModel(
            name='Location',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('place_id', models.CharField(max_length=255, unique=True)),
                ('name', models.CharField(max_length=255)),
                ('address', models.CharField(max_length=512)),
                ('latitude', models.DecimalField(decimal_places=6, max_digits=9)),
                ('longitude', models.DecimalField(decimal_places=6, max_digits=9)),
                ('point', django.contrib.gis.db.models.fields.PointField(blank=True, null=True, srid=4326)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
            ],
            options={
                'db_table': 'locations',
                'indexes': [models.Index(fields=['place_id'], name='locations_place_i_9ae14d_idx'), models.Index(fields=['name'], name='locations_name_ce8723_idx')],
            },
        ),
        migrations.CreateModel(
            name='Posts',
            fields=[
                ('id', models.BigAutoField(primary_key=True, serialize=False)),
                ('title', models.CharField(blank=True, max_length=255, null=True)),
                ('content', models.TextField(blank=True, null=True)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('updated_at', models.DateTimeField(auto_now=True)),
                ('status', models.CharField(choices=[('draft', 'Draft'), ('published', 'Published')], default='published', max_length=20)),
                ('visibility', models.CharField(choices=[('public', 'Public'), ('private', 'Private'), ('friends', 'Friends Only')], default='public', max_length=20)),
                ('category', models.CharField(help_text="Category of the post, e.g., 'Adventure', 'Hiking'.", max_length=20)),
                ('period', models.CharField(choices=[('oneday', 'One Day'), ('multipleday', 'Multiple Day')], max_length=20)),
                ('hashtags', models.TextField(blank=True, help_text='Comma-separated hashtags (e.g., #travel, #nature)', null=True)),
                ('location', models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.SET_NULL, related_name='posts', to='api.location')),
                ('parent_post', models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.CASCADE, related_name='child_posts', to='api.posts')),
                ('user', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='posts', to=settings.AUTH_USER_MODEL)),
            ],
            options={
                'db_table': 'posts',
            },
        ),
        migrations.CreateModel(
            name='PostImages',
            fields=[
                ('id', models.BigAutoField(primary_key=True, serialize=False)),
                ('image', models.ImageField(blank=True, null=True, upload_to='postImages/')),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('post', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='images', to='api.posts')),
            ],
            options={
                'db_table': 'post_images',
            },
        ),
        migrations.CreateModel(
            name='Notifications',
            fields=[
                ('id', models.BigAutoField(primary_key=True, serialize=False)),
                ('notification_type', models.CharField(choices=[('reply', 'Reply'), ('mention', 'Mention'), ('collection', 'Collection')], max_length=50)),
                ('message', models.CharField(max_length=255)),
                ('is_read', models.BooleanField(default=False)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('comment', models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.CASCADE, related_name='notifications', to='api.comments')),
                ('recipient', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='notifications', to=settings.AUTH_USER_MODEL)),
                ('sender', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='sent_notifications', to=settings.AUTH_USER_MODEL)),
                ('post', models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.CASCADE, related_name='notifications', to='api.posts')),
            ],
            options={
                'db_table': 'notifications',
            },
        ),
        migrations.CreateModel(
            name='Likes',
            fields=[
                ('id', models.BigAutoField(primary_key=True, serialize=False)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('comment', models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.CASCADE, related_name='comment_likes', to='api.comments')),
                ('user', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='likes', to=settings.AUTH_USER_MODEL)),
                ('post', models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.CASCADE, related_name='post_likes', to='api.posts')),
            ],
            options={
                'db_table': 'likes',
            },
        ),
        migrations.AddField(
            model_name='comments',
            name='post',
            field=models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, to='api.posts'),
        ),
        migrations.CreateModel(
            name='Collects',
            fields=[
                ('id', models.BigAutoField(primary_key=True, serialize=False)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('folder', models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.CASCADE, related_name='collections', to='api.collectionfolders')),
                ('user', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='collecter', to=settings.AUTH_USER_MODEL)),
                ('post', models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.CASCADE, related_name='post_saves', to='api.posts')),
            ],
            options={
                'db_table': 'collects',
            },
        ),
        migrations.CreateModel(
            name='Profile',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('role', models.CharField(choices=[('admin', 'Admin'), ('user', 'User')], default='user', max_length=10)),
                ('user', models.OneToOneField(on_delete=django.db.models.deletion.CASCADE, related_name='profile', to=settings.AUTH_USER_MODEL)),
            ],
            options={
                'db_table': 'profiles',
            },
        ),
        migrations.AddIndex(
            model_name='follow',
            index=models.Index(fields=['follower'], name='follows_followe_ca9b09_idx'),
        ),
        migrations.AddIndex(
            model_name='follow',
            index=models.Index(fields=['following'], name='follows_followi_dcb467_idx'),
        ),
        migrations.AlterUniqueTogether(
            name='follow',
            unique_together={('follower', 'following')},
        ),
        migrations.AddIndex(
            model_name='users',
            index=models.Index(fields=['username'], name='users_usernam_baeb4b_idx'),
        ),
        migrations.AddIndex(
            model_name='users',
            index=models.Index(fields=['email'], name='users_email_4b85f2_idx'),
        ),
        migrations.AddIndex(
            model_name='posts',
            index=models.Index(fields=['user'], name='posts_user_id_05c508_idx'),
        ),
        migrations.AddIndex(
            model_name='posts',
            index=models.Index(fields=['created_at'], name='posts_created_060265_idx'),
        ),
        migrations.AddIndex(
            model_name='posts',
            index=models.Index(fields=['category'], name='posts_categor_c9aadc_idx'),
        ),
        migrations.AddIndex(
            model_name='posts',
            index=models.Index(fields=['period'], name='posts_period_ead688_idx'),
        ),
        migrations.AddIndex(
            model_name='posts',
            index=models.Index(fields=['location'], name='posts_locatio_7f484b_idx'),
        ),
        migrations.AddIndex(
            model_name='notifications',
            index=models.Index(fields=['recipient'], name='notificatio_recipie_1dd18d_idx'),
        ),
        migrations.AddIndex(
            model_name='notifications',
            index=models.Index(fields=['is_read'], name='notificatio_is_read_3f8c44_idx'),
        ),
        migrations.AddIndex(
            model_name='notifications',
            index=models.Index(fields=['created_at'], name='notificatio_created_e4c995_idx'),
        ),
        migrations.AddIndex(
            model_name='comments',
            index=models.Index(fields=['post'], name='comments_post_id_7ee550_idx'),
        ),
        migrations.AddIndex(
            model_name='comments',
            index=models.Index(fields=['user'], name='comments_user_id_8613ff_idx'),
        ),
        migrations.AddIndex(
            model_name='comments',
            index=models.Index(fields=['reply_to'], name='comments_reply_t_6b9e9a_idx'),
        ),
        migrations.AlterUniqueTogether(
            name='collects',
            unique_together={('user', 'post', 'folder')},
        ),
    ]
