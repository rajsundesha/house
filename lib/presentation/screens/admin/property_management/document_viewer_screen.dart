import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:house_rental_app/presentation/shared/widgets/dialog_components.dart';
import 'package:house_rental_app/presentation/shared/widgets/loading_overlay.dart';
import 'package:provider/provider.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:house_rental_app/data/models/property.dart';
import 'package:house_rental_app/presentation/providers/property_provider.dart';
// import 'package:house_rental_app/presentation/shared/widgets/custom_components.dart';
import 'package:intl/intl.dart';

class PropertyDocument {
  final String id;
  final String name;
  final String url;
  final String type;
  final DateTime uploadedAt;
  final String? description;

  PropertyDocument({
    required this.id,
    required this.name,
    required this.url,
    required this.type,
    required this.uploadedAt,
    this.description,
  });

  factory PropertyDocument.fromMap(Map<String, dynamic> map) {
    return PropertyDocument(
      id: map['id'],
      name: map['name'],
      url: map['url'],
      type: map['type'],
      uploadedAt: (map['uploadedAt'] as Timestamp).toDate(),
      description: map['description'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'url': url,
      'type': type,
      'uploadedAt': Timestamp.fromDate(uploadedAt),
      'description': description,
    };
  }
}

class DocumentViewerScreen extends StatefulWidget {
  final Property property;

  DocumentViewerScreen({required this.property});

  @override
  _DocumentViewerScreenState createState() => _DocumentViewerScreenState();
}

class _DocumentViewerScreenState extends State<DocumentViewerScreen> {
  bool _isLoading = false;
  List<PropertyDocument> _documents = [];
  final storage = FirebaseStorage.instance;

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    setState(() => _isLoading = true);
    try {
      final docRef = FirebaseFirestore.instance
          .collection('properties')
          .doc(widget.property.id)
          .collection('documents');

      final snapshot =
          await docRef.orderBy('uploadedAt', descending: true).get();

      _documents = snapshot.docs
          .map((doc) => PropertyDocument.fromMap(doc.data()))
          .toList();
    } catch (e) {
      showErrorDialog(context, 'Error loading documents: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _uploadDocument() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'txt'],
    );

    if (result != null) {
      setState(() => _isLoading = true);
      try {
        final file = File(result.files.single.path!);
        final fileName = result.files.single.name;
        final extension = path.extension(fileName).toLowerCase();

        // Upload to Firebase Storage
        final ref = storage
            .ref()
            .child('properties/${widget.property.id}/documents/$fileName');
        await ref.putFile(file);
        final downloadUrl = await ref.getDownloadURL();

        // Add document metadata to Firestore
        final document = PropertyDocument(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: fileName,
          url: downloadUrl,
          type: extension,
          uploadedAt: DateTime.now(),
        );

        await FirebaseFirestore.instance
            .collection('properties')
            .doc(widget.property.id)
            .collection('documents')
            .add(document.toMap());

        await _loadDocuments();
      } catch (e) {
        showErrorDialog(context, 'Error uploading document: $e');
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _downloadAndOpenDocument(PropertyDocument document) async {
    setState(() => _isLoading = true);
    try {
      final tempDir = await getTemporaryDirectory();
      final localFile = File('${tempDir.path}/${document.name}');

      if (!await localFile.exists()) {
        // Download file
        final response = await http.get(Uri.parse(document.url));
        await localFile.writeAsBytes(response.bodyBytes);
      }

      // Open file
      await OpenFile.open(localFile.path);
    } catch (e) {
      showErrorDialog(context, 'Error opening document: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteDocument(PropertyDocument document) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Document'),
        content: Text('Are you sure you want to delete ${document.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('DELETE', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      try {
        // Delete from Storage
        final ref = storage.refFromURL(document.url);
        await ref.delete();

        // Delete from Firestore
        await FirebaseFirestore.instance
            .collection('properties')
            .doc(widget.property.id)
            .collection('documents')
            .where('id', isEqualTo: document.id)
            .get()
            .then((snapshot) {
          for (var doc in snapshot.docs) {
            doc.reference.delete();
          }
        });

        await _loadDocuments();
      } catch (e) {
        showErrorDialog(context, 'Error deleting document: $e');
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildDocumentIcon(String type) {
    IconData iconData;
    Color color;

    switch (type.toLowerCase()) {
      case '.pdf':
        iconData = Icons.picture_as_pdf;
        color = Colors.red;
        break;
      case '.doc':
      case '.docx':
        iconData = Icons.description;
        color = Colors.blue;
        break;
      case '.xls':
      case '.xlsx':
        iconData = Icons.table_chart;
        color = Colors.green;
        break;
      default:
        iconData = Icons.insert_drive_file;
        color = Colors.grey;
    }

    return Icon(iconData, color: color, size: 36);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Property Documents'),
        actions: [
          IconButton(
            icon: Icon(Icons.upload_file),
            onPressed: _uploadDocument,
          ),
        ],
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: _documents.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.folder_open, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('No documents available'),
                    SizedBox(height: 16),
                    ElevatedButton.icon(
                      icon: Icon(Icons.upload_file),
                      label: Text('Upload Document'),
                      onPressed: _uploadDocument,
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: EdgeInsets.all(16),
                itemCount: _documents.length,
                itemBuilder: (context, index) {
                  final document = _documents[index];
                  return Card(
                    child: ListTile(
                      leading: _buildDocumentIcon(document.type),
                      title: Text(document.name),
                      subtitle: Text(
                        'Uploaded on: ${DateFormat('MMM d, y').format(document.uploadedAt)}',
                      ),
                      trailing: PopupMenuButton(
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            child: ListTile(
                              leading: Icon(Icons.download),
                              title: Text('Download'),
                            ),
                            value: 'download',
                          ),
                          PopupMenuItem(
                            child: ListTile(
                              leading: Icon(Icons.delete, color: Colors.red),
                              title: Text('Delete',
                                  style: TextStyle(color: Colors.red)),
                            ),
                            value: 'delete',
                          ),
                        ],
                        onSelected: (value) {
                          switch (value) {
                            case 'download':
                              _downloadAndOpenDocument(document);
                              break;
                            case 'delete':
                              _deleteDocument(document);
                              break;
                          }
                        },
                      ),
                      onTap: () => _downloadAndOpenDocument(document),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
