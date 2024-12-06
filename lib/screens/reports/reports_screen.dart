import 'package:flutter/material.dart';
import 'package:house_rental_app/models/payment.dart';
import 'package:house_rental_app/providers/payment_provider.dart';
import 'package:provider/provider.dart';

class ReportsScreen extends StatefulWidget {
  @override
  _ReportsScreenState createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTimeRange _dateRange = DateTimeRange(
    start: DateTime.now().subtract(Duration(days: 30)),
    end: DateTime.now(),
  );

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Reports'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Revenue'),
            Tab(text: 'Occupancy'),
            Tab(text: 'Maintenance'),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.calendar_today),
            onPressed: _selectDateRange,
          ),
          IconButton(
            icon: Icon(Icons.file_download),
            onPressed: _exportReport,
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          RevenueReport(dateRange: _dateRange),
          OccupancyReport(dateRange: _dateRange),
          MaintenanceReport(dateRange: _dateRange),
        ],
      ),
    );
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _dateRange,
    );
    if (picked != null) {
      setState(() => _dateRange = picked);
    }
  }

  Future<void> _exportReport() async {
    try {
      final reportData = await _generateReport();
      final pdf = await _generatePDF(reportData);
      await _savePDF(pdf);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Report exported successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error exporting report: $e')),
      );
    }
  }

  Future<Map<String, dynamic>> _generateReport() async {
    // Generate report data based on current tab and date range
    return {};
  }
}

// Reports Components
class RevenueReport extends StatelessWidget {
  final DateTimeRange dateRange;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Payment>>(
      future: context.read<PaymentProvider>().getPaymentsByDateRange(
            dateRange.start,
            dateRange.end,
          ),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        final payments = snapshot.data!;
        final totalRevenue = payments.fold<double>(
          0,
          (sum, payment) => sum + payment.amount,
        );

        return SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              _buildRevenueOverview(totalRevenue, payments),
              SizedBox(height: 24),
              _buildRevenueChart(payments),
              SizedBox(height: 24),
              _buildPaymentsList(payments),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRevenueOverview(double totalRevenue, List<Payment> payments) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              '₹${totalRevenue.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text('Total Revenue'),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStat('Payments', payments.length.toString()),
                _buildStat(
                  'Average',
                  '₹${(totalRevenue / payments.length).toStringAsFixed(2)}',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
