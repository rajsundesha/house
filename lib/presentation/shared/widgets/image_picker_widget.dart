import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class ImagePickerWidget extends StatefulWidget {
  final List<String> initialImages;
  final Function(List<File>) onImagesSelected;
  final Function(String)? onImageRemoved;
  final int maxImages;
  final String label;
  final bool showPreview;
  final double? previewHeight;
  final double? previewWidth;

  const ImagePickerWidget({
    Key? key,
    this.initialImages = const [],
    required this.onImagesSelected,
    this.onImageRemoved,
    this.maxImages = 5,
    this.label = 'Select Images',
    this.showPreview = true,
    this.previewHeight,
    this.previewWidth,
  }) : super(key: key);

  @override
  _ImagePickerWidgetState createState() => _ImagePickerWidgetState();
}

class _ImagePickerWidgetState extends State<ImagePickerWidget> {
  final List<File> _selectedFiles = [];
  final _imagePicker = ImagePicker();

  Future<void> _pickImages() async {
    try {
      final pickedFiles = await _imagePicker.pickMultiImage();
      if (pickedFiles != null) {
        final remainingSlots = widget.maxImages - _selectedFiles.length;
        final newFiles = pickedFiles
            .take(remainingSlots)
            .map((file) => File(file.path))
            .toList();
            
        setState(() {
          _selectedFiles.addAll(newFiles);
        });
        widget.onImagesSelected(_selectedFiles);
      }
    } catch (e) {
      print('Error picking images: $e');
    }
  }

  Future<void> _pickFromCamera() async {
    try {
      final pickedFile = await _imagePicker.pickImage(source: ImageSource.camera);
      if (pickedFile != null) {
        final file = File(pickedFile.path);
        setState(() {
          _selectedFiles.add(file);
        });
        widget.onImagesSelected(_selectedFiles);
      }
    } catch (e) {
      print('Error taking photo: $e');
    }
  }

  void _showImagePickerModal() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.photo_library),
              title: Text('Pick from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImages();
              },
            ),
            ListTile(
              leading: Icon(Icons.camera_alt),
              title: Text('Take a Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickFromCamera();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showPreview && 
            (widget.initialImages.isNotEmpty || _selectedFiles.isNotEmpty))
          Container(
            height: widget.previewHeight ?? 120,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                ..._selectedFiles.map((file) => Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: Stack(
                        children: [
                          Image.file(
                            file,
                            height: widget.previewHeight ?? 120,
                            width: widget.previewWidth ?? 120,
                            fit: BoxFit.cover,
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedFiles.remove(file);
                                });
                                widget.onImagesSelected(_selectedFiles);
                              },
                              child: Container(
                                padding: EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.close,
                   color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
                ...widget.initialImages.map((url) => Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: Stack(
                        children: [
                          Image.network(
                            url,
                            height: widget.previewHeight ?? 120,
                            width: widget.previewWidth ?? 120,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                height: widget.previewHeight ?? 120,
                                width: widget.previewWidth ?? 120,
                                color: Colors.grey[200],
                                child: Center(
                                  child: CircularProgressIndicator(
                                    value: loadingProgress.expectedTotalBytes !=
                                            null
                                        ? loadingProgress
                                                .cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                                  ),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                              height: widget.previewHeight ?? 120,
                              width: widget.previewWidth ?? 120,
                              color: Colors.grey[200],
                              child: Icon(Icons.error),
                            ),
                          ),
                          if (widget.onImageRemoved != null)
                            Positioned(
                              top: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: () => widget.onImageRemoved!(url),
                                child: Container(
                                  padding: EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    )),
                if (_selectedFiles.length + widget.initialImages.length <
                    widget.maxImages)
                  InkWell(
                    onTap: _showImagePickerModal,
                    child: Container(
                      width: widget.previewWidth ?? 120,
                      height: widget.previewHeight ?? 120,
                      decoration: BoxDecoration(
                        border:
                            Border.all(color: Theme.of(context).dividerColor),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_photo_alternate,
                            size: 32,
                            color: Theme.of(context).primaryColor,
                          ),
                          SizedBox(height: 8),
                          Text(
                            widget.label,
                            style: TextStyle(
                              color: Theme.of(context).primaryColor,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          )
        else
          InkWell(
            onTap: _showImagePickerModal,
            child: Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Theme.of(context).dividerColor),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_photo_alternate,
                    size: 24,
                    color: Theme.of(context).primaryColor,
                  ),
                  SizedBox(width: 8),
                  Text(
                    widget.label,
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (widget.maxImages > 1)
          Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              '${_selectedFiles.length + widget.initialImages.length}/${widget.maxImages} images selected',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
      ],
    );
  }
}

class ImagePreviewScreen extends StatelessWidget {
  final List<String> images;
  final int initialIndex;

  const ImagePreviewScreen({
    Key? key,
    required this.images,
    this.initialIndex = 0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: PageView.builder(
        controller: PageController(initialPage: initialIndex),
        itemCount: images.length,
        itemBuilder: (context, index) {
          return InteractiveViewer(
            minScale: 0.5,
            maxScale: 4.0,
            child: Image.network(
              images[index],
              fit: BoxFit.contain,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) => Center(
                child: Icon(Icons.error, color: Colors.white),
              ),
            ),
          );
        },
      ),
    );
  }
}
