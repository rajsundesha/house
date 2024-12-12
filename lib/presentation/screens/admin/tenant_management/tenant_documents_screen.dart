import 'package:flutter/material.dart';
import 'package:house_rental_app/presentation/shared/widgets/dialog_components.dart';
import 'package:house_rental_app/presentation/shared/widgets/loading_overlay.dart';
import 'package:provider/provider.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:house_rental_app/data/models/tenant.dart';

import 'package:intl/intl.dart';

class TenantDocumentsScreen extends StatefulWidget {
  final Tenant tenant;

  TenantDocumentsScreen({required this.tenant});

  @override
  _TenantDocumentsScreenState createState() => _TenantDocumentsScreenState();
}

class _TenantDocumentsScreenState extends State<TenantDocumentsScreen> {
  bool _isLoading = false;
  List<TenantDocument> _documents = [];
  String _selectedCategory = 'lease'; // Default category
  final storage = FirebaseStorage.instance;

  final Map<String, String> documentCategories = {
    'lease': 'Lease Documents',
    'id_proof': 'ID Proofs',
    'income': 'Income Documents',
    'background': 'Background Verification',
    'other': 'Other Documents',
  };

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    setState(() => _isLoading = true);
    try {
      setState(() {
        _documents = widget.tenant.documents;
      });
    } catch (e) {
      showErrorDialog(context, 'Error loading documents: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _uploadDocument() async {
    final type = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Select Document Type'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: documentCategories.entries.map((entry) {
            return ListTile(
              title: Text(entry.value),
              onTap: () => Navigator.pop(context, entry.key),
            );
          }).toList(),
        ),
      ),
    );

    if (type == null) return;

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
    );

    if (result != null) {
      setState(() => _isLoading = true);
      try {
        final file = File(result.files.single.path!);
        final fileName = result.files.single.name;
        final extension = path.extension(fileName).toLowerCase();

        // Upload to Firebase Storage
        final ref = storage.ref().child(
            'tenants/${widget.tenant.id}/documents/${DateTime.now().millisecondsSinceEpoch}_$fileName');
        await ref.putFile(file);
        final downloadUrl = await ref.getDownloadURL();

        // Create new document
        final document = TenantDocument(
          type: type,
          documentId: DateTime.now().millisecondsSinceEpoch.toString(),
          documentUrl: downloadUrl,
          uploadedAt: DateTime.now(),
        );

        // Update tenant's documents list
        final updatedDocuments = [...widget.tenant.documents, document];

        // Update Firestore
        await FirebaseFirestore.instance
            .collection('tenants')
            .doc(widget.tenant.id)
            .update({
          'documents': updatedDocuments.map((d) => d.toMap()).toList(),
        });

        setState(() {
          _documents = updatedDocuments;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Document uploaded successfully')),
        );
      } catch (e) {
        showErrorDialog(context, 'Error uploading document: $e');
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _downloadAndOpenDocument(TenantDocument document) async {
    setState(() => _isLoading = true);
    try {
      final tempDir = await getTemporaryDirectory();
      final localFile =
          File('${tempDir.path}/${path.basename(document.documentUrl)}');

      if (!await localFile.exists()) {
        // Download file
        final response = await http.get(Uri.parse(document.documentUrl));
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

  Future<void> _deleteDocument(TenantDocument document) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Document'),
        content: Text('Are you sure you want to delete this document?'),
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
        final ref = storage.refFromURL(document.documentUrl);
        await ref.delete();

        // Update tenant's documents list
        final updatedDocuments = _documents
            .where((d) => d.documentId != document.documentId)
            .toList();

        // Update Firestore
        await FirebaseFirestore.instance
            .collection('tenants')
            .doc(widget.tenant.id)
            .update({
          'documents': updatedDocuments.map((d) => d.toMap()).toList(),
        });

        setState(() {
          _documents = updatedDocuments;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Document deleted successfully')),
        );
      } catch (e) {
        showErrorDialog(context, 'Error deleting document: $e');
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildDocumentIcon(TenantDocument document) {
    final extension = path.extension(document.documentUrl).toLowerCase();
    IconData iconData;
    Color color;

    switch (extension) {
      case '.pdf':
        iconData = Icons.picture_as_pdf;
        color = Colors.red;
        break;
      case '.doc':
      case '.docx':
        iconData = Icons.description;
        color = Colors.blue;
        break;
      case '.jpg':
      case '.jpeg':
      case '.png':
        iconData = Icons.image;
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
    final filteredDocuments =
        _documents.where((doc) => _selectedCategory == doc.type).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Tenant Documents'),
        actions: [
          IconButton(
            icon: Icon(Icons.upload_file),
            onPressed: _uploadDocument,
          ),
        ],
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: Column(
          children: [
            // Category Selection
            Container(
              height: 60,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                children: documentCategories.entries.map((entry) {
                  return Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(entry.value),
                      selected: _selectedCategory == entry.key,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _selectedCategory = entry.key);
                        }
                      },
                    ),
                  );
                }).toList(),
              ),
            ),

            Expanded(
              child: filteredDocuments.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.folder_open, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                              'No ${documentCategories[_selectedCategory]} available'),
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
                      itemCount: filteredDocuments.length,
                      itemBuilder: (context, index) {
                        final document = filteredDocuments[index];
                        return Card(
                          child: ListTile(
                            leading: _buildDocumentIcon(document),
                            title: Text(path.basename(document.documentUrl)),
                            subtitle: Text(
                              'Uploaded: ${DateFormat('MMM d, y').format(document.uploadedAt)}',
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
                                    leading:
                                        Icon(Icons.delete, color: Colors.red),
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
          ],
        ),
      ),
    );
  }
}
