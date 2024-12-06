// class Document {
//   final String id;
//   final String type;
//   final String url;
//   final String name;
//   final DateTime uploadedAt;
//   final String? ownerId;
//   final Map<String, dynamic>? metadata;

//   Document({
//     required this.id,
//     required this.type,
//     required this.url,
//     required this.name,
//     required this.uploadedAt,
//     this.ownerId,
//     this.metadata,
//   });

//   Map<String, dynamic> toMap() {
//     return {
//       'id': id,
//       'type': type,
//       'url': url,
//       'name': name,
//       'uploadedAt': uploadedAt,
//       'ownerId': ownerId,
//       'metadata': metadata,
//     };
//   }

//   factory Document.fromMap(Map<String, dynamic> map) {
//     return Document(
//       id: map['id'],
//       type: map['type'],
//       url: map['url'],
//       name: map['name'],
//       uploadedAt: map['uploadedAt'].toDate(),
//       ownerId: map['ownerId'],
//       metadata: map['metadata'],
//     );
//   }
// }
