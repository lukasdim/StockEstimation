import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../api_service.dart';
import 'dart:math';

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
  bool showLongTerm = false;
  bool isLoading = false;
  List<double>? STpred;
  final TextEditingController balanceController = TextEditingController(text: '10000.00');
  double currentBalance = 10000.00;

  // NEW: Trading simulation controllers
  final TextEditingController investmentController = TextEditingController(text: '10000.00');
  double investmentAmount = 10000.00;
  bool showSimulation = true;

  @override
  void initState() {
    super.initState();
    _generateSyntheticShortTerm();
    balanceController.addListener(_updateBalance);
    investmentController.addListener(_updateInvestment);
  }

  @override
  void dispose() {
    balanceController.dispose();
    investmentController.dispose();
    super.dispose();
  }

  double? _safeGetDouble(dynamic data, String key) {
    if (data == null) return null;
    
    // Handle both Map types
    dynamic value;
    if (data is Map<String, dynamic>) {
      value = data[key];
    } else if (data is Map) {
      value = data[key];
    } else {
      return null;
    }
    
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    
    return null;
  }

  void _updateBalance() {
    setState(() {
      currentBalance = double.tryParse(balanceController.text) ?? 10000.00;
    });
  }

  void _updateInvestment() {
    setState(() {
      investmentAmount = double.tryParse(investmentController.text) ?? 10000.00;
    });
  }

  void _generateSyntheticShortTerm() {
    try {
      var dates = widget.predictions.keys.toList()..sort();
      
      if (dates.isEmpty) {
        STpred = null;
        return;
      }

      int daysToUse = min(21, dates.length);
      List<double> longTermPrices = [];
      
      for (int i = 0; i < daysToUse; i++) {
        var dateData = widget.predictions[dates[i]];
        if (dateData != null && dateData['yhat'] != null) {
          longTermPrices.add((dateData['yhat'] as num).toDouble());
        }
      }

      if (longTermPrices.isEmpty) {
        STpred = null;
        return;
      }

      STpred = _adjust(longTermPrices);
      
    } catch (e) {
      print('Error generating synthetic short-term: $e');
      STpred = null;
    }
  }

  List<double> _adjust(List<double> basePrices) {
    if (basePrices.isEmpty) return [];
    
    final random = Random(widget.ticker.hashCode); 
    List<double> prices = [];
    
    double avgPrice = basePrices.reduce((a, b) => a + b) / basePrices.length;
    double priceRange = basePrices.reduce(max) - basePrices.reduce(min);
    
    double scale = avgPrice * 0.025;
    
    if (priceRange < avgPrice * 0.02) {
      scale = avgPrice * 0.035;
    }
    
    for (int i = 0; i < basePrices.length; i++) {
      double basePrice = basePrices[i];
      
      double noise = (random.nextDouble() - 0.5) * 2 * scale;
      
      if (i > 0) {
        double momentum = (prices[i - 1] - (i > 1 ? prices[i - 2] : basePrice)) * 0.3;
        noise += momentum;
      }
      
      double oscillation = sin(i * 0.5) * scale * 0.5;
      
      double price = basePrice + noise + oscillation;
      
      double maxDeviation = basePrice * 0.08;
      price = price.clamp(
        basePrice - maxDeviation,
        basePrice + maxDeviation,
      );
      
      prices.add(price);
    }
    
    if (prices.length == basePrices.length && basePrices.isNotEmpty) {
      double targetEnd = basePrices.last;
      double currentEnd = prices.last;
      double adjustment = (targetEnd - currentEnd) / 5;
      
      for (int i = max(0, prices.length - 5); i < prices.length; i++) {
        int stepsFromEnd = prices.length - 1 - i;
        prices[i] += adjustment * (5 - stepsFromEnd);
      }
    }
    
    return prices;
  }

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
                                  : "21-day volatile projection",
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

                  if (!showLongTerm) _buildShortTermStats(),
                  if (showLongTerm) _buildLongTermStats(),

                  SizedBox(height: 20),

                  // NEW: Trading Simulation Section
                  _buildTradingSimulation(),
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
                  'Day ${spot.x.toInt()}\n\$${spot.y.toStringAsFixed(2)}',
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
        var dates = widget.predictions.keys.toList()..sort();
        
        for (int i = 0; i < dates.length; i++) {
          var dateData = widget.predictions[dates[i]];
          if (dateData != null && dateData['yhat'] != null) {
            double price = (dateData['yhat'] as num).toDouble();
            spots.add(FlSpot(i.toDouble(), price));
          }
        }
      } else {
        if (STpred != null) {
          for (int i = 0; i < STpred!.length; i++) {
            spots.add(FlSpot(i.toDouble(), STpred![i]));
          }
        }
      }
    } catch (e) {
      print('Error building chart spots: $e');
    }
    
    return spots;
  }

  Widget _buildShortTermStats() {
    if (STpred == null || STpred!.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text('No prediction data available'),
        ),
      );
    }

    List<double> prices = STpred!;
    
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
            SizedBox(height: 8),
            Text(
              'short-term projection',
              style: TextStyle(fontSize: 11, color: Colors.grey, fontStyle: FontStyle.italic),
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
      
      double? yhat = _safeGetDouble(data, 'yhat');
      double? lower = _safeGetDouble(data, 'yhat_lower');
      double? upper = _safeGetDouble(data, 'yhat_upper');
      
      if (yhat != null) prices.add(yhat);
      if (lower != null) lowerBounds.add(lower);
      if (upper != null) upperBounds.add(upper);
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

  // NEW: Trading Simulation Widget
  Widget _buildTradingSimulation() {
    // Get prices based on current mode
    List<double>? prices;
    
    if (showLongTerm) {
      var dates = widget.predictions.keys.toList()..sort();
      prices = [];
      for (var date in dates) {
        var data = widget.predictions[date];
        double? yhat = _safeGetDouble(data, 'yhat');
        if (yhat != null) {
          prices.add(yhat);
        }
      }
    } else {
      prices = STpred;
    }

    if (prices == null || prices.isEmpty) {
      return Card(
        color: Colors.grey.shade100,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Icon(Icons.trending_up, size: 48, color: Colors.grey),
              SizedBox(height: 8),
              Text(
                'Trading simulation unavailable',
                style: TextStyle(color: Colors.grey),
              ),
              Text(
                'No prediction data to simulate',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    // Calculate simulation results
    double startPrice = prices.first;
    double endPrice = prices.last;
    double numShares = investmentAmount / startPrice;
    double endValue = numShares * endPrice;
    double profit = endValue - investmentAmount;
    double profitPercent = (profit / investmentAmount) * 100;
    
    // Calculate additional metrics
    double maxPrice = prices.reduce((a, b) => a > b ? a : b);
    double minPrice = prices.reduce((a, b) => a < b ? a : b);
    double maxGain = ((maxPrice - startPrice) / startPrice) * 100;
    double maxLoss = ((minPrice - startPrice) / startPrice) * 100;

    return Card(
      elevation: 4,
      color: profit >= 0 
        ? Colors.green.shade50.withOpacity(0.5)
        : Colors.red.shade50.withOpacity(0.5),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.assessment,
                  color: Colors.blue.shade700,
                  size: 28,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Trading Simulation',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        showLongTerm 
                          ? '90-day investment projection' 
                          : '21-day investment projection',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 20),
            
            // Investment Amount Input
            TextField(
              controller: investmentController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Investment Amount',
                prefixText: '\$',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
                suffixIcon: IconButton(
                  icon: Icon(Icons.refresh),
                  tooltip: 'Reset to \$10,000',
                  onPressed: () {
                    investmentController.text = '10000.00';
                  },
                ),
                helperText: 'Enter the amount you want to invest',
              ),
            ),
            
            SizedBox(height: 20),
            
            // Simulation Results
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Simulation Results',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  
                  SizedBox(height: 12),
                  Divider(),
                  SizedBox(height: 12),
                  
                  // Purchase Details
                  _buildStatRow('Entry Price', '\$${startPrice.toStringAsFixed(2)}'),
                  _buildStatRow('Exit Price', '\$${endPrice.toStringAsFixed(2)}'),
                  _buildStatRow('Shares Purchased', numShares.toStringAsFixed(4)),
                  
                  SizedBox(height: 16),
                  Divider(thickness: 2),
                  SizedBox(height: 16),
                  
                  // Investment Summary
                  _buildStatRow(
                    'Initial Investment', 
                    '\$${investmentAmount.toStringAsFixed(2)}',
                    color: Colors.blue.shade700,
                  ),
                  _buildStatRow(
                    'Final Value', 
                    '\$${endValue.toStringAsFixed(2)}',
                    color: profit >= 0 ? Colors.green.shade700 : Colors.red.shade700,
                  ),
                  
                  SizedBox(height: 16),
                  
                  // Profit/Loss Highlight
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: profit >= 0 
                        ? Colors.green.withOpacity(0.15)
                        : Colors.red.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: profit >= 0 
                          ? Colors.green.shade300 
                          : Colors.red.shade300,
                        width: 2,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              profit >= 0 ? 'Projected Profit' : 'Projected Loss',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              '${profit >= 0 ? '+' : ''}\$${profit.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: profit >= 0 ? Colors.green.shade700 : Colors.red.shade700,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Return',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              '${profit >= 0 ? '+' : ''}${profitPercent.toStringAsFixed(2)}%',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: profit >= 0 ? Colors.green.shade700 : Colors.red.shade700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: 16),
                  Divider(),
                  SizedBox(height: 12),
                  
                  // Risk Metrics
                  Text(
                    'Risk Analysis',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  SizedBox(height: 8),
                  _buildStatRow(
                    'Best Case Scenario', 
                    '${maxGain >= 0 ? '+' : ''}${maxGain.toStringAsFixed(2)}%',
                    color: Colors.green.shade700,
                  ),
                  _buildStatRow(
                    'Worst Case Scenario', 
                    '${maxLoss >= 0 ? '+' : ''}${maxLoss.toStringAsFixed(2)}%',
                    color: Colors.red.shade700,
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 16),
            
            // Disclaimer
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.shade300),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.amber.shade800, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This is a simulated projection based on AI predictions. Past performance does not guarantee future results. Not financial advice.',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.amber.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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