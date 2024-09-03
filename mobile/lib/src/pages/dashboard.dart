import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class DashboardPage extends StatefulWidget {
  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  bool _isLoading = true;
  double receitas = 0.0;
  double despesas = 0.0;
  String selectedMonth = "Julho";
  int? _userId;

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? userId = prefs.getInt('user_id');
    if (userId != null) {
      setState(() {
        _userId = userId;
      });
      _fetchExpensesData(userId);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ID do usuário não encontrado, faça login novamente.')),
      );
    }
  }

  Future<void> _fetchExpensesData(int userId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    if (token != null) {
      final url = Uri.parse('http://10.0.2.2:8000/transactions/record-fixed-variable-expenses/$userId/');
      try {
        final response = await http.get(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Token $token',
          },
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          setState(() {
            receitas = data['receitas'] ?? 0.0;
            despesas = data['despesas'] ?? 0.0;
            _isLoading = false;
          });
        } else {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao carregar dados: ${response.body}')),
          );
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CircleAvatar(
                        radius: 30.0,
                        backgroundColor: Colors.teal,
                        child: Icon(Icons.person, size: 30.0, color: Colors.white),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Fulano', style: TextStyle(fontSize: 18.0)),
                          DropdownButton<String>(
                            value: selectedMonth,
                            items: <String>['Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho', 'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro']
                                .map((String month) {
                              return DropdownMenuItem<String>(
                                value: month,
                                child: Text(month),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                selectedMonth = newValue!;
                                // Recarregar os dados para o mês selecionado
                              });
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20.0),
                  Expanded(
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceEvenly,
                        maxY: _calculateMaxY(),
                        barGroups: _buildBarGroups(),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true)),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          Text(
                            receitas.toStringAsFixed(2),
                            style: TextStyle(fontSize: 18.0, color: Colors.green, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Receitas',
                            style: TextStyle(fontSize: 16.0, color: Colors.black54),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          Text(
                            despesas.toStringAsFixed(2),
                            style: TextStyle(fontSize: 18.0, color: Colors.red, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Despesas',
                            style: TextStyle(fontSize: 16.0, color: Colors.black54),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20.0),
                  Text(
                    'Saldo: ${(receitas - despesas).toStringAsFixed(2)}',
                    style: TextStyle(fontSize: 18.0, color: Colors.black54),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
    );
  }

  double _calculateMaxY() {
    return (receitas > despesas ? receitas : despesas) + 10;  // Ajusta a altura máxima do gráfico
  }

  List<BarChartGroupData> _buildBarGroups() {
    return [
      BarChartGroupData(
        x: 0,
        barRods: [
          BarChartRodData(
            toY: receitas,
            color: Colors.green,
            width: 20,
          ),
          BarChartRodData(
            toY: despesas,
            color: Colors.red,
            width: 20,
          ),
        ],
      ),
    ];
  }
}
