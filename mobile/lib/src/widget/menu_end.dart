import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobile/src/pages/dashboard.dart';
import 'package:mobile/src/pages/list_espenses_variable.dart';
import 'package:mobile/src/pages/list_expenses.dart';
import 'package:mobile/src/pages/register_user.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile/src/pages/login.dart';
import 'package:mobile/src/widget/menu.dart';

// Tela Home com Menu Inferior
class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    DashboardPage(),
    FixedExpensesPage(),
    VariableExpensesPage(),
    RegisterUserScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _logout(BuildContext context) async {
    final url = Uri.parse('http://10.0.2.2:8000/logout/');

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    if (token != null) {
      try {
        final response = await http.post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Token $token', // Certifique-se de incluir o token aqui
          },
        );

        if (response.statusCode == 200) {
          await prefs.remove('token'); // Remove o token após logout

          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => LoginScreen()),
            (Route<dynamic> route) => false,
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao fazer logout: ${response.body}')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro de rede: $e')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Token não encontrado, faça login novamente.')),
      );
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
        (Route<dynamic> route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: MenuDrawer(),
      appBar: AppBar(
        title: const Text('TecFinance'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance),
            label: 'Contas Fixas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.attach_money),
            label: 'Contas Variáveis',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline),
            label: 'Cadastrar Despesa',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.teal,
        unselectedItemColor: Colors.blueGrey[400],
        onTap: _onItemTapped,
        backgroundColor: Colors.white,
        elevation: 10.0,
      ),
    );
  }
}