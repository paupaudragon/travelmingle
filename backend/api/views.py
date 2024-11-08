from django.shortcuts import render

# Create your views here.
from django.http import JsonResponse


def simple_view(request):
    data = {
        'message': 'Hello from Django!'
    }
    return JsonResponse(data)
