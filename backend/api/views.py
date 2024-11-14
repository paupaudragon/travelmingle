from django.conf import settings
from django.http import JsonResponse
from .models import User, Post, Comment

from django.shortcuts import render
# def user_list(request):
#     users = User.objects.values()  # Get all users as dictionaries
#     return JsonResponse(list(users), safe=False)


# def post_list(request):
#     posts = Post.objects.values()  # Get all posts as dictionaries
#     return JsonResponse(list(posts), safe=False)


# def comment_list(request):
#     comments = Comment.objects.values()  # Get all comments as dictionaries
#     return JsonResponse(list(comments), safe=False)


def myapp(request):
    context = {
        'MEDIA_URL': settings.MEDIA_URL,
    }
    return render(request, 'main.html', context)
