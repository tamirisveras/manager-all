from rest_framework import generics, permissions, viewsets, status
from api_group_financing.apps.accounts.views.serializers import (ReadUserSerializer,
CreateUserSerializer, UpdateUserSerializer, GroupSerializer, UserGroupSerializer, TransactionSerializer, 
PasswordResetConfirmSerializer, PasswordResetSerializer, ListTransactionSerializer)
from api_group_financing.apps.accounts.models import User
from api_group_financing.apps.accounts.models import Group
from api_group_financing.apps.accounts.models import Transactions
from rest_framework import generics, permissions
from django.core.mail import send_mail
from rest_framework.response import Response
from django.urls import reverse
from django.utils.http import urlsafe_base64_encode, urlsafe_base64_decode
from django.utils.encoding import force_bytes, force_str, DjangoUnicodeDecodeError
from rest_framework.views import APIView
from django.shortcuts import get_object_or_404
from rest_framework import status, permissions, generics
from django.db.models import Sum, F, FloatField
from django.db.models.functions import Cast
from django.utils.dateparse import parse_date
from django.utils import timezone
from rest_framework.authentication import TokenAuthentication
from rest_framework.authentication import BasicAuthentication
from django.contrib.auth import logout
from django.utils.http import urlsafe_base64_decode
from django.contrib.auth.tokens import default_token_generator
from rest_framework.response import Response
from django.contrib.auth import authenticate
from rest_framework.authtoken.models import Token


