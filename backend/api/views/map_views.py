from django.http import JsonResponse
from ..utils import geocode_address


def get_location(request):
    address = request.GET.get('address')
    location = geocode_address(address)
    return JsonResponse(location)
