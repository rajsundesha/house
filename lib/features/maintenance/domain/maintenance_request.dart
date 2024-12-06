class MaintenanceRequest {
  final String id;
  final String propertyId;
  final String tenantId;
  final String title;
  final String description;
  final DateTime createdAt;
  final MaintenancePriority priority;
  final MaintenanceStatus status;
  final String? assignedTo;
  final DateTime? completedAt;
  final List<String> images;

  MaintenanceRequest({
    required this.id,
    required this.propertyId,
    required this.tenantId,
    required this.title,
    required this.description,
    required this.createdAt,
    this.priority = MaintenancePriority.medium,
    this.status = MaintenanceStatus.pending,
    this.assignedTo,
    this.completedAt,
    this.images = const [],
  });

  factory MaintenanceRequest.fromMap(Map<String, dynamic> map, String id) {
    return MaintenanceRequest(
      id: id,
      propertyId: map['propertyId'],
      tenantId: map['tenantId'],
      title: map['title'],
      description: map['description'],
      createdAt: DateTime.parse(map['createdAt']),
      priority: MaintenancePriority.values.byName(map['priority'] ?? 'medium'),
      status: MaintenanceStatus.values.byName(map['status'] ?? 'pending'),
      assignedTo: map['assignedTo'],
      completedAt: map['completedAt'] != null ? DateTime.parse(map['completedAt']) : null,
      images: List<String>.from(map['images'] ?? []),
    );
  }

  Map<String, dynamic> toMap() => {
    'propertyId': propertyId,
    'tenantId': tenantId,
    'title': title,
    'description': description,
    'createdAt': createdAt.toIso8601String(),
    'priority': priority.name,
    'status': status.name,
    'assignedTo': assignedTo,
    'completedAt': completedAt?.toIso8601String(),
    'images': images,
  };
}

enum MaintenancePriority { low, medium, high, urgent }

enum MaintenanceStatus { pending, inProgress, completed, cancelled }