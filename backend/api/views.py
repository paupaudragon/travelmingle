from rest_framework import status
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework.generics import ListCreateAPIView, RetrieveUpdateDestroyAPIView


###
from .models import User, Post, Comment
from .serializers import UserSerializer, PostSerializer, CommentSerializer  

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

    def get(self, request, post_id):
        post = Post.objects.prefetch_related('comments').get(pk=post_id)
        serializer = PostSerializer(post)
        return Response(serializer.data)

###
import logging
logger = logging.getLogger(__name__)

# Add Comment views
class CommentListCreateView(ListCreateAPIView):
    queryset = Comment.objects.select_related('user', 'post').all()
    serializer_class = CommentSerializer

    def perform_create(self, serializer):
        post = Post.objects.get(id=self.request.data.get('post'))
        user = User.objects.get(id=self.request.data.get('user'))
        parent_id = self.request.data.get('parent')

        parent_comment = None
        if parent_id:
            parent_comment = Comment.objects.filter(id=parent_id).first()

        serializer.save(
            post=post, 
            user=user, 
            parent=parent_comment,
            # image=self.request.FILES.get('image')  # Save uploaded image
        )

class CommentDetailView(RetrieveUpdateDestroyAPIView):
    queryset = Comment.objects.select_related('user', 'post').all()
    serializer_class = CommentSerializer