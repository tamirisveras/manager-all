import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class RegisterUserScreen extends StatefulWidget {
  @override
  _RegisterUserScreenState createState() => _RegisterUserScreenState();
}

class _RegisterUserScreenState extends State<RegisterUserScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _incomeController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  String _selectedAccountType = 'Conta Simples'; // Valor inicial

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Cadastro de Usuário'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Nome Completo',
              ),
            ),
            SizedBox(height: 20.0),
            TextField(
              controller: _incomeController,
              decoration: InputDecoration(
                labelText: 'Renda Fixa (Salário)',
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 20.0),
            DropdownButtonFormField<String>(
              value: _selectedAccountType,
              decoration: InputDecoration(
                labelText: 'Tipo de Conta',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              items: [
                DropdownMenuItem(
                  value: 'Conta Simples',
                  child: Text('Conta Simples'),
                ),
                DropdownMenuItem(
                  value: 'Prime',
                  child: Text('Prime'),
                ),
              ],
              onChanged: (String? newValue) {
                setState(() {
                  _selectedAccountType = newValue!;
                });
              },
            ),
            SizedBox(height: 20.0),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email',
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            SizedBox(height: 20.0),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Senha',
              ),
            ),
            SizedBox(height: 20.0),
            TextField(
              controller: _confirmPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Confirme a Senha',
              ),
            ),
            SizedBox(height: 40.0),
            ElevatedButton(
              onPressed: () {
                _signup(context);
              },
              child: Text('Cadastrar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _signup(BuildContext context) async {
    String name = _nameController.text.trim();
    String income = _incomeController.text.trim();
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();
    String confirmPassword = _confirmPasswordController.text.trim();

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('As senhas não coincidem.')),
      );
      return;
    }

    if (email.isNotEmpty && password.isNotEmpty && name.isNotEmpty) {
      // Separar primeiro e último nome
      List<String> nameParts = name.split(' ');
      String firstName = nameParts.first;
      String lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';  // Se houver mais de um nome, combine o resto como last_name

      final Map<String, dynamic> requestData = {
        'first_name': firstName,
        'last_name': lastName,
        'email': email,
        'password': password,
        'income_fixed': double.tryParse(income) ?? 0.0,
        'type_account': _selectedAccountType == 'Prime' ? true : false,
      };

      final url = Uri.parse('http://10.0.2.2:8000/users/create/');
      
      try {
        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: json.encode(requestData),
        );

        if (response.statusCode == 201) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Cadastro realizado com sucesso!')),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao cadastrar: ${response.body}')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao se conectar ao servidor: $e')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Preencha todos os campos')),
      );
    }
  }
}
