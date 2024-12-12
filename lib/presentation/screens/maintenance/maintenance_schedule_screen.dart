
import 'package:flutter/material.dart';
import 'package:house_rental_app/presentation/shared/widgets/dialog_components.dart';
import 'package:house_rental_app/presentation/shared/widgets/loading_overlay.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:house_rental_app/presentation/providers/property_provider.dart';
// import 'package:house_rental_app/presentation/shared/widgets/custom_components.dart';
import 'package:intl/intl.dart';

class MaintenanceTask {
  final String id;
  final String propertyId;
  final String title;
  final String description;
  final DateTime scheduledDate;
  final String priority; // high, medium, low
  final String status; // pending, in_progress, completed
  final double estimatedCost;
  final String? assignedTo;
  final List<String> images;
  final DateTime createdAt;
  final DateTime? completedAt;

  MaintenanceTask({
    required this.id,
    required this.propertyId,
    required this.title,
    required this.description,
    required this.scheduledDate,
    required this.priority,
    required this.status,
    required this.estimatedCost,
    this.assignedTo,
    List<String>? images,
    required this.createdAt,
    this.completedAt,
  }) : this.images = images ?? [];

  factory MaintenanceTask.fromMap(Map<String, dynamic> map, String id) {
    return MaintenanceTask(
      id: id,
      propertyId: map['propertyId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      scheduledDate: (map['scheduledDate'] as Timestamp).toDate(),
      priority: map['priority'] ?? 'medium',
      status: map['status'] ?? 'pending',
      estimatedCost: (map['estimatedCost'] ?? 0).toDouble(),
      assignedTo: map['assignedTo'],
      images: List<String>.from(map['images'] ?? []),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      completedAt: map['completedAt'] != null
          ? (map['completedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'propertyId': propertyId,
      'title': title,
      'description': description,
      'scheduledDate': Timestamp.fromDate(scheduledDate),
      'priority': priority,
      'status': status,
      'estimatedCost': estimatedCost,
      'assignedTo': assignedTo,
      'images': images,
      'createdAt': Timestamp.fromDate(createdAt),
      'completedAt':
          completedAt != null ? Timestamp.fromDate(completedAt!) : null,
    };
  }

  MaintenanceTask copyWith({
    String? propertyId,
    String? title,
    String? description,
    DateTime? scheduledDate,
    String? priority,
    String? status,
    double? estimatedCost,
    String? assignedTo,
    List<String>? images,
    DateTime? completedAt,
  }) {
    return MaintenanceTask(
      id: this.id,
      propertyId: propertyId ?? this.propertyId,
      title: title ?? this.title,
      description: description ?? this.description,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      estimatedCost: estimatedCost ?? this.estimatedCost,
      assignedTo: assignedTo ?? this.assignedTo,
      images: images ?? this.images,
      createdAt: this.createdAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}

class MaintenanceScheduleScreen extends StatefulWidget {
  @override
  _MaintenanceScheduleScreenState createState() =>
      _MaintenanceScheduleScreenState();
}

class _MaintenanceScheduleScreenState extends State<MaintenanceScheduleScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  late TabController _tabController;
  List<MaintenanceTask> _tasks = [];
  String _selectedPropertyId = '';
  String _selectedFilter = 'all'; // all, pending, in_progress, completed
  final _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    setState(() => _isLoading = true);
    try {
      final querySnapshot = await _firestore
          .collection('maintenance_tasks')
          .orderBy('scheduledDate')
          .get();

      setState(() {
        _tasks = querySnapshot.docs
            .map((doc) => MaintenanceTask.fromMap(doc.data(), doc.id))
            .toList();
      });
    } catch (e) {
      showErrorDialog(context, 'Error loading maintenance tasks: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateTaskStatus(MaintenanceTask task, String newStatus) async {
    try {
      final updatedTask = task.copyWith(
        status: newStatus,
        completedAt: newStatus == 'completed' ? DateTime.now() : null,
      );

      await _firestore
          .collection('maintenance_tasks')
          .doc(task.id)
          .update(updatedTask.toMap());

      await _loadTasks();
    } catch (e) {
      showErrorDialog(context, 'Error updating task status: $e');
    }
  }

  List<MaintenanceTask> _getFilteredTasks(String status) {
    if (_selectedPropertyId.isNotEmpty) {
      return _tasks
          .where((task) =>
              task.status == status &&
              task.propertyId == _selectedPropertyId)
          .toList();
    }
    return _tasks.where((task) => task.status == status).toList();
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Widget _buildTaskList(String status) {
    final tasks = _getFilteredTasks(status);
    if (tasks.isEmpty) {
      return Center(
        child: Text('No ${status.replaceAll('_', ' ')} tasks'),
      );
    }

    return ListView.builder(
      itemCount: tasks.length,
      padding: EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final task = tasks[index];
        return Card(
          margin: EdgeInsets.only(bottom: 8),
          child: ExpansionTile(
            leading: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _getPriorityColor(task.priority),
              ),
            ),
            title: Text(task.title),
            subtitle: Text(
              DateFormat('MMM d, y').format(task.scheduledDate),
            ),
            children: [
              Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Description:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(task.description),
                    SizedBox(height: 8),
                    Text(
                      'Estimated Cost:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text('\$${task.estimatedCost.toStringAsFixed(2)}'),
                    if (task.assignedTo != null) ...[
                      SizedBox(height: 8),
                      Text(
                        'Assigned To:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(task.assignedTo!),
                    ],
                    if (task.images.isNotEmpty) ...[
                      SizedBox(height: 8),
                      Text(
                        'Images:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Container(
                        height: 100,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: task.images.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: EdgeInsets.only(right: 8),
                              child: Image.network(
                                task.images[index],
                                height: 100,
                                width: 100,
                                fit: BoxFit.cover,
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                    SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        if (task.status != 'completed')
                          ElevatedButton(
                            onPressed: () {
                              _updateTaskStatus(
                                task,
                                task.status == 'pending'
                                    ? 'in_progress'
                                    : 'completed',
                              );
                            },
                            child: Text(
                              task.status == 'pending'
                                  ? 'Start'
                                  : 'Mark Complete',
                            ),
                          ),
                        OutlinedButton(
                          onPressed: () {
                            // Navigate to edit task screen
                            Navigator.pushNamed(
                              context,
                              '/edit_maintenance_task',
                              arguments: task,
                            ).then((_) => _loadTasks());
                          },
                          child: Text('Edit'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Maintenance Schedule'),
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list),
            onPressed: () {
              // Show property filter
              showModalBottomSheet(
                context: context,
                builder: (context) => PropertyFilterSheet(
                  selectedPropertyId: _selectedPropertyId,
                  onPropertySelected: (propertyId) {
                    setState(() => _selectedPropertyId = propertyId);
                    Navigator.pop(context);
                  },
                ),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Pending'),
            Tab(text: 'In Progress'),
            Tab(text: 'Completed'),
          ],
        ),
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildTaskList('pending'),
            _buildTaskList('in_progress'),
            _buildTaskList('completed'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/add_maintenance_task')
              .then((_) => _loadTasks());
        },
        child: Icon(Icons.add),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

class PropertyFilterSheet extends StatelessWidget {
  final String selectedPropertyId;
  final Function(String) onPropertySelected;

  PropertyFilterSheet({
    required this.selectedPropertyId,
    required this.onPropertySelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Select Property',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          SizedBox(height: 16),
          Consumer<PropertyProvider>(
            builder: (context, provider, child) {
              return Column(
                children: [
                  ListTile(
                    title: Text('All Properties'),
                    selected: selectedPropertyId.isEmpty,
                    onTap: () => onPropertySelected(''),
                  ),
                  ...provider.properties.map(
                    (property) => ListTile(
                      title: Text(property.address),
                      selected: property.id == selectedPropertyId,
                      onTap: () => onPropertySelected(property.id),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
