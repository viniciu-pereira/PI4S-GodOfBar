import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const DataListPage(),
    );
  }
}

class YourDataModel {
  final String id;
  final String temperature;
  final String humidity;
  final String timestamp;

  YourDataModel({
    required this.id,
    required this.temperature,
    required this.humidity,
    required this.timestamp,
  });

  factory YourDataModel.fromJson(Map<String, dynamic> json) {
    return YourDataModel(
      id: json['id'] as String,
      temperature: json['temperature'] as String,
      humidity: json['humidity'] as String,
      timestamp: json['timestamp'] as String,
    );
  }
}

class DataListPage extends StatefulWidget {
  const DataListPage({super.key});

  @override
  DataListPageState createState() => DataListPageState();
}

class DataListPageState extends State<DataListPage> {
  late Future<List<YourDataModel>> futureData;
  late List<YourDataModel> dataList;
  int _currentPage = 0;
  final int _itemsPerPage = 50;

  @override
  void initState() {
    super.initState();
    futureData = fetchData();
  }

  Future<List<YourDataModel>> fetchData() async {
    final url = Uri.parse('https://apaixonautas.com.br/consulta.php');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      List<YourDataModel> list =
          data.map((json) => YourDataModel.fromJson(json)).toList();
      list.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      return list;
    } else {
      throw Exception('Failed to load data');
    }
  }

  List<YourDataModel> _getCurrentPageItems(List<YourDataModel> data) {
    int start = _currentPage * _itemsPerPage;
    int end = start + _itemsPerPage;
    return data.sublist(start, end > data.length ? data.length : end);
  }

  void _nextPage(List<YourDataModel> data) {
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
      body: FutureBuilder<List<YourDataModel>>(
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
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (_currentPage > 0) ...{
                            TextButton(
                              onPressed: () => _previousPage(),
                              child: const Text('Anterior'),
                            ),
                          } else ...{
                            Container(width: 50)
                          },
                          Text('Página ${_currentPage + 1}'),
                          TextButton(
                            onPressed: () => _nextPage(data),
                            child: const Text('Próxima'),
                          ),
                        ],
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

class GraphicPage extends StatelessWidget {
  final List<YourDataModel> list;
  const GraphicPage({super.key, required this.list});

  @override
  Widget build(BuildContext context) {
       // Filtrando apenas os dados do dia anterior (11)
    List<FlSpot> spots = [];
    List<FlSpot> spots2 = [];
    DateTime now = DateTime.now();
    DateTime yesterday = DateTime(now.year, now.month, now.day - 1);

    for (YourDataModel data in list) {
      DateTime dataTime = DateTime.parse(data.timestamp);
      if (dataTime.day == yesterday.day && dataTime.month == yesterday.month) {
        double hours = dataTime.hour.toDouble();
        spots.add(FlSpot(hours, double.parse(data.temperature)));
        spots2.add(FlSpot(hours, double.parse(data.humidity)));
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gráfico'),
      ),
      body: Column(
        children: [
          SizedBox(
            height: 400,
            child: LineChart(
              LineChartData(
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: false,
                    dotData: const FlDotData(show: true),
                  ),
                  LineChartBarData(
                    color: Colors.red,
                    spots: spots2,
                    isCurved: false,
                    dotData: const FlDotData(show: true),
                  )
                ],
                titlesData: const FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: true),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
