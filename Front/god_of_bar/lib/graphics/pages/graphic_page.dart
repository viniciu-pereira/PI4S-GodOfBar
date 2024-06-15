import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:god_of_bar/core/models/register_model.dart';
import 'package:intl/intl.dart';

class GraphicPage extends StatefulWidget {
  final List<RegisterModel> list;
  const GraphicPage({super.key, required this.list});

  @override
  GraphicPageState createState() => GraphicPageState();
}

class GraphicPageState extends State<GraphicPage> {
  int _selectedInterval = 5; // Default interval is 5 minutes
  DateTimeRange? _selectedDateRange;
  final DateTime _now = DateTime.now();

  List<List<FlSpot>> _generateSpots(List<RegisterModel> list, int interval, DateTimeRange? dateRange) {
    Map<int, List<RegisterModel>> groupedData = {};
    DateTime startDate = dateRange?.start ?? DateTime(_now.year, _now.month, _now.day);
    DateTime endDate = dateRange?.end ?? DateTime(_now.year, _now.month, _now.day + 1);

    for (RegisterModel data in list) {
      DateTime dataTime = DateTime.parse(data.timestamp);
      if (dataTime.isAfter(startDate) && dataTime.isBefore(endDate)) {
        int intervalGroup = (dataTime.hour * 60 + dataTime.minute) ~/ interval;
        if (!groupedData.containsKey(intervalGroup)) {
          groupedData[intervalGroup] = [];
        }
        groupedData[intervalGroup]!.add(data);
      }
    }

    List<FlSpot> spots = [];
    List<FlSpot> spots2 = [];
    groupedData.forEach((intervalGroup, dataList) {
      double avgTemperature = dataList.map((e) => double.parse(e.temperature)).reduce((a, b) => a + b) / dataList.length;
      double avgHumidity = dataList.map((e) => double.parse(e.humidity)).reduce((a, b) => a + b) / dataList.length;
      spots.add(FlSpot(intervalGroup.toDouble(), avgTemperature));
      spots2.add(FlSpot(intervalGroup.toDouble(), avgHumidity));
    });

    return [spots, spots2];
  }

  @override
  Widget build(BuildContext context) {
    List<FlSpot> spots = _generateSpots(widget.list, _selectedInterval, _selectedDateRange)[0];
    List<FlSpot> spots2 = _generateSpots(widget.list, _selectedInterval, _selectedDateRange)[1];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gráfico'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Select Interval: '),
                    DropdownButton<int>(
                      value: _selectedInterval,
                      items: const [
                        DropdownMenuItem(value: 5, child: Text('5 minutes')),
                        DropdownMenuItem(value: 10, child: Text('10 minutes')),
                        DropdownMenuItem(value: 30, child: Text('30 minutes')),
                        DropdownMenuItem(value: 60, child: Text('1 hour')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedInterval = value;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: ElevatedButton(
                  onPressed: () async {
                    DateTimeRange? picked = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                      initialDateRange: _selectedDateRange ?? DateTimeRange(start: DateTime.now().subtract(const Duration(days: 1)), end: DateTime.now()),
                    );
                    if (picked != null && picked != _selectedDateRange) {
                      setState(() {
                        _selectedDateRange = picked;
                      });
                    }
                  },
                  child: const Text('Select Date Range'),
                ),
              ),
              Text(
                _selectedDateRange == null
                    ? 'Showing data for: Today'
                    : 'Showing data from: ${DateFormat('yyyy-MM-dd').format(_selectedDateRange!.start)} to ${DateFormat('yyyy-MM-dd').format(_selectedDateRange!.end)}',
                style: const TextStyle(fontSize: 16),
              ),
              SizedBox(
                height: 400,
                child: LineChart(
                  LineChartData(
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        color: Colors.blue,
                        barWidth: 2,
                        isStrokeCapRound: true,
                        dotData: const FlDotData(show: true),
                        belowBarData: BarAreaData(
                          show: true,
                          color: Colors.blue.withOpacity(0.3),
                        ),
                      ),
                      LineChartBarData(
                        spots: spots2,
                        isCurved: true,
                        color:Colors.red,
                        barWidth: 2,
                        isStrokeCapRound: true,
                        dotData: const FlDotData(show: true),
                        belowBarData: BarAreaData(
                          show: true,
                          color:Colors.red.withOpacity(0.3),
                        ),
                      ),
                    ],
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: (24 * 60 / _selectedInterval).ceil() / 12, // show label for each interval
                          getTitlesWidget: (value, meta) {
                            int minuteOfDay = value.toInt() * _selectedInterval;
                            DateTime time = DateTime(2024, 6, 11).add(Duration(minutes: minuteOfDay));
                            return Text(DateFormat.Hm().format(time));
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            return Text(value.toInt().toString());
                          },
                        ),
                      ),
                    ),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: true,
                      getDrawingVerticalLine: (value) {
                        return const FlLine(
                          color: Color(0xff37434d),
                          strokeWidth: 1,
                        );
                      },
                      getDrawingHorizontalLine: (value) {
                        return const FlLine(
                          color: Color(0xff37434d),
                          strokeWidth: 1,
                        );
                      },
                    ),
                    borderData: FlBorderData(
                      show: true,
                      border: Border.all(color: const Color(0xff37434d), width: 1),
                    ),
                    lineTouchData: LineTouchData(
                      touchTooltipData: LineTouchTooltipData(
                        //tooltipBgColor: Colors.blueAccent,
                        getTooltipItems: (touchedSpots) {
                          return touchedSpots.map((spot) {
                            final flSpot = spot;
                            String text = '';
                            if (flSpot.barIndex == 0) {
                              text = 'Temperature: ${flSpot.y}';
                            } else {
                              text = 'Humidity: ${flSpot.y}';
                            }
                            return LineTooltipItem(
                              text,
                              const TextStyle(color: Colors.white),
                            );
                          }).toList();
                        },
                      ),
                      touchCallback: (event, touchResponse) {},
                      handleBuiltInTouches: true,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  LegendItem(color: Colors.blue, text: 'Temperature'),
                  SizedBox(width: 10),
                  LegendItem(color: Colors.red, text: 'Humidity'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class LegendItem extends StatelessWidget {
  final Color color;
  final String text;
  const LegendItem({super.key, required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          color: color,
        ),
        const SizedBox(width: 5),
        Text(text),
      ],
    );
  }
}
