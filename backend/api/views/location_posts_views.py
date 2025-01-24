from rest_framework.generics import ListAPIView
from ..models import Posts
from ..serializers import PostSerializer
from rest_framework.response import Response
from rest_framework import status


class PostListByLocationView(ListAPIView):
    serializer_class = PostSerializer

    def get_queryset(self):
        location_name = self.request.query_params.get('name')

        if location_name:
            return Posts.objects.filter(location__name=location_name)

        return Posts.objects.none()

    def list(self, request, *args, **kwargs):
        queryset = self.get_queryset()
        if not queryset.exists():
            return Response({"message": "No posts found for this location."}, status=status.HTTP_404_NOT_FOUND)

        serializer = self.get_serializer(queryset, many=True)
        return Response(serializer.data)
