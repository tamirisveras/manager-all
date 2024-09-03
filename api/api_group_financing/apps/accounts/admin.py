from django.contrib import admin
from api_group_financing.apps.accounts.models.user import User
from api_group_financing.apps.accounts.models.transactions import Transactions
from api_group_financing.apps.accounts.models.group import Group

admin.site.register(User)
admin.site.register(Transactions)
admin.site.register(Group)