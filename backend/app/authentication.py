from rest_framework.authentication import BaseAuthentication
from rest_framework import exceptions
from django.utils import timezone
from oidc_provider.models import Token


class OIDCAuthentication(BaseAuthentication):
    """
    Authenticate incoming requests using standard OIDC Bearer tokens,
    with fallback to X-Username header for local dev/testing.
    """
    def authenticate(self, request):
        auth_header = request.headers.get('Authorization')
        if auth_header and auth_header.startswith('Bearer '):
            token_str = auth_header.split(' ', 1)[1].strip()
            try:
                token = Token.objects.filter(access_token=token_str).first()
                if token:
                    return (token.user, token)
            except Exception:
                pass

        # Dev / Testing fallback header
        dev_user = request.headers.get('X-Username')
        if dev_user:
            from django.contrib.auth.models import User
            try:
                user = User.objects.filter(username=dev_user).first()
                if user:
                    return (user, None)
            except Exception:
                pass

        return None
