import 'package:flutter/material.dart';
import 'package:house_rental_app/presentation/shared/widgets/dialog_components.dart';
import 'package:house_rental_app/presentation/shared/widgets/loading_overlay.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:house_rental_app/data/models/property.dart';
import 'package:house_rental_app/presentation/providers/property_provider.dart';
// import 'package:house_rental_app/presentation/shared/widgets/custom_components.dart';
import 'dart:io';

class PropertyImagesGalleryScreen extends StatefulWidget {
  final Property property;

  PropertyImagesGalleryScreen({required this.property});

  @override
  _PropertyImagesGalleryScreenState createState() =>
      _PropertyImagesGalleryScreenState();
}

class _PropertyImagesGalleryScreenState
    extends State<PropertyImagesGalleryScreen> {
  bool _isLoading = false;
  List<String> _images = [];
  PageController _pageController = PageController();
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _images = List.from(widget.property.images);
  }

  void _showFullScreenImage(int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          body: SafeArea(
            child: PhotoViewGallery.builder(
              pageController: PageController(initialPage: index),
              itemCount: _images.length,
              builder: (context, index) {
                return PhotoViewGalleryPageOptions(
                  imageProvider: NetworkImage(_images[index]),
                  minScale: PhotoViewComputedScale.contained,
                  maxScale: PhotoViewComputedScale.covered * 2,
                );
              },
              scrollPhysics: BouncingScrollPhysics(),
              backgroundDecoration: BoxDecoration(color: Colors.black),
              loadingBuilder: (context, event) => Center(
                child: CircularProgressIndicator(),
              ),
            ),
          ),
          floatingActionButton: FloatingActionButton(
            child: Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
    );
  }

  Future<void> _addImages() async {
    setState(() => _isLoading = true);
    try {
      final List<File> selectedImages = await _pickImages();
      if (selectedImages.isNotEmpty) {
        await Provider.of<PropertyProvider>(context, listen: false)
            .addPropertyImages(widget.property.id, selectedImages);

        // Refresh property data to get updated image list
        final updatedProperty =
            await Provider.of<PropertyProvider>(context, listen: false)
                .getPropertyById(widget.property.id);
        if (updatedProperty != null) {
          setState(() {
            _images = List.from(updatedProperty.images);
          });
        }
      }
    } catch (e) {
      showErrorDialog(context, 'Error adding images: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<List<File>> _pickImages() async {
    try {
      final imagePicker = ImagePicker();
      final pickedFiles = await imagePicker.pickMultiImage();
      return pickedFiles.map((file) => File(file.path)).toList();
    } catch (e) {
      print('Error picking images: $e');
      return [];
    }
  }

  Future<void> _deleteImage(String imageUrl) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Image'),
        content: Text('Are you sure you want to delete this image?'),
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
        await Provider.of<PropertyProvider>(context, listen: false)
            .removePropertyImage(widget.property.id, imageUrl);
        setState(() {
          _images.remove(imageUrl);
          if (_currentIndex >= _images.length) {
            _currentIndex = _images.length - 1;
          }
        });
      } catch (e) {
        showErrorDialog(context, 'Error deleting image: $e');
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Property Images'),
        actions: [
          IconButton(
            icon: Icon(Icons.add_photo_alternate),
            onPressed: _addImages,
          ),
        ],
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: Column(
          children: [
            if (_images.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.photo_library_outlined,
                          size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No images available'),
                      SizedBox(height: 16),
                      ElevatedButton.icon(
                        icon: Icon(Icons.add_photo_alternate),
                        label: Text('Add Images'),
                        onPressed: _addImages,
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    PhotoViewGallery.builder(
                      pageController: _pageController,
                      itemCount: _images.length,
                      builder: (context, index) {
                        return PhotoViewGalleryPageOptions(
                          imageProvider: NetworkImage(_images[index]),
                          minScale: PhotoViewComputedScale.contained,
                          maxScale: PhotoViewComputedScale.covered * 2,
                        );
                      },
                      onPageChanged: (index) {
                        setState(() => _currentIndex = index);
                      },
                      scrollPhysics: BouncingScrollPhysics(),
                      backgroundDecoration:
                          BoxDecoration(color: Colors.black87),
                      loadingBuilder: (context, event) => Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    Positioned(
                      bottom: 16,
                      child: Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.delete, color: Colors.white),
                              onPressed: () =>
                                  _deleteImage(_images[_currentIndex]),
                            ),
                            Text(
                              '${_currentIndex + 1}/${_images.length}',
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Container(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _images.length,
                padding: EdgeInsets.all(8),
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      _pageController.animateToPage(
                        index,
                        duration: Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    child: Container(
                      width: 80,
                      margin: EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _currentIndex == index
                              ? Theme.of(context).primaryColor
                              : Colors.transparent,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.network(
                          _images[index],
                          fit: BoxFit.cover,
                        ),
                      ),
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

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}
