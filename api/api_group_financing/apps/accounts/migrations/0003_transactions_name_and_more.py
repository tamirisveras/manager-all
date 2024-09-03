# Generated by Django 5.0.7 on 2024-08-10 14:04

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('accounts', '0002_alter_group_name'),
    ]

    operations = [
        migrations.AddField(
            model_name='transactions',
            name='name',
            field=models.CharField(default=1, max_length=255, verbose_name='Nome'),
            preserve_default=False,
        ),
        migrations.AlterField(
            model_name='transactions',
            name='type_transaction',
            field=models.BooleanField(choices=[(False, 'Fixo'), (True, 'Variável')], default=False, verbose_name='Tipo de Transação'),
        ),
    ]
