import 'package:flutter/material.dart';
import 'package:house_rental_app/presentation/shared/widgets/dialog_components.dart';
import 'package:house_rental_app/presentation/shared/widgets/image_picker_widget.dart';
import 'package:house_rental_app/presentation/shared/widgets/loading_overlay.dart';
import 'package:provider/provider.dart';
import 'package:house_rental_app/data/models/property.dart';
import 'package:house_rental_app/presentation/providers/property_provider.dart';
import 'package:house_rental_app/utils/currency_utils.dart';
import 'dart:io';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class EditPropertyScreen extends StatefulWidget {
  final Property property;

  EditPropertyScreen({required this.property});

  @override
  _EditPropertyScreenState createState() => _EditPropertyScreenState();
}

class _EditPropertyScreenState extends State<EditPropertyScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _addressController;
  late TextEditingController _locationController;
  late TextEditingController _rentAmountController;
  late TextEditingController _maintenanceChargeController;
  late TextEditingController _yearlyIncreaseController;
  late TextEditingController _sizeController;
  late TextEditingController _descriptionController;
  late TextEditingController _bedroomsController;
  late TextEditingController _bathroomsController;

  String _furnishingStatus = 'unfurnished';
  bool _hasParking = false;
  List<String> _selectedAmenities = [];
  List<String> _existingImages = [];
  List<File> _newImages = [];
  Map<String, double> _coordinates = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadExistingData();
  }

  void _initializeControllers() {
    _addressController = TextEditingController(text: widget.property.address);
    _locationController = TextEditingController(text: widget.property.location);
    _rentAmountController = TextEditingController(
        text: widget.property.currentRentAmount.toString());
    _maintenanceChargeController = TextEditingController(
        text: widget.property.maintenanceCharge.toString());
    _yearlyIncreaseController = TextEditingController(
        text: widget.property.yearlyIncreasePercentage.toString());
    _sizeController = TextEditingController(text: widget.property.size);
    _descriptionController =
        TextEditingController(text: widget.property.description);
    _bedroomsController =
        TextEditingController(text: widget.property.bedrooms.toString());
    _bathroomsController =
        TextEditingController(text: widget.property.bathrooms.toString());
  }

  void _loadExistingData() {
    _furnishingStatus = widget.property.furnishingStatus;
    _hasParking = widget.property.parking;
    _selectedAmenities = List.from(widget.property.amenities);
    _existingImages = List.from(widget.property.images);
    _coordinates = Map.from(widget.property.locationCoordinates);
  }

  Future<void> _saveProperty() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final updatedProperty = Property(
        id: widget.property.id,
        address: _addressController.text,
        location: _locationController.text,
        baseRentAmount: CurrencyUtils.parseCurrency(_rentAmountController.text),
        currentRentAmount:
            CurrencyUtils.parseCurrency(_rentAmountController.text),
        maintenanceCharge:
            CurrencyUtils.parseCurrency(_maintenanceChargeController.text),
        yearlyIncreasePercentage: double.parse(_yearlyIncreaseController.text),
        status: widget.property.status,
        size: _sizeController.text,
        assignedManagerId: widget.property.assignedManagerId,
        description: _descriptionController.text,
        bedrooms: int.parse(_bedroomsController.text),
        bathrooms: int.parse(_bathroomsController.text),
        furnishingStatus: _furnishingStatus,
        parking: _hasParking,
        amenities: _selectedAmenities,
        locationCoordinates: _coordinates,
        images: _existingImages,
        createdAt: widget.property.createdAt,
        updatedAt: DateTime.now(),
        maintenanceRecords: widget.property.maintenanceRecords,
        flexibleRentHistory: widget.property.flexibleRentHistory,
      );

      // First, update the property
      await Provider.of<PropertyProvider>(context, listen: false)
          .updateProperty(updatedProperty);

      // Then, if there are new images, add them
      if (_newImages.isNotEmpty) {
        await Provider.of<PropertyProvider>(context, listen: false)
            .addPropertyImages(widget.property.id, _newImages);
      }

      showSuccessDialog(
        context,
        'Property updated successfully',
        onDismissed: () => Navigator.pop(context),
      );
    } catch (e) {
      showErrorDialog(context, 'Error updating property: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Property'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveProperty,
            child: Text(
              'Save',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ImagePickerWidget(
                  initialImages: _existingImages,
                  onImagesSelected: (files) {
                    setState(() => _newImages = files);
                  },
                  onImageRemoved: (url) async {
                    try {
                      await Provider.of<PropertyProvider>(context,
                              listen: false)
                          .removePropertyImage(widget.property.id, url);
                      setState(() {
                        _existingImages.remove(url);
                      });
                    } catch (e) {
                      showErrorDialog(context, 'Error removing image: $e');
                    }
                  },
                ),
                SizedBox(height: 16),

                // Basic Information
                Text('Basic Information',
                    style: Theme.of(context).textTheme.titleLarge),
                SizedBox(height: 8),
                TextFormField(
                  controller: _addressController,
                  decoration: InputDecoration(
                    labelText: 'Address',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _locationController,
                  decoration: InputDecoration(
                    labelText: 'Location/Area',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                ),
                SizedBox(height: 16),

                // Rent Information
                Text('Rent Information',
                    style: Theme.of(context).textTheme.titleLarge),
                SizedBox(height: 8),
                TextFormField(
                  controller: _rentAmountController,
                  decoration: InputDecoration(
                    labelText: 'Rent Amount',
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
                TextFormField(
                  controller: _maintenanceChargeController,
                  decoration: InputDecoration(
                    labelText: 'Maintenance Charge',
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
                TextFormField(
                  controller: _yearlyIncreaseController,
                  decoration: InputDecoration(
                    labelText: 'Yearly Increase Percentage',
                    suffixText: '%',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v?.isEmpty ?? true) return 'Required';
                    final percent = double.tryParse(v!);
                    if (percent == null || percent < 0 || percent > 100)
                      return 'Invalid percentage';
                    return null;
                  },
                ),
                SizedBox(height: 16),

                // Property Details
                Text('Property Details',
                    style: Theme.of(context).textTheme.titleLarge),
                SizedBox(height: 8),
                TextFormField(
                  controller: _sizeController,
                  decoration: InputDecoration(
                    labelText: 'Size (sq ft)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v?.isEmpty ?? true) return 'Required';
                    if (double.tryParse(v!) == null) return 'Invalid size';
                    return null;
                  },
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _bedroomsController,
                        decoration: InputDecoration(
                          labelText: 'Bedrooms',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          if (v?.isEmpty ?? true) return 'Required';
                          if (int.tryParse(v!) == null) return 'Invalid number';
                          return null;
                        },
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _bathroomsController,
                        decoration: InputDecoration(
                          labelText: 'Bathrooms',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          if (v?.isEmpty ?? true) return 'Required';
                          if (int.tryParse(v!) == null) return 'Invalid number';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
// Furnishing Status
                Text('Furnishing Status',
                    style: Theme.of(context).textTheme.titleLarge),
                SizedBox(height: 8),
                Column(
                  children: [
                    RadioListTile<String>(
                      title: Text('Unfurnished'),
                      value: 'unfurnished',
                      groupValue: _furnishingStatus,
                      onChanged: (value) {
                        setState(() => _furnishingStatus = value!);
                      },
                    ),
                    RadioListTile<String>(
                      title: Text('Semi-furnished'),
                      value: 'semi-furnished',
                      groupValue: _furnishingStatus,
                      onChanged: (value) {
                        setState(() => _furnishingStatus = value!);
                      },
                    ),
                    RadioListTile<String>(
                      title: Text('Furnished'),
                      value: 'furnished',
                      groupValue: _furnishingStatus,
                      onChanged: (value) {
                        setState(() => _furnishingStatus = value!);
                      },
                    ),
                  ],
                ),
                SizedBox(height: 16),

                // Parking
                SwitchListTile(
                  title: Text('Parking Available'),
                  value: _hasParking,
                  onChanged: (value) {
                    setState(() => _hasParking = value);
                  },
                ),
                SizedBox(height: 16),

                // Description
                Text('Description',
                    style: Theme.of(context).textTheme.titleLarge),
                SizedBox(height: 8),
                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    hintText: 'Enter property description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                SizedBox(height: 16),

                // Amenities
                Text('Amenities',
                    style: Theme.of(context).textTheme.titleLarge),
                SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    'Air Conditioning',
                    'Power Backup',
                    'Security',
                    'Garden',
                    'Gym',
                    'Swimming Pool',
                    'Lift',
                    'Club House',
                    'Parking',
                    'Water Supply',
                    'Gas Pipeline',
                    'Fire Safety',
                    'Internet',
                    'Intercom',
                  ].map((amenity) {
                    return FilterChip(
                      label: Text(amenity),
                      selected: _selectedAmenities.contains(amenity),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedAmenities.add(amenity);
                          } else {
                            _selectedAmenities.remove(amenity);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                SizedBox(height: 16),

                // Location Picker
                Text('Location on Map',
                    style: Theme.of(context).textTheme.titleLarge),
                SizedBox(height: 8),
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: _coordinates.isEmpty
                      ? Center(
                          child: TextButton.icon(
                            icon: Icon(Icons.add_location),
                            label: Text('Pick Location'),
                            onPressed: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => LocationPickerScreen(
                                    initialPosition: _coordinates.isEmpty
                                        ? LatLng(0, 0)
                                        : LatLng(
                                            _coordinates['latitude']!,
                                            _coordinates['longitude']!,
                                          ),
                                  ),
                                ),
                              );

                              if (result != null &&
                                  result is Map<String, double>) {
                                setState(() => _coordinates = result);
                              }
                            },
                          ),
                        )
                      : Stack(
                          children: [
                            GoogleMap(
                              initialCameraPosition: CameraPosition(
                                target: LatLng(
                                  _coordinates['latitude']!,
                                  _coordinates['longitude']!,
                                ),
                                zoom: 15,
                              ),
                              markers: {
                                Marker(
                                  markerId: MarkerId('property_location'),
                                  position: LatLng(
                                    _coordinates['latitude']!,
                                    _coordinates['longitude']!,
                                  ),
                                ),
                              },
                              zoomControlsEnabled: false,
                              mapToolbarEnabled: false,
                              myLocationButtonEnabled: false,
                            ),
                            Positioned(
                              right: 8,
                              top: 8,
                              child: FloatingActionButton.small(
                                onPressed: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          LocationPickerScreen(
                                        initialPosition: LatLng(
                                          _coordinates['latitude']!,
                                          _coordinates['longitude']!,
                                        ),
                                      ),
                                    ),
                                  );

                                  if (result != null &&
                                      result is Map<String, double>) {
                                    setState(() => _coordinates = result);
                                  }
                                },
                                child: Icon(Icons.edit_location),
                              ),
                            ),
                          ],
                        ),
                ),
                SizedBox(height: 32),

                // Save Button
                ElevatedButton(
                  onPressed: _isLoading ? null : _saveProperty,
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text(_isLoading ? 'Saving...' : 'Save Changes'),
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
    _addressController.dispose();
    _locationController.dispose();
    _rentAmountController.dispose();
    _maintenanceChargeController.dispose();
    _yearlyIncreaseController.dispose();
    _sizeController.dispose();
    _descriptionController.dispose();
    _bedroomsController.dispose();
    _bathroomsController.dispose();
    super.dispose();
  }
}

// Location Picker Screen
class LocationPickerScreen extends StatefulWidget {
  final LatLng initialPosition;

  LocationPickerScreen({required this.initialPosition});

  @override
  _LocationPickerScreenState createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  late GoogleMapController _mapController;
  LatLng? _selectedLocation;

  @override
  void initState() {
    super.initState();
    _selectedLocation = widget.initialPosition;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pick Location'),
        actions: [
          if (_selectedLocation != null)
            TextButton(
              onPressed: () {
                Navigator.pop(context, {
                  'latitude': _selectedLocation!.latitude,
                  'longitude': _selectedLocation!.longitude,
                });
              },
              child: Text(
                'CONFIRM',
                style: TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: widget.initialPosition,
              zoom: 15,
            ),
            onMapCreated: (controller) {
              _mapController = controller;
            },
            onTap: (location) {
              setState(() {
                _selectedLocation = location;
              });
            },
            markers: _selectedLocation == null
                ? {}
                : {
                    Marker(
                      markerId: MarkerId('selected_location'),
                      position: _selectedLocation!,
                    ),
                  },
          ),
          if (_selectedLocation == null)
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.touch_app, size: 32),
                  Text('Tap on the map to select location'),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
