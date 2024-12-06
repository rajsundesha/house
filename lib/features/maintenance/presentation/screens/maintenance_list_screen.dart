import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/maintenance_request.dart';
import '../providers/maintenance_provider.dart';

class MaintenanceListScreen extends ConsumerWidget {
  const MaintenanceListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final maintenanceRequestsAsync = ref.watch(maintenanceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Maintenance Requests'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              // TODO: Implement filtering
            },
          ),
        ],
      ),
      body: maintenanceRequestsAsync.when(
        data: (requests) => _MaintenanceList(requests: requests),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error: $error'),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to create request screen
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _MaintenanceList extends StatelessWidget {
  final List<MaintenanceRequest> requests;

  const _MaintenanceList({required this.requests});

  @override
  Widget build(BuildContext context) {
    if (requests.isEmpty) {
      return const Center(
        child: Text('No maintenance requests found'),
      );
    }

    return ListView.builder(
      itemCount: requests.length,
      itemBuilder: (context, index) {
        final request = requests[index];
        return _MaintenanceRequestCard(request: request);
      },
    );
  }
}

class _MaintenanceRequestCard extends StatelessWidget {
  final MaintenanceRequest request;

  const _MaintenanceRequestCard({required this.request});

  Color _getStatusColor() {
    switch (request.status) {
      case MaintenanceStatus.pending:
        return Colors.orange;
      case MaintenanceStatus.inProgress:
        return Colors.blue;
      case MaintenanceStatus.completed:
        return Colors.green;
      case MaintenanceStatus.cancelled:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        title: Text(request.title),
        subtitle: Text(
          request.description,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        leading: CircleAvatar(
          backgroundColor: _getStatusColor(),
          child: Icon(
            request.status == MaintenanceStatus.completed
                ? Icons.check
                : Icons.build,
            color: Colors.white,
          ),
        ),
        trailing: Text(
          request.priority.name.toUpperCase(),
          style: TextStyle(
            color: request.priority == MaintenancePriority.urgent
                ? Colors.red
                : null,
            fontWeight: request.priority == MaintenancePriority.urgent
                ? FontWeight.bold
                : null,
          ),
        ),
        onTap: () {
          // Navigate to detail screen
        },
      ),
    );
  }
}