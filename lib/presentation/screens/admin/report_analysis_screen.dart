import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:house_rental_app/presentation/providers/report_provider.dart';
import 'package:house_rental_app/presentation/providers/property_provider.dart';
import 'package:house_rental_app/utils/currency_utils.dart';
import 'package:intl/intl.dart';

class ReportAnalysisScreen extends StatefulWidget {
  @override
  _ReportAnalysisScreenState createState() => _ReportAnalysisScreenState();
}

class _ReportAnalysisScreenState extends State<ReportAnalysisScreen> {
  bool _isLoading = false;
  String? _errorMessage;
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadReports();
    });
  }

  Future<void> _loadReports() async {
    setState(() => _isLoading = true);
    try {
      final reportProvider =
          Provider.of<ReportProvider>(context, listen: false);
      final propertyProvider =
          Provider.of<PropertyProvider>(context, listen: false);

      // Ensure properties are fetched
      if (propertyProvider.properties.isEmpty) {
        await propertyProvider.fetchProperties();
      }

      final propertyIds = propertyProvider.properties.map((p) => p.id).toList();
      await reportProvider.loadMonthlyRevenue(
          _selectedYear, _selectedMonth, propertyIds);
      await reportProvider.loadExpiringLeasesCount(30);
      await reportProvider.loadOccupancyRate();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final reportProvider = Provider.of<ReportProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Report & Analysis'),
        actions: [
          IconButton(icon: Icon(Icons.refresh), onPressed: _loadReports),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text('Error: $_errorMessage'))
              : SingleChildScrollView(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          'Monthly Revenue: ${CurrencyUtils.formatCurrency(reportProvider.monthlyRevenue)}',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      SizedBox(height: 16),
                      Text(
                          'Expiring Leases(30 days): ${reportProvider.expiringLeasesCount}'),
                      SizedBox(height: 16),
                      Text(
                          'Occupancy Rate: ${(reportProvider.occupancyRate * 100).toStringAsFixed(2)}%'),
                      SizedBox(height: 16),
                      // Placeholder UI for PDF/Report Generation:
                      Text(
                          'For PDF/Excel Reports, integrate printing or pdf libraries and implement a button to generate the report after data is loaded.'),
                      ElevatedButton(
                        onPressed: () {
                          // Implement PDF/Excel generation here
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(
                                  'Report generation not implemented yet.')));
                        },
                        child: Text('Generate PDF Report'),
                      )
                    ],
                  ),
                ),
    );
  }
}
