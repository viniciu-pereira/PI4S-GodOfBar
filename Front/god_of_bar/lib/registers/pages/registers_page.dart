import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:god_of_bar/core/models/register_model.dart';
import 'package:god_of_bar/graphics/pages/graphic_page.dart';
import 'package:http/http.dart' as http;


class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  RegisterPageState createState() => RegisterPageState();
}

class RegisterPageState extends State<RegisterPage> {
  late Future<List<RegisterModel>> futureData;
  late List<RegisterModel> dataList;
  int _currentPage = 0;
  final int _itemsPerPage = 50;

  @override
  void initState() {
    super.initState();
    futureData = fetchData();
  }

  Future<List<RegisterModel>> fetchData() async {
    final url = Uri.parse('https://apaixonautas.com.br/consulta.php');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      List<RegisterModel> list = data.map((json) => RegisterModel.fromJson(json)).toList();
      list.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      return list;
    } else {
      throw Exception('Failed to load data');
    }
  }

  List<RegisterModel> _getCurrentPageItems(List<RegisterModel> data) {
    int start = _currentPage * _itemsPerPage;
    int end = start + _itemsPerPage;
    return data.sublist(start, end > data.length ? data.length : end);
  }

  void _nextPage(List<RegisterModel> data) {
    if ((_currentPage + 1) * _itemsPerPage < data.length) {
      setState(() {
        _currentPage++;
      });
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      setState(() {
        _currentPage--;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 32.0),
            child: GestureDetector(
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => GraphicPage(list: dataList)));
              },
              child: const Icon(
                Icons.auto_graph_sharp,
                size: 40,
              ),
            ),
          )
        ],
        title: const Text('Registros da API'),
      ),
      body: FutureBuilder<List<RegisterModel>>(
        future: futureData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No data available'));
          } else {
            final data = snapshot.data!;
            dataList = data;
            final currentPageItems = _getCurrentPageItems(data);
            return SizedBox(
              height: MediaQuery.of(context).size.height,
              child: Column(
                children: [
                  Expanded(
                    flex: 9,
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: currentPageItems.length,
                            itemBuilder: (context, index) {
                              final item = currentPageItems[index];
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 64, vertical: 8),
                                child: ListTile(
                                  style: ListTileStyle.drawer,
                                  tileColor: Colors.grey[200],
                                  title: Text('ID: ${item.id}'),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                          'Temperature: ${item.temperature}°C'),
                                      Text('Humidity: ${item.humidity}%'),
                                      Text('Timestamp: ${item.timestamp}'),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Container(
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 54),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            if (_currentPage > 0) ...{
                              TextButton(
                                onPressed: () => _previousPage(),
                                child: const Text(
                                  'Anterior',
                                  style: TextStyle(
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                            } else ...{
                              Container(width: 50)
                            },
                            Text(
                              'Página ${_currentPage + 1}',
                              style: const TextStyle(
                                fontSize: 18,
                              ),
                            ),
                            TextButton(
                              onPressed: () => _nextPage(data),
                              child: const Text(
                                'Próxima',
                                style: TextStyle(
                                  fontSize: 18,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
        },
      ),
    );
  }
}
