import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class PhotoPicker extends StatelessWidget {
  final void Function(XFile) onImageSelected;
  final String? imageUrl;
  final double size;
  final String? title;
  final bool circle;

  const PhotoPicker({
    Key? key,
    required this.onImageSelected,
    this.imageUrl,
    this.size = 150,
    this.title,
    this.circle = false,
  }) : super(key: key);

  Future<void> _pickImage(BuildContext context) async {
    try {
      final source = await showDialog<ImageSource>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Select Image Source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.camera_alt),
                title: Text('Camera'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: Icon(Icons.photo_library),
                title: Text('Gallery'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        ),
      );

      if (source != null) {
        final ImagePicker picker = ImagePicker();
        final XFile? image = await picker.pickImage(
          source: source,
          maxWidth: 1200,
          maxHeight: 1200,
          imageQuality: 85,
        );

        if (image != null) {
          onImageSelected(image);
        }
      }
    } catch (e) {
      print('Error picking image: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget content = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: circle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: circle ? null : BorderRadius.circular(8),
        color: Colors.grey[200],
        image: imageUrl != null
            ? DecorationImage(
                image: NetworkImage(imageUrl!),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: imageUrl == null
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add_a_photo,
                  size: 32,
                  color: Colors.grey[600],
                ),
                if (title != null) ...[
                  SizedBox(height: 8),
                  Text(
                    title!,
                    style: TextStyle(color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            )
          : null,
    );

    return InkWell(
      onTap: () => _pickImage(context),
      borderRadius:
          circle ? BorderRadius.circular(size / 2) : BorderRadius.circular(8),
      child: content,
    );
  }
}
