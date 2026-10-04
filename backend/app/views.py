from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from .models import Equipment, Booking
from .serializers import EquipmentSerializer, BookingSerializer

class EquipmentListView(APIView):
    def get(self, request):
        category = request.query_params.get('category')
        search = request.query_params.get('search')
        
        queryset = Equipment.objects.all()
        if category and category != 'all':
            queryset = queryset.filter(category=category)
        if search:
            queryset = queryset.filter(name__icontains=search)
            
        serializer = EquipmentSerializer(queryset, many=True)
        return Response(serializer.data)

class EquipmentDetailView(APIView):
    def get(self, request, pk):
        try:
            eq = Equipment.objects.get(pk=pk)
            return Response(EquipmentSerializer(eq).data)
        except Equipment.DoesNotExist:
            return Response({'error': 'Equipment not found'}, status=status.HTTP_404_NOT_FOUND)

class BookingListView(APIView):
    def get(self, request):
        status_param = request.query_params.get('status')
        search = request.query_params.get('search')
        queryset = Booking.objects.all().select_related('equipment')
        if status_param and status_param != 'ALL':
            queryset = queryset.filter(status=status_param)
        if search:
            queryset = queryset.filter(borrower_name__icontains=search)
        serializer = BookingSerializer(queryset, many=True)
        return Response(serializer.data)

    def post(self, request):
        serializer = BookingSerializer(data=request.data)
        if serializer.is_valid():
            booking = serializer.save()
            return Response(BookingSerializer(booking).data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

class BookingDetailView(APIView):
    def get(self, request, pk):
        try:
            booking = Booking.objects.select_related('equipment').get(pk=pk)
            return Response(BookingSerializer(booking).data)
        except Booking.DoesNotExist:
            return Response({'error': 'Booking not found'}, status=status.HTTP_404_NOT_FOUND)

    def patch(self, request, pk):
        try:
            booking = Booking.objects.select_related('equipment').get(pk=pk)
            new_status = request.data.get('status')
            if new_status:
                old_status = booking.status
                booking.status = new_status
                # คืน stock ถ้ามีการยกเลิกหรือคืนอุปกรณ์
                if new_status in ['RETURNED', 'CANCELLED'] and old_status not in ['RETURNED', 'CANCELLED']:
                    booking.equipment.available_quantity += booking.quantity
                    booking.equipment.save()
                elif old_status in ['RETURNED', 'CANCELLED'] and new_status not in ['RETURNED', 'CANCELLED']:
                    if booking.equipment.available_quantity >= booking.quantity:
                        booking.equipment.available_quantity -= booking.quantity
                        booking.equipment.save()
                booking.save()
            return Response(BookingSerializer(booking).data)
        except Booking.DoesNotExist:
            return Response({'error': 'Booking not found'}, status=status.HTTP_404_NOT_FOUND)

    def delete(self, request, pk):
        try:
            booking = Booking.objects.select_related('equipment').get(pk=pk)
            if booking.status not in ['RETURNED', 'CANCELLED']:
                booking.equipment.available_quantity += booking.quantity
                booking.equipment.save()
            booking.delete()
            return Response({'message': 'Booking deleted successfully'}, status=status.HTTP_204_NO_CONTENT)
        except Booking.DoesNotExist:
            return Response({'error': 'Booking not found'}, status=status.HTTP_404_NOT_FOUND)


from django.contrib.auth import authenticate
from oidc_provider.models import Client, Token
from oidc_provider.lib.utils.token import create_token, create_id_token, encode_id_token
from .oidc_claims import userinfo as populate_userinfo


class OIDCLoginView(APIView):
    """
    Direct OpenID Connect (OIDC) login endpoint for Mobile clients.
    Authenticates user and returns standard OpenID Connect tokens:
    - access_token (Bearer token for API access & /openid/userinfo/)
    - id_token (RS256 cryptographically signed standard OpenID Connect JWT)
    - refresh_token
    - user claims
    """
    def post(self, request):
        username = request.data.get('username', '').strip()
        password = request.data.get('password', '')
        client_id = request.data.get('client_id', 'flutter-mobile-client')

        if not username or not password:
            return Response(
                {'error': 'กรุณากรอก Username และ Password'},
                status=status.HTTP_400_BAD_REQUEST
            )

        user = authenticate(request, username=username, password=password)
        if not user:
            return Response(
                {'error': 'ชื่อผู้ใช้หรือรหัสผ่านไม่ถูกต้อง (Invalid credentials)'},
                status=status.HTTP_401_UNAUTHORIZED
            )

        try:
            client = Client.objects.get(client_id=client_id)
        except Client.DoesNotExist:
            client = Client.objects.first()
            if not client:
                return Response(
                    {'error': 'OIDC Client not configured. Run seed_oidc first.'},
                    status=status.HTTP_500_INTERNAL_SERVER_ERROR
                )

        scopes = ['openid', 'profile', 'email']
        # Create standard OIDC Token record
        token = create_token(user=user, client=client, scope=scopes)
        # Create and sign standard ID Token
        id_token_dic = create_id_token(
            token=token,
            user=user,
            aud=client.client_id,
            scope=scopes,
            request=request
        )
        token.id_token = id_token_dic
        token.save()

        signed_id_token = encode_id_token(id_token_dic, client)

        # Retrieve user claims
        user_claims = populate_userinfo({}, user)

        return Response({
            'token_type': 'Bearer',
            'access_token': token.access_token,
            'refresh_token': token.refresh_token,
            'expires_in': 3600,
            'id_token': signed_id_token,
            'scope': ' '.join(scopes),
            'user': user_claims,
        })


from django.http import HttpResponse


class OIDCCallbackView(APIView):
    """
    Renders the OIDC authorization code callback page.
    Displays the authorization code and provides 1-click copy & deep link back to Flutter app.
    """
    def get(self, request):
        code = request.GET.get('code', '')
        state = request.GET.get('state', '')
        error = request.GET.get('error', '')
        error_desc = request.GET.get('error_description', '')

        if error:
            html = f"""<!DOCTYPE html>
            <html lang="th">
            <head><meta charset="utf-8"><title>OIDC Error</title>
            <style>body {{ font-family: sans-serif; display: flex; align-items: center; justify-content: center; height: 100vh; background: #fff1f2; margin: 0; }}</style>
            </head>
            <body><div style="background: white; padding: 30px; border-radius: 12px; box-shadow: 0 4px 12px rgba(0,0,0,0.1); max-width: 500px; text-align: center;">
            <h2 style="color: #be123c;">⚠️ เกิดข้อผิดพลาดในการยืนยันตัวตน</h2>
            <p><strong>Error:</strong> {error}</p>
            <p>{error_desc}</p>
            </div></body></html>"""
            return HttpResponse(html, status=400)

        html = f"""<!DOCTYPE html>
        <html lang="th">
        <head>
            <meta charset="utf-8">
            <meta name="viewport" content="width=device-width, initial-scale=1">
            <title>OIDC Authorization Succeeded</title>
            <style>
                body {{
                    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
                    background: linear-gradient(135deg, #1e3a8a 0%, #3b82f6 100%);
                    min-height: 100vh;
                    display: flex;
                    align-items: center;
                    justify-content: center;
                    margin: 0;
                    padding: 20px;
                }}
                .card {{
                    background: white;
                    border-radius: 20px;
                    padding: 32px;
                    max-width: 520px;
                    width: 100%;
                    box-shadow: 0 20px 40px rgba(0,0,0,0.2);
                    text-align: center;
                }}
                .badge {{
                    display: inline-block;
                    background: #dcfce7;
                    color: #15803d;
                    font-weight: bold;
                    padding: 6px 16px;
                    border-radius: 20px;
                    margin-bottom: 12px;
                }}
                .code-box {{
                    background: #f8fafc;
                    border: 2px dashed #94a3b8;
                    border-radius: 12px;
                    padding: 16px;
                    font-family: monospace;
                    font-size: 16px;
                    font-weight: bold;
                    color: #1e293b;
                    word-break: break-all;
                    margin: 20px 0;
                }}
                .btn {{
                    display: inline-block;
                    background: #1e3a8a;
                    color: white;
                    padding: 12px 24px;
                    border-radius: 10px;
                    text-decoration: none;
                    font-weight: bold;
                    margin: 6px;
                    cursor: pointer;
                    border: none;
                }}
                .btn-copy {{
                    background: #0ea5e9;
                }}
            </style>
        </head>
        <body>
            <div class="card">
                <div class="badge">✅ ยืนยันตัวตน OIDC สำเร็จแล้ว</div>
                <h2 style="margin: 0; color: #1e293b;">ยินดีต้อนรับสู่ระบบ</h2>
                <p style="color: #64748b; font-size: 14px;">OpenID Connect Provider ได้ออก Authorization Code ให้คุณเรียบร้อยแล้ว</p>
                <div class="code-box" id="codeText">{code}</div>
                <div>
                    <button class="btn btn-copy" onclick="copyCode()">📋 คัดลอก Code</button>
                    <a href="com.example.frontend://oauth2redirect?code={code}&state={state}" class="btn">📱 เปิดแอปอัตโนมัติ</a>
                </div>
                <p id="msg" style="color: #10b981; font-weight: bold; min-height: 20px; margin-top: 15px; font-size: 13px;"></p>
                <p style="color: #94a3b8; font-size: 12px; margin-top: 20px;">
                    หากแอปพลิเคชันไม่เปิดอัตโนมัติ คุณสามารถคัดลอกโค้ดด้านบน แล้วนำไปวางในแอปเพื่อเสร็จสิ้นการล็อกอิน
                </p>
            </div>
            <script>
                function copyCode() {{
                    var text = document.getElementById('codeText').innerText;
                    navigator.clipboard.writeText(text).then(function() {{
                        document.getElementById('msg').innerText = 'คัดลอก Authorization Code เรียบร้อยแล้ว!';
                    }});
                }}
                try {{
                    window.location.href = "com.example.frontend://oauth2redirect?code={code}&state={state}";
                }} catch (e) {{}}
            </script>
        </body>
        </html>"""
        return HttpResponse(html, content_type='text/html')


