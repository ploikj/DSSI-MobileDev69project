from oidc_provider.lib.claims import ScopeClaims


def userinfo(claims, user):
    """
    Populate userinfo claims dictionary for OpenID Connect userinfo endpoint.
    """
    claims['sub'] = str(user.id)
    claims['name'] = f"{user.first_name} {user.last_name}".strip() or user.username
    claims['given_name'] = user.first_name or user.username
    claims['family_name'] = user.last_name or ''
    claims['preferred_username'] = user.username
    claims['email'] = user.email or f"{user.username}@ubu.ac.th"
    claims['email_verified'] = True
    claims['roles'] = ['staff' if user.is_staff else 'student']
    claims['is_staff'] = user.is_staff
    claims['is_superuser'] = user.is_superuser
    claims['student_id'] = getattr(user, 'student_id', f"66{user.id:06d}")
    return claims


class CustomScopeClaims(ScopeClaims):
    """
    Provide custom scope claims for OpenID Connect ID Tokens and UserInfo.
    """
    def scope_profile(self):
        return {
            'name': f"{self.user.first_name} {self.user.last_name}".strip() or self.user.username,
            'preferred_username': self.user.username,
            'given_name': self.user.first_name or self.user.username,
            'family_name': self.user.last_name or '',
        }

    def scope_email(self):
        return {
            'email': self.user.email or f"{self.user.username}@ubu.ac.th",
            'email_verified': True,
        }

    def scope_student_id(self):
        return {
            'student_id': getattr(self.user, 'student_id', f"66{self.user.id:06d}"),
        }

    def scope_phone(self):
        return {
            'phone_number': getattr(self.user, 'phone_number', '0812345678'),
        }
