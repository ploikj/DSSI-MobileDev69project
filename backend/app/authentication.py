from rest_framework.authentication import BaseAuthentication
from rest_framework import exceptions
from django.utils import timezone
from oidc_provider.models import Token


class OIDCAuthentication(BaseAuthentication):
    """
    Authenticate incoming requests using standard OIDC Bearer tokens.
    """
    def authenticate(self, request):
        auth_header = request.headers.get('Authorization')
        if not auth_header or not auth_header.startswith('Bearer '):
            return None

        token_str = auth_header.split(' ', 1)[1].strip()
        try:
            token = Token.objects.get(access_token=token_str)
            if token.expires_at < timezone.now():
                raise exceptions.AuthenticationFailed('OIDC Access Token has expired')
            return (token.user, token)
        except Token.DoesNotExist:
            # Let other authenticators (e.g. JWTAuthentication) try
            return None
