from rest_framework import status
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework.generics import ListCreateAPIView, RetrieveUpdateDestroyAPIView
from .models import User, Post
from .serializers import UserSerializer, PostSerializer

# List and Create Users


class UserListCreateView(ListCreateAPIView):
    queryset = User.objects.all()
    serializer_class = UserSerializer

# Retrieve, Update, Delete a single User


class UserDetailView(RetrieveUpdateDestroyAPIView):
    queryset = User.objects.all()
    serializer_class = UserSerializer

# List and Create Posts


class PostListCreateView(ListCreateAPIView):
    queryset = Post.objects.select_related('user').all()
    serializer_class = PostSerializer

    def perform_create(self, serializer):
        user = User.objects.get(id=self.request.data.get('user_id'))
        serializer.save(user=user)

# Retrieve, Update, Delete a single Post


class PostDetailView(RetrieveUpdateDestroyAPIView):
    queryset = Post.objects.select_related('user').all()
    serializer_class = PostSerializer