class PasswordResetView(generics.GenericAPIView):
    serializer_class = PasswordResetSerializer

    def post(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user = User.objects.filter(email=serializer.validated_data['email']).first()
        if user:
            token = default_token_generator.make_token(user)
            uid = urlsafe_base64_encode(force_bytes(user.pk))
            # Garantir que a URL inclua o protocolo e o localhost:8000
            reset_link = f"http://localhost:8000/reset-password/{uid}/{token}/"
            send_mail(
                'Redefinição de senha',
                f'Use o link a seguir para redefinir sua senha: {reset_link}',
                'from@example.com',
                [user.email],
                fail_silently=False,
            )
        return Response({"detail": "Se o e-mail existir, um link de redefinição de senha foi enviado."}, status=status.HTTP_200_OK)
class PasswordResetConfirmView(generics.GenericAPIView):

    serializer_class = PasswordResetConfirmSerializer

    def post(self, request, uidb64, token, *args, **kwargs):
        try:
            uid = urlsafe_base64_decode(uidb64).decode()
            user = User.objects.get(pk=uid)
        except (TypeError, ValueError, OverflowError, User.DoesNotExist):
            user = None
        if user is not None and default_token_generator.check_token(user, token):
            serializer = self.get_serializer(data=request.data)
            serializer.is_valid(raise_exception=True)
            user.set_password(serializer.validated_data['new_password'])
            user.save()
            return Response({"A senha foi redefinida com sucesso."}, status=status.HTTP_200_OK)
        else:
            return Response({"Token ou ID de usuário inválido"}, status=status.HTTP_400_BAD_REQUEST)

class LoginViewSet(APIView):

    def post(self, request, format=None):
        email = request.data.get('email')
        password = request.data.get('password')

        user = authenticate(request, username=email, password=password)

        if user is not None:
            token, created = Token.objects.get_or_create(user=user)
            return Response({'token': token.key}, status=status.HTTP_200_OK)
        else:
            return Response({'error': 'Credenciais inválidas'}, status=status.HTTP_401_UNAUTHORIZED)

class LogoutViewSet(viewsets.ViewSet):

    authentication_classes = [TokenAuthentication]  # Use TokenAuthentication para autenticação baseada em token
    permission_classes = [permissions.IsAuthenticated]

    def create(self, request):  # Usar `create` para aceitar requisições `POST`
        request.user.auth_token.delete()  # Deleta o token de autenticação
        logout(request)  # Realiza o logout do usuário
        return Response({'detail': 'Logout efetuado com sucesso!'}, status=status.HTTP_200_OK)

class ListExpensesAPI(generics.ListAPIView):

    permission_classes = [permissions.IsAuthenticated]

    def get(self, request, *args, **kwargs):
        try:
            user = request.user
            current_month = timezone.now().month
            current_year = timezone.now().year
            groups = Group.objects.filter(users=user)
            if not groups.exists():
                return Response({'detail': 'Usuário não pertence a nenhum grupo.'}, status=status.HTTP_404_NOT_FOUND)
            members = User.objects.filter(group_users__in=groups).distinct()
            member_data = []
            for member in members:
                transactions = Transactions.objects.filter(
                    user=member, 
                    date__month=current_month,
                    date__year=current_year
                )
                total_gastos = transactions.aggregate(
                    total=Sum(Cast('value', FloatField()))
                )['total'] or 0
                member_data.append({
                    "id": member.id,
                    "nome": member.first_name,
                    "email": member.email,
                    "gastos": total_gastos
                })
            return Response({'members': member_data}, status=status.HTTP_200_OK)
        except Exception as e:
            return Response({'detail': f'Erro ao filtrar os membros: {str(e)}'}, status=status.HTTP_400_BAD_REQUEST)
        
class RecordFixedVariableExpensesAPI(generics.ListAPIView):

    permission_classes = [permissions.IsAuthenticated]

    def get(self, request, *args, **kwargs):
        try:
            user = request.user
            groups = Group.objects.filter(users=user)
            if not groups.exists():
                return Response({'detail': 'Usuário não pertence a nenhum grupo.'}, status=status.HTTP_404_NOT_FOUND)
            start_date = request.query_params.get('start_date')
            end_date = request.query_params.get('end_date')
            start_date = parse_date(start_date) if start_date else None
            end_date = parse_date(end_date) if end_date else None
            members = User.objects.filter(group_users__in=groups).distinct()
            member_data = []
            for member in members:
                transactions = Transactions.objects.filter(user=member)
                if start_date:
                    transactions = transactions.filter(date__gte=start_date)
                if end_date:
                    transactions = transactions.filter(date__lte=end_date)
                total_gastos = transactions.annotate(value_as_float=Cast('value', FloatField()))\
                                           .aggregate(total=Sum('value_as_float'))['total']
                member_data.append({
                    "id": member.id,
                    "nome": member.first_name,
                    "email": member.email,
                    "gastos": total_gastos
                })
            return Response({'members': member_data}, status=status.HTTP_200_OK)
        except Exception as e:
            return Response({'detail': f'Erro ao filtrar os membros: {str(e)}'}, status=status.HTTP_400_BAD_REQUEST)

class DifferenceValueAPI(APIView):

    permission_classes = [permissions.IsAuthenticated]

    def get(self, request, *args, **kwargs):
        try:
            user = request.user
            balance = User.objects.filter(id=user.id).values('income_fixed')
            transactions = Transactions.objects.filter(user=user)
            month = Transactions.objects.filter(user=user).values('date')
            total = 0
            for transaction in transactions:
                total += transaction.value
            difference = balance[0]['income_fixed'] - total
            return Response(
                {'Mês': month[0]['date'],
                'Receitas': balance[0]['income_fixed'], 
                'Despesas': total,
                'Saldo:': difference}, status=status.HTTP_200_OK)
        except Exception as e:
            return Response({f'Erro ao calcular a diferença: {str(e)}'}, status=status.HTTP_400_BAD_REQUEST)

class ListTransactionFixViewSet(generics.ListAPIView):

    permission_classes = [permissions.IsAuthenticated]
    serializer_class = ListTransactionSerializer

    def get_queryset(self):
        return Transactions.objects.filter(user=self.request.user, type_transaction=False)
    
class ListTransactionViewSet(generics.ListAPIView):

    permission_classes = [permissions.IsAuthenticated]
    serializer_class = ListTransactionSerializer

    def get_queryset(self):
        return Transactions.objects.filter(user=self.request.user, type_transaction=True)

class CreateTransactionViewSet(generics.CreateAPIView):

    permission_classes = [permissions.IsAuthenticated]
    queryset = Transactions.objects.all()
    serializer_class = TransactionSerializer

class AcceptGroupInviteAPI(APIView):

    permission_classes = [permissions.IsAuthenticated]

    def get(self, request, uidb64, group_id, *args, **kwargs):
        try:
            try:
                user_id = force_str(urlsafe_base64_decode(uidb64))
            except (DjangoUnicodeDecodeError, ValueError):
                return Response({'Link de convite inválido.'}, status=status.HTTP_400_BAD_REQUEST)
            user = get_object_or_404(User, pk=user_id)
            group = get_object_or_404(Group, pk=group_id)
            group.users.add(user)
            return Response({'Usuário adicionado ao grupo com sucesso!'}, status=status.HTTP_200_OK)
        except Exception as e:
            return Response({f'Erro ao adicionar ao grupo: {str(e)}'}, status=status.HTTP_400_BAD_REQUEST)

class AskedParticipateEmailGroupAPI(generics.GenericAPIView):

    permission_classes = [permissions.IsAuthenticated]

    def get(self, request, *args, **kwargs):
        group = get_object_or_404(Group, id=kwargs['pk'])
        user_add = get_object_or_404(User, id=kwargs['id_user'])
        if user_add:
            get_email_user = request.user.email
            get_name_user = request.user.first_name
            uidb64 = urlsafe_base64_encode(force_bytes(user_add.pk))
            group_id = group.id
            accept_url = request.build_absolute_uri(
                reverse('accept-group-invite', kwargs={'uidb64': uidb64, 'group_id': group_id})
            )
            subject = f'Convite para Participar do Grupo {group.name}'
            message = (
                f'Olá {user_add.username},\n\n'
                f'Meu nome é {get_name_user}, email: {get_email_user}, gostaria de participar do grupo "{group.name}"?\n'
                f'Se você deseja aceitar o convite, clique no link abaixo:\n{accept_url}\n\n'
                f'Obrigado!'
            )
            from_email = get_email_user
            recipient_list = [user_add.email]
            send_mail(subject, message, from_email, recipient_list)
            return Response({'Email enviado com sucesso!'}, status=status.HTTP_200_OK)
        else:
            return Response({'Usuário não encontrado!'}, status=status.HTTP_404_NOT_FOUND)

class AddUserGroupViewSet(generics.UpdateAPIView):

    permission_classes = [permissions.IsAuthenticated]
    queryset = Group.objects.all()
    serializer_class = UserGroupSerializer

class ListGroupViewSet(generics.ListAPIView):

    queryset = Group.objects.all()
    serializer_class = GroupSerializer

    def get_queryset(self):
        return super().get_queryset().filter(users=self.request.user)

class CreateGroupViewSet(generics.CreateAPIView):

    permission_classes = [permissions.IsAuthenticated]
    queryset = Group.objects.all()
    serializer_class = GroupSerializer
        
class UpdateGroupViewSet(generics.UpdateAPIView):

    permission_classes = [permissions.IsAuthenticated]
    queryset = Group.objects.all()
    serializer_class = GroupSerializer

class DeleteGroupViewSet(generics.DestroyAPIView):

    permission_classes = [permissions.IsAuthenticated]
    queryset = Group.objects.all()
    serializer_class = GroupSerializer

class ListUserViewSet(generics.ListAPIView):

    queryset = User.objects.all()
    serializer_class = ReadUserSerializer
    

class CreateUserViewSet(generics.CreateAPIView):

    queryset = User.objects.all()
    serializer_class = CreateUserSerializer

class UpdateUserViewSet(generics.UpdateAPIView):

    permission_classes = [permissions.IsAuthenticated]
    queryset = User.objects.all()
    serializer_class = UpdateUserSerializer

class DeleteUserViewSet(generics.DestroyAPIView):

    permission_classes = [permissions.IsAuthenticated]
    queryset = User.objects.all()
    serializer_class = ReadUserSerializer
