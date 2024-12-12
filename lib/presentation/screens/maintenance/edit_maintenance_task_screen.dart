import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:house_rental_app/presentation/providers/property_provider.dart';
import 'package:house_rental_app/data/models/property.dart';
import 'package:house_rental_app/presentation/shared/widgets/dialog_components.dart';
import 'package:house_rental_app/presentation/shared/widgets/loading_overlay.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class EditMaintenanceTaskScreen extends StatefulWidget {
  final String propertyId;
  final MaintenanceRecord record;

  EditMaintenanceTaskScreen({
    required this.propertyId,
    required this.record,
  });

  @override
  _EditMaintenanceTaskScreenState createState() => _EditMaintenanceTaskScreenState();
}

class _EditMaintenanceTaskScreenState extends State<EditMaintenanceTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _costController;
  late DateTime _scheduledDate;
  late String _priority;
  late String _status;
  List<String> _existingImages = [];
  List<File> _newImages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _titleController = TextEditingController(text: widget.record.title);
    _descriptionController = TextEditingController(text: widget.record.description);
    _costController = TextEditingController(text: widget.record.cost.toString());
    _scheduledDate = widget.record.date;
    _status = widget.record.status;
  }

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
        _newImages.addAll(pickedFiles.map((file) => File(file.path)));
      });
    }
  }

  Future<void> _updateTask() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final updatedRecord = MaintenanceRecord(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        cost: double.parse(_costController.text.trim()),
        date: _scheduledDate,
        status: _status,
      );

      await Provider.of<PropertyProvider>(context, listen: false)
          .updateMaintenanceRecord(widget.propertyId, widget.record, updatedRecord);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Maintenance task updated successfully')),
      );
      Navigator.pop(context);
    } catch (e) {
      showErrorDialog(context, 'Error updating maintenance task: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Maintenance Task'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _updateTask,
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
                  value: _status,
                  decoration: InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(),
                  ),
                  items: ['pending', 'in_progress', 'completed'].map((status) {
                    return DropdownMenuItem(
                      value: status,
                      child: Text(status.toUpperCase()),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _status = val!),
                ),
                SizedBox(height: 24),
                Text('Task Images', style: Theme.of(context).textTheme.titleMedium),
                SizedBox(height: 8),
                if (_existingImages.isNotEmpty || _newImages.isNotEmpty)
                  Container(
                    height: 100,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        ..._existingImages.map((url) {
                          return Stack(
                            children: [
                              Padding(
                                padding: EdgeInsets.only(right: 8),
                                child: Image.network(
                                  url,
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
                                      _existingImages.remove(url);
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
                        }),
                        ..._newImages.map((file) {
                          return Stack(
                            children: [
                              Padding(
                                padding: EdgeInsets.only(right: 8),
                                child: Image.file(
                                  file,
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
                                      _newImages.remove(file);
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
                        }),
                      ],
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
                SizedBox(height: 24),
                if (_status == 'completed')
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Completion Details',
                              style: Theme.of(context).textTheme.titleMedium),
                          SizedBox(height: 16),
                          TextFormField(
                            decoration: InputDecoration(
                              labelText: 'Completion Notes',
                              border: OutlineInputBorder(),
                            ),
                            maxLines: 3,
                          ),
                          SizedBox(height: 16),
                          TextFormField(
                            decoration: InputDecoration(
                              labelText: 'Final Cost',
                              prefixText: '₹',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ],
                      ),
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
