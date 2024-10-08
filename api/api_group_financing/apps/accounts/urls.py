from django.urls import path
from api_group_financing.apps.accounts.views.viewsets import (ListUserViewSet,
CreateUserViewSet, UpdateUserViewSet, DeleteUserViewSet, ListGroupViewSet, CreateGroupViewSet, 
UpdateGroupViewSet, DeleteGroupViewSet, AddUserGroupViewSet, AskedParticipateEmailGroupAPI, AcceptGroupInviteAPI,
ListTransactionViewSet, CreateTransactionViewSet, DifferenceValueAPI, RecordFixedVariableExpensesAPI, 
ListExpensesAPI, LoginViewSet, LogoutViewSet, PasswordResetConfirmView, PasswordResetView, ListTransactionFixViewSet)

urlpatterns = [
    path('users/', ListUserViewSet.as_view(), name='list-users'),
    path('users/create/', CreateUserViewSet.as_view(), name='create-user'),
    path('users/update/<int:pk>/', UpdateUserViewSet.as_view(), name='update-user'),
    path('users/delete/<int:pk>/', DeleteUserViewSet.as_view(), name='delete-user'),
    path('groups/', ListGroupViewSet.as_view(), name='list-groups'),
    path('groups/create/', CreateGroupViewSet.as_view(), name='create-group'),
    path('groups/update/<int:pk>/', UpdateGroupViewSet.as_view(), name='update-group'),
    path('groups/delete/<int:pk>/', DeleteGroupViewSet.as_view(), name='delete-group'),
    path('groups/add-group/<int:pk>/', AddUserGroupViewSet.as_view(), name='add-user-group'),
    path('groups/ask-to-join-group/<int:pk>/<int:id_user>/', AskedParticipateEmailGroupAPI.as_view(), name='ask-to-join-group-api'),
    path('groups/accept-invite/<uidb64>/<int:group_id>/', AcceptGroupInviteAPI.as_view(), name='accept-group-invite'),
    path('transactions/', ListTransactionFixViewSet.as_view(), name='list-transactions'),
    path('transactions/variable/', ListTransactionViewSet.as_view(), name='list-transactions-variable'),
    path('transactions/create/', CreateTransactionViewSet.as_view(), name='create-transaction'),
    path('transactions/difference/', DifferenceValueAPI.as_view(), name='difference-value'),
    path('transactions/record-fixed-variable-expenses/<int:pk>/', RecordFixedVariableExpensesAPI.as_view(), name='record-fixed-variable-expenses'),
    path('transactions/expenses/', ListExpensesAPI.as_view(), name='list-expenses'),
    path('login/', LoginViewSet.as_view(), name='login'),
    path('logout/', LogoutViewSet.as_view({'post': 'create'}), name='logout'),
    path('password-reset/', PasswordResetView.as_view(), name='password-reset'),
    path('reset-password/<uidb64>/<token>/', PasswordResetConfirmView.as_view(), name='password-reset-confirm'),
]