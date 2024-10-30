import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// import 'package:inner_bhakti/msft/ticker_node_screen.dart';
import './ticker_node_screen.dart';

class TickerInputScreen extends StatefulWidget {
  @override
  _TickerInputScreenState createState() => _TickerInputScreenState();
}

class _TickerInputScreenState extends State<TickerInputScreen> {
  final TextEditingController _controller = TextEditingController();
  String _companyName = '';
  List<EarningsData> _earningsData = [];
  bool _isLoading = false;

  Future<void> fetchEarningsData(String ticker) async {
    setState(() => _isLoading = true);
    final url = Uri.parse(
        'https://api.api-ninjas.com/v1/earningscalendar?ticker=$ticker');
    final response = await http.get(
      url,
      headers: {'X-Api-Key': 'YOUR_API_KEY'},
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List;
      _earningsData = data.map((item) => EarningsData.fromJson(item)).toList();
      setState(() => _companyName = ticker.toUpperCase());
    } else {
      setState(() => _companyName = 'Error fetching data');
    }
    setState(() => _isLoading = false);
  }

  void _onFetchData() {
    final ticker = _controller.text.trim();
    if (ticker.isNotEmpty) {
      FocusScope.of(context).unfocus(); // Hide keyboard
      fetchEarningsData(ticker);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(title: Text('Enter Company Ticker')),
        body: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _controller,
                decoration: InputDecoration(
                  labelText: 'Enter Ticker Symbol (e.g., MSFT)',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: _onFetchData,
                child: Text('Get Company Earnings Data'),
              ),
              if (_isLoading) CircularProgressIndicator(),
              if (_earningsData.isNotEmpty)
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 20.0),
                    child: EarningsChart(
                      earningsData: _earningsData,
                      companyName: _companyName,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class EarningsData {
  final String priceDate;
  final double actualEPS;
  final double estimatedEPS;

  EarningsData({
    required this.priceDate,
    required this.actualEPS,
    required this.estimatedEPS,
  });

  factory EarningsData.fromJson(Map<String, dynamic> json) {
    return EarningsData(
      priceDate: json['pricedate'],
      actualEPS: json['actual_eps'] ?? 0.0,
      estimatedEPS: json['estimated_eps'] ?? 0.0,
    );
  }
}

class EarningsChart extends StatelessWidget {
  final List<EarningsData> earningsData;
  final String companyName;

  EarningsChart({required this.earningsData, required this.companyName});

  @override
  Widget build(BuildContext context) {
    // Determine min and max values from earnings data
    double minY =
        earningsData.map((e) => e.actualEPS).reduce((a, b) => a < b ? a : b);
    double maxY =
        earningsData.map((e) => e.actualEPS).reduce((a, b) => a > b ? a : b);

    return LineChart(
      LineChartData(
        minY: minY - 1, // Set a little below the min value
        maxY: maxY + 1, // Set a little above the max value
        lineBarsData: [
          LineChartBarData(
            spots: earningsData
                .asMap()
                .entries
                .map((e) => FlSpot(e.key.toDouble(), e.value.actualEPS))
                .toList(),
            isCurved: true,
            color: Colors.green,
            belowBarData: BarAreaData(show: false),
            dotData: FlDotData(show: true),
          ),
          LineChartBarData(
            spots: earningsData
                .asMap()
                .entries
                .map((e) => FlSpot(e.key.toDouble(), e.value.estimatedEPS))
                .toList(),
            isCurved: true,
            color: Colors.blue,
            belowBarData: BarAreaData(show: false),
            dotData: FlDotData(show: true),
          ),
        ],
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < earningsData.length) {
                  return Text(
                    earningsData[index].priceDate,
                    style: TextStyle(fontSize: 10),
                  );
                }
                return Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(value.toString(),
                    style: TextStyle(fontSize: 10)); // Customize Y-axis labels
              },
            ),
          ),
        ),
        lineTouchData: LineTouchData(
          touchCallback: (touchEvent, touchResponse) {
            if (touchResponse != null &&
                touchResponse.lineBarSpots != null &&
                touchResponse.lineBarSpots!.isNotEmpty) {
              final index = touchResponse.lineBarSpots!.first.spotIndex;
              final selectedData = earningsData[index];
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TranscriptScreen(
                    priceDate: selectedData.priceDate,
                    ticker: companyName,
                  ),
                ),
              );
            }
          },
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((touchedSpot) {
                final date = earningsData[touchedSpot.spotIndex].priceDate;
                final actual = earningsData[touchedSpot.spotIndex].actualEPS;
                final estimated =
                    earningsData[touchedSpot.spotIndex].estimatedEPS;
                return LineTooltipItem(
                  '$date\nActual EPS: $actual\nEstimated EPS: $estimated',
                  TextStyle(color: Colors.white),
                );
              }).toList();
            },
          ),
          handleBuiltInTouches: true,
        ),
      ),
    );
  }
}
