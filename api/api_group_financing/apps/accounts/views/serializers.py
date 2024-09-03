from django.forms import ValidationError
from rest_framework import serializers
from api_group_financing.apps.accounts.models import User
from django.contrib.auth.hashers import make_password
from api_group_financing.apps.accounts.models import Group
from api_group_financing.apps.accounts.models import Transactions

class PasswordResetSerializer(serializers.Serializer):

    email = serializers.EmailField()

class PasswordResetConfirmSerializer(serializers.Serializer):

    new_password = serializers.CharField(write_only=True, min_length=8)
    confirm_password = serializers.CharField(write_only=True, min_length=8)

    def validate(self, data):
        if data['new_password'] != data['confirm_password']:
            raise serializers.ValidationError("As senhas não coincidem.")
        return data    

class ListTransactionSerializer(serializers.ModelSerializer):

    class Meta:
        model = Transactions
        fields = '__all__'

class TransactionSerializer(serializers.ModelSerializer):

    user = serializers.StringRelatedField()

    class Meta:
        model = Transactions
        fields = ['name', 'type_transaction', 'value', 'user']

    def create(self, validated_data):
        user = self.context['request'].user
        validated_data['user'] = user
        save_user = super().create(validated_data)
        save_user.save()
        return save_user


class ReadUserSerializer(serializers.ModelSerializer):

    class Meta:
        model = User
        fields = ('id', 'first_name', 'last_name', 'email', 'income_fixed', 'type_account')


class CreateUserSerializer(serializers.ModelSerializer):

    password = serializers.CharField(write_only=True)

    class Meta:
        model = User
        fields = ['first_name','last_name', 'email', 'password', 'income_fixed', 'type_account']


    def create(self, validated_data):
        validated_data['password'] = make_password(validated_data['password'])
        return super().create(validated_data)
    

class UpdateUserSerializer(serializers.ModelSerializer):

    class Meta:
        model = User
        fields = ['first_name','last_name', 'income_fixed', 'type_account']
        extra_kwargs = {
            'first_name': {'required': False},
            'last_name': {'required': False},
            'income_fixed': {'required': False},
            'type_account': {'required': False}
        }


class GroupSerializer(serializers.ModelSerializer):

    class Meta:
        model = Group
        fields = ['name']

    def create(self, validated_data):
        user = self.context['request'].user
        group = Group.objects.create(
            name=validated_data['name'],
            creator=user
        )
        group.users.add(user)
        group.save()
        return group
    def validate(self, attrs):
        user = self.context['request'].user
        if not user.type_account:
            user_groups_count = Group.objects.filter(creator=user).count()
            if user_groups_count >= 1:
                raise ValidationError("Usuários com conta do tipo Simples só podem criar um grupo.")
        else:
            user_groups_count = Group.objects.filter(creator=user).count()
            if user_groups_count >= 5:
                raise ValidationError("Usuários com conta do tipo Prime só podem criar até 5 grupos.")
        return attrs
    

class UserGroupSerializer(serializers.ModelSerializer):

    class Meta:
        model = Group
        fields = ['users']
        extra_kwargs = {
            'users': {'required': False}
        }
