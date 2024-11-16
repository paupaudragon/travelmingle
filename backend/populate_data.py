import json
from api.models import User, Post, PostImage
import os
import django

# Set up Django environment
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'backend.settings')
django.setup()


def populate_data():
    # Load JSON data
    with open('api/database.py', 'r') as file:
        data = json.load(file)
        posts = data['posts']

        for post_data in posts:
            post = Post.objects.create(
                title=post_data['title'],
                content=post_data['content'],
                author=post_data['author'],
                photo=f"postimages/{post_data['photo']}"
            )
            print(f"Created post: {post.title}")


if __name__ == '__main__':
    populate_data()
    print("Data population complete!")
