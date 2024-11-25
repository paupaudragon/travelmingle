from drf_yasg import openapi
from drf_yasg.utils import swagger_auto_schema
from rest_framework.generics import ListCreateAPIView, RetrieveUpdateDestroyAPIView
from ..models import CollectionFolders, Collects
from ..serializers import CollectionFolderSerializer, CollectSerializer


class CollectionFolderListCreateView(ListCreateAPIView):
    """
    Handles listing and creating Collection Folders.
    """
    queryset = CollectionFolders.objects.select_related('user').all()
    serializer_class = CollectionFolderSerializer

    @swagger_auto_schema(
        operation_summary="List all collection folders",
        operation_description=(
            "Retrieve a list of all collection folders. Each folder includes details about the user and the folder's creation time."
        ),
        responses={200: CollectionFolderSerializer(many=True)}
    )
    def get(self, request, *args, **kwargs):
        return super().get(request, *args, **kwargs)

    @swagger_auto_schema(
        operation_summary="Create a new collection folder",
        operation_description="Create a new collection folder for a user by providing the folder's name and the user's ID.",
        request_body=openapi.Schema(
            type=openapi.TYPE_OBJECT,
            properties={
                "user_id": openapi.Schema(type=openapi.TYPE_INTEGER, description="ID of the user creating the folder."),
                "name": openapi.Schema(type=openapi.TYPE_STRING, description="Name of the new folder."),
            },
            required=["user_id", "name"]
        ),
        responses={201: CollectionFolderSerializer}
    )
    def post(self, request, *args, **kwargs):
        return super().post(request, *args, **kwargs)


class CollectionFolderDetailView(RetrieveUpdateDestroyAPIView):
    """
    Handles retrieving, updating, and deleting a single Collection Folder.
    """
    queryset = CollectionFolders.objects.select_related('user').all()
    serializer_class = CollectionFolderSerializer

    @swagger_auto_schema(
        operation_summary="Retrieve a collection folder",
        operation_description="Retrieve details of a specific collection folder by its ID, including the user and folder metadata.",
        responses={200: CollectionFolderSerializer}
    )
    def get(self, request, *args, **kwargs):
        return super().get(request, *args, **kwargs)

    @swagger_auto_schema(
        operation_summary="Update a collection folder",
        operation_description="Update the name of an existing collection folder. The user ID cannot be updated.",
        request_body=openapi.Schema(
            type=openapi.TYPE_OBJECT,
            properties={
                "name": openapi.Schema(type=openapi.TYPE_STRING, description="Updated name of the folder."),
            },
            required=["name"]
        ),
        responses={200: CollectionFolderSerializer}
    )
    def patch(self, request, *args, **kwargs):
        return super().patch(request, *args, **kwargs)

    @swagger_auto_schema(
        operation_summary="Delete a collection folder",
        operation_description="Delete a collection folder by its ID.",
        responses={204: "Collection folder deleted successfully."}
    )
    def delete(self, request, *args, **kwargs):
        return super().delete(request, *args, **kwargs)

# ---------------------------------
# Collection Views
# ---------------------------------


class CollectListCreateView(ListCreateAPIView):
    """
    Handles listing and creating Collects.
    """
    queryset = Collects.objects.select_related('user', 'post', 'folder').all()
    serializer_class = CollectSerializer

    @swagger_auto_schema(
        operation_summary="List all collects",
        operation_description=(
            "Retrieve a list of all collects. Each collect includes details about the user, post, and associated folder."
        ),
        responses={200: CollectSerializer(many=True)}
    )
    def get(self, request, *args, **kwargs):
        return super().get(request, *args, **kwargs)

    @swagger_auto_schema(
        operation_summary="Create a new collect",
        operation_description=(
            "Create a new collect to save a post into a folder. "
            "Provide `user_id` and `post_id`, and optionally `folder_id` to associate the collect with a specific folder."
        ),
        request_body=openapi.Schema(
            type=openapi.TYPE_OBJECT,
            properties={
                "user_id": openapi.Schema(type=openapi.TYPE_INTEGER, description="ID of the user collecting the post."),
                "post_id": openapi.Schema(type=openapi.TYPE_INTEGER, description="ID of the post to be collected."),
                "folder_id": openapi.Schema(type=openapi.TYPE_INTEGER, description="ID of the folder (optional)."),
            },
            required=["user_id", "post_id"]
        ),
        responses={201: CollectSerializer}
    )
    def post(self, request, *args, **kwargs):
        return super().post(request, *args, **kwargs)


class CollectDetailView(RetrieveUpdateDestroyAPIView):
    """
    Handles retrieving, updating, and deleting a single Collect.
    """
    queryset = Collects.objects.select_related('user', 'post', 'folder').all()
    serializer_class = CollectSerializer

    @swagger_auto_schema(
        operation_summary="Retrieve a collect",
        operation_description="Retrieve details of a specific collect by its ID, including the associated user, post, and folder.",
        responses={200: CollectSerializer}
    )
    def get(self, request, *args, **kwargs):
        return super().get(request, *args, **kwargs)

    @swagger_auto_schema(
        operation_summary="Update a collect",
        operation_description="Update a collect by changing the folder or associated post.",
        request_body=openapi.Schema(
            type=openapi.TYPE_OBJECT,
            properties={
                "folder_id": openapi.Schema(type=openapi.TYPE_INTEGER, description="ID of the folder (optional)."),
                "post_id": openapi.Schema(type=openapi.TYPE_INTEGER, description="ID of the post to be collected."),
            },
        ),
        responses={200: CollectSerializer}
    )
    def patch(self, request, *args, **kwargs):
        return super().patch(request, *args, **kwargs)

    @swagger_auto_schema(
        operation_summary="Delete a collect",
        operation_description="Delete a collect by its ID.",
        responses={204: "Collect deleted successfully."}
    )
    def delete(self, request, *args, **kwargs):
        return super().delete(request, *args, **kwargs)
