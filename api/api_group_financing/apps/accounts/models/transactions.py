from django.db import models
from api_group_financing.apps.accounts.models.user import User

class Transactions(models.Model):

    TYPE_TRANSACTION = (
        (False, 'Fixo'),
        (True, 'Variável')
    )

    user = models.ForeignKey(User, on_delete=models.CASCADE, verbose_name='Usuário')
    name = models.CharField('Nome', max_length=255)
    type_transaction = models.BooleanField('Tipo de Transação', choices=TYPE_TRANSACTION, default=False)
    value = models.FloatField('Valor', default=0.0)
    date = models.DateField('Data', auto_now_add=True)

    class Meta:
        verbose_name = 'Transação'
        verbose_name_plural = 'Transações'

    def __str__(self):
        return f'{self.user} - {self.date}'