//lib/screens/admin/dashboard/revenue_dashboard.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../providers/payment_provider.dart';
import '../../../widgets/common/async_value_builder.dart';
import '../../../utils/currency_utils.dart';

class RevenueDashboard extends StatelessWidget {
  const RevenueDashboard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AsyncValueBuilder<Map<String, double>>(
      future: context.read<PaymentProvider>().getMonthlyRevenue(),
      builder: (data) => Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              _buildChart(context, data),
              _buildStatistics(context, data),
            ],
          ),
        ),
      ),
      loadingWidget: _buildLoadingState(),
      errorBuilder: (error) => _buildErrorState(error),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Revenue Overview',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        SizedBox(height: 8),
        Text(
          'Monthly revenue analysis',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
        ),
        SizedBox(height: 24),
      ],
    );
  }

  Widget _buildChart(BuildContext context, Map<String, double> data) {
    return SizedBox(
      height: 300,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 1000,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.grey[300],
                strokeWidth: 1,
              );
            },
          ),
          titlesData: _buildChartTitles(data),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: _createSpots(data),
              isCurved: true,
              color: Theme.of(context).primaryColor,
              barWidth: 4,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 6,
                    color: Colors.white,
                    strokeWidth: 3,
                    strokeColor: Theme.of(context).primaryColor,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                color: Theme.of(context).primaryColor.withOpacity(0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  FlTitlesData _buildChartTitles(Map<String, double> data) {
    return FlTitlesData(
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          interval: 5000,
          reservedSize: 40,
          getTitlesWidget: (value, meta) {
            return Text(
              CurrencyUtils.formatCompact(value),
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            );
          },
        ),
      ),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          getTitlesWidget: (value, meta) {
            if (value.toInt() >= data.keys.length) return SizedBox();
            return Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                data.keys.elementAt(value.toInt()),
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            );
          },
          interval: 1,
        ),
      ),
      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
    );
  }

  List<FlSpot> _createSpots(Map<String, double> data) {
    return data.entries.map((entry) {
      return FlSpot(
        data.keys.toList().indexOf(entry.key).toDouble(),
        entry.value,
      );
    }).toList();
  }

  Widget _buildStatistics(BuildContext context, Map<String, double> data) {
    final total = data.values.reduce((a, b) => a + b);
    final average = total / data.length;

    return Padding(
      padding: EdgeInsets.only(top: 24),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              context,
              'Total Revenue',
              CurrencyUtils.formatCurrency(total),
              Icons.attach_money,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: _buildStatCard(
              context,
              'Monthly Average',
              CurrencyUtils.formatCurrency(average),
              Icons.trending_up,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
  ) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: Theme.of(context).primaryColor),
              SizedBox(width: 8),
              Text(title, style: TextStyle(color: Colors.grey[600])),
            ],
          ),
          SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Card(
      child: Container(
        height: 400,
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Card(
      child: Container(
        height: 400,
        padding: EdgeInsets.all(16),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red),
              SizedBox(height: 16),
              Text(
                'Error loading revenue data',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(error, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
