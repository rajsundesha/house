import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:house_rental_app/presentation/providers/property_provider.dart';
import 'package:house_rental_app/data/models/property.dart';
import 'package:house_rental_app/presentation/shared/widgets/dialog_components.dart';
import 'package:house_rental_app/presentation/shared/widgets/loading_overlay.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class AddMaintenanceTaskScreen extends StatefulWidget {
  final String propertyId;

  AddMaintenanceTaskScreen({required this.propertyId});

  @override
  _AddMaintenanceTaskScreenState createState() =>
      _AddMaintenanceTaskScreenState();
}

class _AddMaintenanceTaskScreenState extends State<AddMaintenanceTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _costController = TextEditingController();
  DateTime _scheduledDate = DateTime.now();
  String _priority = 'medium';
  List<File> _selectedImages = [];
  bool _isLoading = false;

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _scheduledDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _scheduledDate = picked);
    }
  }

  Future<void> _pickImages() async {
    final imagePicker = ImagePicker();
    final pickedFiles = await imagePicker.pickMultiImage();
    if (pickedFiles != null) {
      setState(() {
        _selectedImages.addAll(pickedFiles.map((file) => File(file.path)));
      });
    }
  }

  Future<void> _saveTask() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final maintenanceRecord = MaintenanceRecord(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        cost: double.parse(_costController.text.trim()),
        date: _scheduledDate,
        status: 'pending',
      );

      await Provider.of<PropertyProvider>(context, listen: false)
          .addMaintenanceRecord(widget.propertyId, maintenanceRecord);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Maintenance task added successfully')),
      );
      Navigator.pop(context);
    } catch (e) {
      showErrorDialog(context, 'Error adding maintenance task: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Maintenance Task'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveTask,
            child: Text(
              'Save',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: 'Task Title',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _costController,
                  decoration: InputDecoration(
                    labelText: 'Estimated Cost',
                    prefixText: '₹',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v?.isEmpty ?? true) return 'Required';
                    if (double.tryParse(v!) == null) return 'Invalid amount';
                    return null;
                  },
                ),
                SizedBox(height: 16),
                InkWell(
                  onTap: _selectDate,
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Scheduled Date',
                      border: OutlineInputBorder(),
                    ),
                    child: Text(DateFormat('MMM d, y').format(_scheduledDate)),
                  ),
                ),
                SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _priority,
                  decoration: InputDecoration(
                    labelText: 'Priority',
                    border: OutlineInputBorder(),
                  ),
                  items: ['low', 'medium', 'high'].map((priority) {
                    return DropdownMenuItem(
                      value: priority,
                      child: Text(priority.toUpperCase()),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _priority = val!),
                ),
                SizedBox(height: 24),
                Text('Task Images (Optional)',
                    style: Theme.of(context).textTheme.titleMedium),
                SizedBox(height: 8),
                if (_selectedImages.isNotEmpty)
                  Container(
                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _selectedImages.length,
                      itemBuilder: (context, index) {
                        return Stack(
                          children: [
                            Padding(
                              padding: EdgeInsets.only(right: 8),
                              child: Image.file(
                                _selectedImages[index],
                                height: 100,
                                width: 100,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 12,
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedImages.removeAt(index);
                                  });
                                },
                                child: Container(
                                  padding: EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.close, size: 16),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                SizedBox(height: 16),
                ElevatedButton.icon(
                  icon: Icon(Icons.add_photo_alternate),
                  label: Text('Add Images'),
                  onPressed: _pickImages,
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity, 48),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _costController.dispose();
    super.dispose();
  }
}
