import 'package:flutter/material.dart';
import 'package:prediction_app/pages/details_page.dart';
import 'settings_page.dart';
import 'login_page.dart';
import '../api_service.dart';

class MainPage extends StatefulWidget {
  final VoidCallback toggleTheme;
  final bool isLoggedIn;
  final ApiService apiService;
  final String? userName;

  MainPage({
    required this.toggleTheme,
    required this.isLoggedIn,
    required this.apiService,
    this.userName,
  });
  
  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final TextEditingController searchController = TextEditingController();
  final TextEditingController tickerInputController = TextEditingController();

  List<String> trackedTickers = [];
  Map<String, Map<String, dynamic>> stockData = {};
  bool isLoading = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    // Start with some default tickers
    trackedTickers = ['AAPL', 'GOOGL', 'MSFT'];
    loadAllStockData();
  }

  Future<void> loadAllStockData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      // Add all tickers to the backend
      for (String ticker in trackedTickers) {
        await widget.apiService.addTicker(ticker);
      }
      
      // Update estimations for all tickers
      await widget.apiService.updateEstimations();
      
      // Get predictions
      final estimations = await widget.apiService.getEstimations();
      
      // Process the data
      Map<String, Map<String, dynamic>> newStockData = {};
      for (String ticker in trackedTickers) {
        newStockData[ticker] = {
          'ticker': ticker,
          'predictions': estimations[ticker] ?? {},
        };
      }
      
      setState(() {
        stockData = newStockData;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to load stock data: $e';
        isLoading = false;
      });
      print('Error loading stock data: $e');
    }
  }

  Future<void> addNewTicker(String ticker) async {
    ticker = ticker.toUpperCase().trim();
    
    if (ticker.isEmpty) {
      _showError('Please enter a ticker symbol');
      return;
    }
    
    if (trackedTickers.contains(ticker)) {
      _showError('$ticker is already being tracked');
      return;
    }

    setState(() => isLoading = true);

    try {
      await widget.apiService.addTicker(ticker);
      await widget.apiService.updateEstimations();
      
      setState(() {
        trackedTickers.add(ticker);
      });
      
      await loadAllStockData();
      _showSuccess('$ticker added successfully');
      tickerInputController.clear();
    } catch (e) {
      _showError('Failed to add $ticker: $e');
      setState(() => isLoading = false);
    }
  }

  void removeTicker(String ticker) {
    setState(() {
      trackedTickers.remove(ticker);
      stockData.remove(ticker);
    });
    _showSuccess('$ticker removed');
  }

  List<String> getFilteredTickers() {
    String query = searchController.text.toLowerCase();
    if (query.isEmpty) return trackedTickers;
    
    return trackedTickers
        .where((ticker) => ticker.toLowerCase().contains(query))
        .toList();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredTickers = getFilteredTickers();
    
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: searchController,
          onChanged: (value) => setState(() {}),
          decoration: InputDecoration(
            hintText: "Search tickers...",
            border: InputBorder.none,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: isLoading ? null : loadAllStockData,
          ),
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SettingsPage(
                    toggleTheme: widget.toggleTheme,
                    isLoggedIn: widget.isLoggedIn,
                    apiService: widget.apiService,
                  ),
                ),
              );
            },
          ),
          if (!widget.isLoggedIn)
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => LoginPage(
                      toggleTheme: widget.toggleTheme,
                      apiService: widget.apiService,
                    ),
                  ),
                );
              },
              child: Text("Login"),
            ),
        ],
      ),
      body: Column(
        children: [
          // Add ticker section
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: tickerInputController,
                    decoration: InputDecoration(
                      labelText: "Add new ticker (e.g., TSLA)",
                      border: OutlineInputBorder(),
                    ),
                    textCapitalization: TextCapitalization.characters,
                  ),
                ),
                SizedBox(width: 8),
                ElevatedButton(
                  onPressed: isLoading 
                    ? null 
                    : () => addNewTicker(tickerInputController.text),
                  child: Icon(Icons.add),
                ),
              ],
            ),
          ),

          if (errorMessage != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                errorMessage!,
                style: TextStyle(color: Colors.red),
              ),
            ),

          if (isLoading)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),

          // Stock list
          Expanded(
            child: filteredTickers.isEmpty
                ? Center(
                    child: Text(
                      'No tickers tracked. Add one above!',
                      style: TextStyle(fontSize: 16),
                    ),
                  )
                : ListView.builder(
                    itemCount: filteredTickers.length,
                    itemBuilder: (context, index) {
                      String ticker = filteredTickers[index];
                      var data = stockData[ticker];
                      
                      return Card(
                        margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: ListTile(
                          title: Text(
                            ticker,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            data != null 
                              ? 'Tap to view predictions' 
                              : 'Loading...',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (widget.isLoggedIn)
                                IconButton(
                                  icon: Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => removeTicker(ticker),
                                ),
                              Icon(Icons.arrow_forward_ios),
                            ],
                          ),
                          onTap: data != null
                              ? () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => DetailsPage(
                                        toggleTheme: widget.toggleTheme,
                                        ticker: ticker,
                                        predictions: data['predictions'] ?? {},
                                        apiService: widget.apiService,
                                      ),
                                    ),
                                  );
                                }
                              : null,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}