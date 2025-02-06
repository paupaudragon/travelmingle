from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from ..models import Posts
from ..serializers import PostSerializer
from django.db.models import F, FloatField
from django.db.models.functions import Power, Sqrt
from math import cos, radians


class NearbyPostsView(APIView):
    def get(self, request):
        try:
            latitude = float(request.query_params.get('latitude'))
            longitude = float(request.query_params.get('longitude'))
            radius = float(request.query_params.get('radius', 5))
            limit = int(request.query_params.get('limit', 20))
        except (TypeError, ValueError):
            return Response(
                {"error": "Invalid parameters"},
                status=status.HTTP_400_BAD_REQUEST
            )

        lat_km = 111.32
        lng_km = 111.32 * cos(radians(latitude))

        nearby_posts = Posts.objects.annotate(
            distance=Sqrt(
                Power((F('location__latitude') - latitude) * lat_km, 2, output_field=FloatField()) +
                Power((F('location__longitude') - longitude)
                      * lng_km, 2, output_field=FloatField()),
                output_field=FloatField()
            )
        ).filter(
            distance__lte=radius,
            parent_post__isnull=True
        ).order_by('distance')[:limit]

        serializer = PostSerializer(
            nearby_posts, many=True, context={'request': request})

        return Response({
            'posts': serializer.data,
            'count': len(serializer.data),
            'radius': radius,
            'center': {
                'latitude': latitude,
                'longitude': longitude
            }
        })
