class DocumentUpload extends StatefulWidget {
  final String documentType;
  final Function(File) onFileSelected;
  final String? currentUrl;

  @override
  _DocumentUploadState createState() => _DocumentUploadState();
}

class _DocumentUploadState extends State<DocumentUpload> {
  File? _selectedFile;
  bool _isUploading = false;

  @override
  Widget build(BuildContext context) {
    if (_selectedFile != null) {
      return _buildPreview();
    }

    if (widget.currentUrl != null) {
      return _buildExistingDocument();
    }

    return _buildUploadButton();
  }

  Widget _buildUploadButton() {
    return OutlinedButton.icon(
      onPressed: _pickFile,
      icon: Icon(Icons.upload_file),
      label: Text('Upload ${widget.documentType}'),
    );
  }

  Widget _buildPreview() {
    return Card(
      child: ListTile(
        leading: Icon(Icons.file_present),
        title: Text(_selectedFile!.path.split('/').last),
        subtitle: FutureBuilder<String>(
          future: FileUtils.getFileSize(_selectedFile!),
          builder: (context, snapshot) {
            return Text(snapshot.data ?? 'Calculating size...');
          },
        ),
        trailing: IconButton(
          icon: Icon(Icons.close),
          onPressed: () => setState(() => _selectedFile = null),
        ),
      ),
    );
  }

  Widget _buildExistingDocument() {
    return Card(
      child: ListTile(
        leading: Icon(Icons.file_present),
        title: Text(widget.documentType),
        subtitle: Text('Tap to preview'),
        trailing: IconButton(
          icon: Icon(Icons.replay),
          onPressed: _pickFile,
        ),
        onTap: () {
          // Open document preview
        },
      ),
    );
  }

  Future<void> _pickFile() async {
    try {
      final file = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );

      if (file != null) {
        setState(() => _selectedFile = File(file.files.single.path!));
        widget.onFileSelected(_selectedFile!);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking file: $e')),
      );
    }
  }
}
