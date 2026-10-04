from django.core.management import call_command
from django.core.management.base import BaseCommand
from django.contrib.auth.models import User
from oidc_provider.models import Client, ResponseType, RSAKey


class Command(BaseCommand):
    help = 'Seed OIDC Provider RSA keys, default Mobile Client, and demo users'

    def handle(self, *args, **kwargs):
        self.stdout.write('Seeding OIDC Provider configuration...')

        # 1. Ensure RSA Key exists for RS256 signing
        if not RSAKey.objects.exists():
            self.stdout.write('Generating RSA key for OIDC...')
            call_command('creatersakey')
            self.stdout.write(self.style.SUCCESS('RSA Key created successfully.'))
        else:
            self.stdout.write(self.style.SUCCESS('RSA Key already exists.'))

        # 2. Ensure ResponseType 'code' exists
        code_type, _ = ResponseType.objects.get_or_create(value='code')
        id_token_type, _ = ResponseType.objects.get_or_create(value='id_token')

        # 3. Create or update Default OIDC Client for Mobile App
        redirect_uris = [
            'http://127.0.0.1:8000/callback',
            'http://10.0.2.2:8000/callback',
            'http://localhost:8000/callback',
            'com.example.frontend://oauth2redirect',
            'app.flutter.oidc://callback',
        ]

        client, created = Client.objects.get_or_create(
            client_id='flutter-mobile-client',
            defaults={
                'name': 'UBU Mobile Booking App (OIDC Client)',
                'client_type': 'public',
                'jwt_alg': 'RS256',
                '_redirect_uris': '\n'.join(redirect_uris),
                '_scope': 'openid profile email',
                'require_consent': False,
                'reuse_consent': True,
            }
        )

        client.response_types.add(code_type)
        client.response_types.add(id_token_type)
        client.save()

        action_str = 'Created' if created else 'Updated'
        self.stdout.write(self.style.SUCCESS(
            f"{action_str} OIDC Client: {client.client_id} (Type: {client.client_type}, Alg: {client.jwt_alg})"
        ))

        # 4. Ensure demo users exist
        demo_users = [
            {
                'username': 'admin',
                'password': 'admin1234',
                'first_name': 'Admin',
                'last_name': 'IT Service',
                'email': 'admin@ubu.ac.th',
                'is_staff': True,
                'is_superuser': True,
            },
            {
                'username': 'narathip',
                'password': 'pass1234',
                'first_name': 'ณราธิป',
                'last_name': 'นันทสุรสีห์',
                'email': 'narathip.n@ubu.ac.th',
                'is_staff': False,
            },
            {
                'username': 'somchai',
                'password': 'pass1234',
                'first_name': 'สมชาย',
                'last_name': 'ใจมั่น',
                'email': 'somchai.j@ubu.ac.th',
                'is_staff': True,
            }
        ]

        for udata in demo_users:
            uname = udata['username']
            user, u_created = User.objects.get_or_create(username=uname)
            user.set_password(udata['password'])
            user.first_name = udata['first_name']
            user.last_name = udata['last_name']
            user.email = udata['email']
            user.is_staff = udata.get('is_staff', False)
            user.is_superuser = udata.get('is_superuser', False)
            user.save()
            u_status = 'Created' if u_created else 'Updated'
            self.stdout.write(f" - {u_status} user: {uname} (Password: {udata['password']})")

        self.stdout.write(self.style.SUCCESS('OIDC Seeding completed successfully!'))
