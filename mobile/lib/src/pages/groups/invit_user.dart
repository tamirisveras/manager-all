import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class InviteUserScreen extends StatefulWidget {
  final int groupId; // ID do grupo ao qual o usuário será convidado

  InviteUserScreen(BuildContext context, String text, int? currentGroupId, {required this.groupId});

  @override
  _InviteUserScreenState createState() => _InviteUserScreenState();
}

class _InviteUserScreenState extends State<InviteUserScreen> {
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;
  String _message = '';

  Future<void> _inviteUser() async {
    setState(() {
      _isLoading = true;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    if (token != null) {
      try {
        // 1. Buscar o ID do usuário pelo email
        final searchUrl = Uri.parse('http://10.0.2.2:8000/users/search/');
        final searchResponse = await http.post(
          searchUrl,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Token $token',
          },
          body: jsonEncode({'email': _emailController.text.trim()}),
        );

        if (searchResponse.statusCode == 200) {
          final userData = jsonDecode(searchResponse.body);
          final int userId = userData['id'];

          // 2. Enviar convite para o usuário
          final inviteUrl = Uri.parse(
              'http://10.0.2.2:8000/groups/ask-to-join-group/${widget.groupId}/$userId/');
          final inviteResponse = await http.get(
            inviteUrl,
            headers: {
              'Authorization': 'Token $token',
            },
          );

          if (inviteResponse.statusCode == 200) {
            setState(() {
              _message = 'Convite enviado com sucesso!';
            });
          } else {
            setState(() {
              _message = 'Erro ao enviar convite: ${inviteResponse.body}';
            });
          }
        } else {
          setState(() {
            _message = 'Erro ao buscar usuário: ${searchResponse.body}';
          });
        }
      } catch (e) {
        setState(() {
          _message = 'Erro de rede: $e';
        });
      }
    } else {
      setState(() {
        _message = 'Token não encontrado, faça login novamente.';
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Convidar Usuário para Grupo'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email do Usuário',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
            ),
            const SizedBox(height: 20.0),
            ElevatedButton(
              onPressed: _isLoading ? null : _inviteUser,
              child: _isLoading
                  ? CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    )
                  : Text('Enviar Convite'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 24.0),
                backgroundColor: Colors.teal,
              ),
            ),
            const SizedBox(height: 20.0),
            if (_message.isNotEmpty)
              Text(
                _message,
                style: TextStyle(
                  color: _message.contains('sucesso') ? Colors.green : Colors.red,
                ),
                textAlign: TextAlign.center,
              ),
          ],
        ),
      ),
    );
  }
}
