class MaintenanceScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Maintenance')),
      body: ListView(
        children: [
          MaintenanceRequestList(),
          MaintenanceHistoryList(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _createMaintenanceRequest(context),
        child: Icon(Icons.add),
      ),
    );
  }

  Future<void> _createMaintenanceRequest(BuildContext context) async {
    final result = await showDialog<MaintenanceRequest>(
      context: context,
      builder: (context) => MaintenanceRequestDialog(),
    );
    if (result != null) {
      // Handle new maintenance request
    }
  }
}
