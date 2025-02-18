from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from ..models import Posts
from ..serializers import PostSerializer
from django.db.models import F, FloatField
from django.db.models.functions import Power, Sqrt
from math import cos, radians

import re  # regular expressions
from django.db.models import Func, F, Value

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

        travel_types = request.query_params.get('travel_types', '').split(',')
        periods = request.query_params.get('periods', '').split(',')

        # Preprocess travel types and periods to remove spaces, special characters, and trim
        def preprocess_filter_values(values):
            processed = []
            for value in values:
                value = re.sub(r'[^\w]', '', value)  # Remove non-alphanumeric characters
                value = value.strip().lower()  # Trim and convert to lowercase
                if value:  # Add only if not empty
                    processed.append(value)
            return processed

        travel_types = preprocess_filter_values(travel_types)
        periods = preprocess_filter_values(periods)

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
        )

        # Normalize category dynamically using annotate
        nearby_posts = nearby_posts.annotate(
            normalized_category=Func(F('category'), function='LOWER')
        ).annotate(
            normalized_category=Func(F('normalized_category'), Value(' '), Value(''), function='REPLACE')
        )

        # Filter by travel types if provided
        if travel_types:
            nearby_posts = nearby_posts.filter(normalized_category__in=travel_types)

        # Filter by periods if provided
        if periods:
            nearby_posts = nearby_posts.filter(period__in=periods)

        nearby_posts = nearby_posts.order_by('distance')[:limit]

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
