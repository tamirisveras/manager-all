import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobile/src/pages/list_expenses.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RegisterUserScreen extends StatefulWidget {
  @override
  _RegisterUserScreenState createState() => _RegisterUserScreenState();
}

class _RegisterUserScreenState extends State<RegisterUserScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _valueController = TextEditingController();
  String _selectedTransactionType = 'Fixo'; // Valor inicial

  Future<void> _submitTransaction() async {
    final name = _nameController.text;
    final value = _valueController.text;

    if (name.isEmpty || value.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Preencha todos os campos')),
      );
      return;
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    if (token != null) {
      final url = Uri.parse('http://10.0.2.2:8000/transactions/create/');
      final requestData = {
        'name': name,
        'type_transaction': _selectedTransactionType == 'Variável',
        'value': double.tryParse(value) ?? 0.0,
      };

      try {
        final response = await http.post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Token $token',
          },
          body: jsonEncode(requestData),
        );

        if (response.statusCode == 201) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Transação cadastrada com sucesso!')),
          );
          // Redireciona para a FixedExpensesPage após o sucesso
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => FixedExpensesPage()),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao cadastrar transação: ${response.body}')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro de rede: $e')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Token não encontrado, faça login novamente.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Nome da Despesa',
              ),
            ),
            SizedBox(height: 20.0),
            TextField(
              controller: _valueController,
              decoration: InputDecoration(
                labelText: 'Valor',
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 20.0),
            DropdownButtonFormField<String>(
              value: _selectedTransactionType,
              decoration: InputDecoration(
                labelText: 'Tipo de Transação',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              items: [
                DropdownMenuItem(
                  value: 'Fixo',
                  child: Text('Fixo'),
                ),
                DropdownMenuItem(
                  value: 'Variável',
                  child: Text('Variável'),
                ),
              ],
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedTransactionType = newValue;
                  });
                }
              },
            ),
            SizedBox(height: 40.0),
            ElevatedButton(
              onPressed: _submitTransaction,
              child: Text('Cadastrar'),
            ),
          ],
        ),
      ),
    );
  }
}
