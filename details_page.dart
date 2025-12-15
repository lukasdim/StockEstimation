import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../api_service.dart';

class DetailsPage extends StatefulWidget {
  final VoidCallback toggleTheme;
  final String ticker;
  final Map<String, dynamic> predictions;
  final ApiService apiService;

  DetailsPage({
    required this.toggleTheme,
    required this.ticker,
    required this.predictions,
    required this.apiService,
  });

  @override
  State<DetailsPage> createState() => _DetailsPageState();
}

class _DetailsPageState extends State<DetailsPage> {
  bool showLongTerm = false; // false = short term, true = long term
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.ticker} Analysis"),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _refreshData,
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Text(
                    widget.ticker,
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'AI-Powered Stock Predictions',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  SizedBox(height: 24),

                  // Mode Toggle
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                showLongTerm ? "Long-Term Forecast" : "Short-Term Forecast",
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 4),
                              Text(
                                showLongTerm 
                                  ? "90-day Prophet prediction" 
                                  : "21-day LightGBM prediction",
                                style: TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                          Switch(
                            value: showLongTerm,
                            onChanged: (val) {
                              setState(() {
                                showLongTerm = val;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 20),

                  // Chart
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Price Predictions',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 16),
                          Container(
                            height: 300,
                            child: _buildChart(),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 20),

                  // Statistics
                  if (!showLongTerm) _buildShortTermStats(),
                  if (showLongTerm) _buildLongTermStats(),
                ],
              ),
            ),
    );
  }

  Widget _buildChart() {
    if (widget.predictions.isEmpty) {
      return Center(
        child: Text('No prediction data available'),
      );
    }

    List<FlSpot> spots = _getChartSpots();
    
    if (spots.isEmpty) {
      return Center(child: Text('No data points available'));
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(show: true, drawVerticalLine: true),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 50,
              getTitlesWidget: (value, meta) {
                return Text(
                  '\$${value.toStringAsFixed(0)}',
                  style: TextStyle(fontSize: 10),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                int day = value.toInt();
                if (day % 7 == 0 || day == 0) {
                  return Text(
                    'Day $day',
                    style: TextStyle(fontSize: 10),
                  );
                }
                return Text('');
              },
            ),
          ),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: true),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: showLongTerm ? Colors.blue : Colors.green,
            barWidth: 3,
            dotData: FlDotData(show: spots.length < 30),
            belowBarData: BarAreaData(
              show: true,
              color: (showLongTerm ? Colors.blue : Colors.green).withOpacity(0.1),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (touchedSpot) => Colors.blueGrey.withOpacity(0.8),
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                return LineTooltipItem(
                  'Day ${spot.x.toInt()}\n\${spot.y.toStringAsFixed(2)}',
                  TextStyle(color: Colors.white),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  List<FlSpot> _getChartSpots() {
    List<FlSpot> spots = [];
    
    try {
      if (showLongTerm) {
        // Long-term predictions (yhat, yhat_lower, yhat_upper)
        var dates = widget.predictions.keys.toList()..sort();
        
        for (int i = 0; i < dates.length; i++) {
          var dateData = widget.predictions[dates[i]];
          if (dateData != null && dateData['yhat'] != null) {
            double price = (dateData['yhat'] as num).toDouble();
            spots.add(FlSpot(i.toDouble(), price));
          }
        }
      } else {
        // Short-term predictions (predicted_price)
        var dates = widget.predictions.keys.toList()..sort();
        
        for (int i = 0; i < dates.length; i++) {
          var dateData = widget.predictions[dates[i]];
          if (dateData != null && dateData['predicted_price'] != null) {
            double price = (dateData['predicted_price'] as num).toDouble();
            spots.add(FlSpot(i.toDouble(), price));
          }
        }
      }
    } catch (e) {
      print('Error building chart spots: $e');
    }
    
    return spots;
  }

  Widget _buildShortTermStats() {
    var dates = widget.predictions.keys.toList()..sort();
    
    if (dates.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text('No prediction data available'),
        ),
      );
    }

    List<double> prices = [];
    for (var date in dates) {
      var data = widget.predictions[date];
      if (data != null && data['predicted_price'] != null) {
        prices.add((data['predicted_price'] as num).toDouble());
      }
    }

    if (prices.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text('No price data available'),
        ),
      );
    }

    double minPrice = prices.reduce((a, b) => a < b ? a : b);
    double maxPrice = prices.reduce((a, b) => a > b ? a : b);
    double avgPrice = prices.reduce((a, b) => a + b) / prices.length;
    double firstPrice = prices.first;
    double lastPrice = prices.last;
    double change = ((lastPrice - firstPrice) / firstPrice) * 100;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Short-Term Statistics (21 days)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            _buildStatRow('Starting Price', '\$${firstPrice.toStringAsFixed(2)}'),
            _buildStatRow('Ending Price', '\$${lastPrice.toStringAsFixed(2)}'),
            _buildStatRow(
              'Expected Change', 
              '${change >= 0 ? '+' : ''}${change.toStringAsFixed(2)}%',
              color: change >= 0 ? Colors.green : Colors.red,
            ),
            _buildStatRow('Average Price', '\$${avgPrice.toStringAsFixed(2)}'),
            _buildStatRow('Lowest Price', '\$${minPrice.toStringAsFixed(2)}'),
            _buildStatRow('Highest Price', '\$${maxPrice.toStringAsFixed(2)}'),
          ],
        ),
      ),
    );
  }

  Widget _buildLongTermStats() {
    var dates = widget.predictions.keys.toList()..sort();
    
    if (dates.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text('No prediction data available'),
        ),
      );
    }

    List<double> prices = [];
    List<double> lowerBounds = [];
    List<double> upperBounds = [];
    
    for (var date in dates) {
      var data = widget.predictions[date];
      if (data != null) {
        if (data['yhat'] != null) {
          prices.add((data['yhat'] as num).toDouble());
        }
        if (data['yhat_lower'] != null) {
          lowerBounds.add((data['yhat_lower'] as num).toDouble());
        }
        if (data['yhat_upper'] != null) {
          upperBounds.add((data['yhat_upper'] as num).toDouble());
        }
      }
    }

    if (prices.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text('No price data available'),
        ),
      );
    }

    double firstPrice = prices.first;
    double lastPrice = prices.last;
    double avgPrice = prices.reduce((a, b) => a + b) / prices.length;
    double change = ((lastPrice - firstPrice) / firstPrice) * 100;
    
    double? lastLower = lowerBounds.isNotEmpty ? lowerBounds.last : null;
    double? lastUpper = upperBounds.isNotEmpty ? upperBounds.last : null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Long-Term Statistics (90 days)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            _buildStatRow('Starting Price', '\$${firstPrice.toStringAsFixed(2)}'),
            _buildStatRow('Expected Price', '\$${lastPrice.toStringAsFixed(2)}'),
            _buildStatRow(
              'Expected Change', 
              '${change >= 0 ? '+' : ''}${change.toStringAsFixed(2)}%',
              color: change >= 0 ? Colors.green : Colors.red,
            ),
            _buildStatRow('Average Price', '\$${avgPrice.toStringAsFixed(2)}'),
            if (lastLower != null && lastUpper != null) ...[
              Divider(),
              Text('Confidence Interval:', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              _buildStatRow('Lower Bound', '\$${lastLower.toStringAsFixed(2)}'),
              _buildStatRow('Upper Bound', '\$${lastUpper.toStringAsFixed(2)}'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 14)),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _refreshData() async {
    setState(() => isLoading = true);
    
    try {
      await widget.apiService.addTicker(widget.ticker);
      await widget.apiService.updateEstimations();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Data refreshed successfully'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Pop back to reload main page
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to refresh: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }
}