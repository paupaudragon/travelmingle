from django.contrib import admin
from .models import Posts, PostImages,Users,Comments

admin.site.register(Posts)
admin.site.register(PostImages)
admin.site.register(Users)
admin.site.register(Comments)