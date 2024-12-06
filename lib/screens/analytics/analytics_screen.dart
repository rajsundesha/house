class AnalyticsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Analytics'),
          bottom: TabBar(
            tabs: [
              Tab(text: 'Financial'),
              Tab(text: 'Occupancy'),
              Tab(text: 'Performance'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            FinancialAnalytics(),
            OccupancyAnalytics(),
            PerformanceAnalytics(),
          ],
        ),
      ),
    );
  }
}
