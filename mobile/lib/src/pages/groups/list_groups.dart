import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ListGroupsScreen extends StatefulWidget {
  @override
  _ListGroupsScreenState createState() => _ListGroupsScreenState();
}

class _ListGroupsScreenState extends State<ListGroupsScreen> {
  bool _isLoading = true;
  List<dynamic> _groups = [];
  int _selectedIndex = 0;
  final TextEditingController _groupNameController = TextEditingController();
  bool _isCreatingGroup = false;

  DateTime _selectedDate = DateTime.now(); // Para filtrar membros por mês/ano
  List<dynamic> _members = []; // Lista de membros filtrados
  bool _isFiltering = false; // Para indicar se a tela de filtragem está carregando
  int? _currentGroupId; // Armazena o ID do grupo atual
  final TextEditingController _inviteEmailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchGroups();
  }

  Future<void> _fetchGroups() async {
    setState(() {
      _isLoading = true;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    if (token != null) {
      final url = Uri.parse('http://10.0.2.2:8000/groups/');
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          _groups = json.decode(response.body);
          _isLoading = false;
          if (_groups.isNotEmpty) {
            _currentGroupId = _groups.first['id']; // Armazena o ID do primeiro grupo
          }
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar grupos: ${response.body}')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Token não encontrado, faça login novamente.')),
      );
    }
  }

  Future<void> _createGroup() async {
    setState(() {
      _isCreatingGroup = true;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    if (token != null) {
      final url = Uri.parse('http://10.0.2.2:8000/groups/create/');
      final Map<String, dynamic> requestData = {
        'name': _groupNameController.text.trim(),
      };

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
          SnackBar(content: Text('Grupo criado com sucesso!')),
        );
        _fetchGroups();
        setState(() {
          _selectedIndex = 0; // Retorna à lista de grupos após criar
          _groupNameController.clear();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao criar grupo: ${response.body}')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Token não encontrado, faça login novamente.')),
      );
    }

    setState(() {
      _isCreatingGroup = false;
    });
  }

  Future<void> _fetchMembersData(int? groupId) async {
    if (groupId == null) return;

    setState(() {
      _isFiltering = true;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    if (token != null) {
      final DateFormat dateFormat = DateFormat('yyyy-MM-dd');
      final startDate = DateTime(_selectedDate.year, _selectedDate.month, 1);
      final endDate = DateTime(_selectedDate.year, _selectedDate.month + 1, 0);

      final url = Uri.parse(
        'http://10.0.2.2:8000/transactions/record-fixed-variable-expenses/$groupId/?start_date=${dateFormat.format(startDate)}&end_date=${dateFormat.format(endDate)}',
      );

      try {
        final response = await http.get(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Token $token',
          },
        );

        if (response.statusCode == 200) {
          setState(() {
            _members = json.decode(response.body)['members'];
            _isFiltering = false;
            if (_selectedIndex != 2) {
              _selectedIndex = 2; // Navega para a tela de filtragem se ainda não estiver nela
            }
          });
        } else {
          setState(() {
            _isFiltering = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao carregar membros: ${response.body}')),
          );
        }
      } catch (e) {
        setState(() {
          _isFiltering = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro de rede: $e')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Token não encontrado, faça login novamente.')),
      );
    }
  }

  Future<void> _fetchCurrentMonthExpenses() async {
    setState(() {
      _isFiltering = true;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    if (token != null) {
      final url = Uri.parse('http://10.0.2.2:8000/transactions/expenses/');
      try {
        final response = await http.get(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Token $token',
          },
        );

        if (response.statusCode == 200) {
          setState(() {
            _members = json.decode(response.body)['members'];
            _isFiltering = false;
            if (_selectedIndex != 3) {
              _selectedIndex = 3; // Navega para a tela de gastos do mês atual
            }
          });
        } else {
          setState(() {
            _isFiltering = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao carregar despesas do mês: ${response.body}')),
          );
        }
      } catch (e) {
        setState(() {
          _isFiltering = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro de rede: $e')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Token não encontrado, faça login novamente.')),
      );
    }
  }

  Future<void> _inviteUserToGroup() async {
    if (_inviteEmailController.text.isEmpty || _currentGroupId == null) return;

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    if (token != null) {
      final url = Uri.parse('http://10.0.2.2:8000/groups/ask-to-join-group/$_currentGroupId/');
      final requestData = {
        'email': _inviteEmailController.text.trim(),
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

        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Convite enviado com sucesso!')),
          );
          _inviteEmailController.clear();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao enviar convite: ${response.body}')),
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
    }
  }

  void _onItemTapped(int index) {
    if (index == 2 && _currentGroupId != null) {
      // Navegar para a página de filtro e carregar dados do grupo atual
      _fetchMembersData(_currentGroupId);
    } else if (index == 3) {
      // Navegar para a página de gastos do mês atual
      _fetchCurrentMonthExpenses();
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  void _onDateSelected(DateTime selectedDate) {
    setState(() {
      _selectedDate = selectedDate;
      if (_currentGroupId != null) {
        _fetchMembersData(_currentGroupId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _selectedIndex == 0
              ? 'Grupos'
              : (_selectedIndex == 1 ? 'Criar Grupo' : _selectedIndex == 2 ? 'Filtrar Grupo' : 'Gastos Mês Atual'),
          style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.teal,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : IndexedStack(
              index: _selectedIndex,
              children: [
                _buildGroupsList(),
                _buildCreateGroupForm(),
                _buildFilterGroupScreen(),
                _buildCurrentMonthExpensesScreen(),
              ],
            ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'Grupos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add),
            label: 'Adicionar Grupo',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.manage_search_outlined),
            label: 'Filtrar Grupo',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Gastos Mês Atual',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.teal,
        unselectedItemColor: Colors.blueGrey,
        onTap: _onItemTapped,
      ),
    );
  }

  Widget _buildGroupsList() {
    return _groups.isEmpty
        ? Center(child: Text('Você não está participando de nenhum grupo!'))
        : ListView.builder(
            itemCount: _groups.length,
            itemBuilder: (context, index) {
              final group = _groups[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                child: ListTile(
                  title: Text(
                    group['name'],
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.person_add, color: Colors.teal),
                        onPressed: () {
                          setState(() {
                            _currentGroupId = group['id'];
                          });
                          _showInviteUserDialog(); // Abre o pop-up para convidar usuário
                        },
                      ),
                      Icon(Icons.arrow_forward_ios, color: Colors.teal),
                    ],
                  ),
                  onTap: () {
                    setState(() {
                      _currentGroupId = group['id'];
                    });
                    _fetchMembersData(group['id']); // Navega para a tela de filtragem
                  },
                ),
              );
            },
          );
  }

  Widget _buildCreateGroupForm() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _groupNameController,
            decoration: InputDecoration(
              labelText: 'Nome do Grupo',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              filled: true,
              fillColor: Colors.grey[100],
            ),
          ),
          const SizedBox(height: 20.0),
          ElevatedButton(
            onPressed: _isCreatingGroup ? null : _createGroup,
            child: _isCreatingGroup
                ? CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  )
                : Text('Criar Grupo'),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 16.0), backgroundColor: Colors.teal,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterGroupScreen() {
    return _isFiltering
        ? Center(child: CircularProgressIndicator())
        : Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Mês: ${DateFormat('MMMM yyyy', 'pt_BR').format(_selectedDate)}',
                      style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              title: Text('Escolher Data'),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ElevatedButton(
                                    onPressed: () {
                                      _showDatePicker();
                                      Navigator.of(context).pop(); // Fechar o diálogo após selecionar a data
                                    },
                                    child: Text('Selecionar Data'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.teal,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                      child: Text('Selecionar Mês'),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 24.0), backgroundColor: Colors.teal,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _members.isEmpty
                    ? Center(
                        child: Text('Nenhum membro encontrado para o período selecionado.'))
                    : ListView.builder(
                        itemCount: _members.length,
                        itemBuilder: (context, index) {
                          final member = _members[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                            child: ListTile(
                              title: Text(
                                member['nome'],
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                              ),
                              subtitle: Text('Gastos: \$${member['gastos'].toStringAsFixed(2)}'),
                              trailing: Text(member['email'], style: TextStyle(color: Colors.grey)),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
  }

  Widget _buildCurrentMonthExpensesScreen() {
    return _isFiltering
        ? Center(child: CircularProgressIndicator())
        : _members.isEmpty
            ? Center(
                child: Text('Nenhum membro com gastos no mês atual.'),
              )
            : ListView.builder(
                itemCount: _members.length,
                itemBuilder: (context, index) {
                  final member = _members[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                    child: ListTile(
                      title: Text(
                        member['nome'],
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text('Gastos: \$${member['gastos'].toStringAsFixed(2)}'),
                      trailing: Text(member['email'], style: TextStyle(color: Colors.grey)),
                    ),
                  );
                },
              );
  }

  void _showDatePicker() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      locale: const Locale("pt", "BR"),
    );
    if (pickedDate != null && pickedDate != _selectedDate) {
      _onDateSelected(pickedDate);
    }
  }

  void _showInviteUserDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Convidar Usuário para o Grupo'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _inviteEmailController,
                decoration: InputDecoration(
                  labelText: 'Email do Usuário',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                _inviteUserToGroup();
                Navigator.of(context).pop();
              },
              child: Text('Enviar Convite'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
            ),
          ],
        );
      },
    );
  }
}
