from django.db import models
from api_group_financing.apps.accounts.models.user import User
from django.contrib.auth.models import GroupManager


class Group(models.Model):

    name = models.CharField('Nome', max_length=150, unique=True)
    users = models.ManyToManyField(User, related_name='group_users')
    creator = models.ForeignKey(User, on_delete=models.CASCADE, related_name='created_groups')

    objects = GroupManager()

    class Meta:
        verbose_name = 'Grupo'
        verbose_name_plural = 'Grupos'  

    def __str__(self):
        return self.name