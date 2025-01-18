from django.core.management.base import BaseCommand
from api.models import Users, Profile


class Command(BaseCommand):
    help = 'Creates missing profiles for users'

    def handle(self, *args, **kwargs):
        users_without_profile = Users.objects.filter(profile__isnull=True)
        created_count = 0

        for user in users_without_profile:
            Profile.objects.create(user=user, role='user')
            created_count += 1

        self.stdout.write(
            self.style.SUCCESS(
                f'Successfully created {created_count} missing profiles'
            )
        )
