enum DocumentType {
  lease,
  idProof,
  agreement,
  payment,
  maintenance,
  other
}

class Document {
  final String id;
  final String name;
  final String url;
  final DocumentType type;
  final String? description;
  final DateTime uploadedAt;
  final String uploadedBy;
  final String relatedId; // Could be propertyId, tenantId, leaseId etc.
  final Map<String, dynamic>? metadata;

  Document({
    required this.id,
    required this.name,
    required this.url,
    required this.type,
    this.description,
    required this.uploadedAt,
    required this.uploadedBy,
    required this.relatedId,
    this.metadata,
  });

  factory Document.fromMap(Map<String, dynamic> map, String id) {
    return Document(
      id: id,
      name: map['name'],
      url: map['url'],
      type: DocumentType.values.byName(map['type']),
      description: map['description'],
      uploadedAt: DateTime.parse(map['uploadedAt']),
      uploadedBy: map['uploadedBy'],
      relatedId: map['relatedId'],
      metadata: map['metadata'],
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'url': url,
    'type': type.name,
    'description': description,
    'uploadedAt': uploadedAt.toIso8601String(),
    'uploadedBy': uploadedBy,
    'relatedId': relatedId,
    'metadata': metadata,
  };
}