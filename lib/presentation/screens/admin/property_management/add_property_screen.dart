import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

import 'package:house_rental_app/presentation/providers/property_provider.dart';
import 'package:house_rental_app/data/models/property.dart';
import 'package:house_rental_app/utils/currency_utils.dart';

class AddPropertyScreen extends StatefulWidget {
  @override
  _AddPropertyScreenState createState() => _AddPropertyScreenState();
}

class _AddPropertyScreenState extends State<AddPropertyScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _addressController = TextEditingController();
  final _locationController = TextEditingController();
  final _rentAmountController = TextEditingController();
  final _maintenanceChargeController = TextEditingController();
  final _yearlyIncreaseController = TextEditingController(text: '5');
  final _sizeController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _bedroomsController = TextEditingController();
  final _bathroomsController = TextEditingController();

  List<File> _selectedImages = [];
  Map<String, double> _coordinates = {};

  String _furnishingStatus = 'unfurnished';
  bool _hasParking = false;
  List<String> _selectedAmenities = [];
  bool _isLoading = false;
  String? _error;

  final _amenitiesList = [
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
    'Intercom'
  ];

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
  }

  Future<void> _checkLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    // No direct UI feedback here, just ensuring permission is requested.
  }

  Future<void> _pickImages() async {
    try {
      final imagePicker = ImagePicker();
      final pickedFiles = await imagePicker.pickMultiImage();
      if (pickedFiles != null) {
        setState(() {
          _selectedImages
              .addAll(pickedFiles.map((file) => File(file.path)).toList());
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error picking images: $e')));
    }
  }

  Future<void> _pickLocation() async {
    try {
      // Get current position with a timeout to avoid "freezing"
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(const Duration(seconds: 10), onTimeout: () {
        throw 'Location request timed out. Please ensure GPS is on.';
      });

      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => LocationPickerScreen(
            initialPosition: LatLng(position.latitude, position.longitude),
          ),
        ),
      );

      if (result != null && result is Map<String, double>) {
        setState(() {
          _coordinates = result;
          // Show the selected coordinates in the locationController
          _locationController.text =
              '${_coordinates['latitude']?.toStringAsFixed(5)}, ${_coordinates['longitude']?.toStringAsFixed(5)}';
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error picking location: $e')));
    }
  }

  Future<void> _saveProperty() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please add at least one property image')));
      return;
    }

    if (_coordinates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please select property location on map')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final property = Property(
        id: '',
        address: _addressController.text,
        location: _locationController.text,
        baseRentAmount: CurrencyUtils.parseCurrency(_rentAmountController.text),
        currentRentAmount:
            CurrencyUtils.parseCurrency(_rentAmountController.text),
        maintenanceCharge:
            CurrencyUtils.parseCurrency(_maintenanceChargeController.text),
        yearlyIncreasePercentage: double.parse(_yearlyIncreaseController.text),
        status: 'vacant',
        size: _sizeController.text,
        description: _descriptionController.text,
        bedrooms: int.parse(_bedroomsController.text),
        bathrooms: int.parse(_bathroomsController.text),
        furnishingStatus: _furnishingStatus,
        parking: _hasParking,
        amenities: _selectedAmenities,
        locationCoordinates: _coordinates,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await Provider.of<PropertyProvider>(context, listen: false)
          .addProperty(property, _selectedImages);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Property added successfully')));
      Navigator.pop(context);
    } catch (e) {
      setState(() => _error = e.toString());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error adding property: $_error')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildImageSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Property Images',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            if (_selectedImages.isNotEmpty)
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _selectedImages.length,
                  itemBuilder: (context, index) {
                    return Stack(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Image.file(
                            _selectedImages[index],
                            height: 120,
                            width: 120,
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
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close, size: 16),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.add_photo_alternate),
              label: const Text('Add Images'),
              onPressed: _pickImages,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Location Details',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          TextFormField(
            controller: _addressController,
            decoration: const InputDecoration(
              labelText: 'Complete Address',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
            validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _locationController,
            decoration: const InputDecoration(
              labelText: 'Area/Locality',
              border: OutlineInputBorder(),
            ),
            validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            icon: const Icon(Icons.location_on),
            label: Text(_coordinates.isEmpty
                ? 'Pick Location on Map'
                : 'Location Selected'),
            onPressed: _pickLocation,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
              backgroundColor: _coordinates.isEmpty ? null : Colors.green,
            ),
          ),
          if (_coordinates.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
                'Selected Coordinates: ${_coordinates['latitude']?.toStringAsFixed(5)}, ${_coordinates['longitude']?.toStringAsFixed(5)}')
          ]
        ]),
      ),
    );
  }

  Widget _buildRentSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Rent Details', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          TextFormField(
            controller: _rentAmountController,
            decoration: const InputDecoration(
              labelText: 'Base Rent Amount',
              prefixText: '₹',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            validator: (v) {
              if (v?.isEmpty ?? true) return 'Required';
              final amount = CurrencyUtils.parseCurrency(v!);
              if (amount <= 0) return 'Invalid amount';
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _maintenanceChargeController,
            decoration: const InputDecoration(
              labelText: 'Maintenance Charge',
              prefixText: '₹',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            validator: (v) {
              if (v?.isEmpty ?? true) return 'Required';
              final amount = CurrencyUtils.parseCurrency(v!);
              if (amount < 0) return 'Invalid amount';
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _yearlyIncreaseController,
            decoration: const InputDecoration(
              labelText: 'Yearly Increase Percentage',
              suffixText: '%',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            validator: (v) {
              if (v?.isEmpty ?? true) return 'Required';
              final percent = double.tryParse(v!);
              if (percent == null || percent < 0 || percent > 100) {
                return 'Invalid percentage';
              }
              return null;
            },
          ),
        ]),
      ),
    );
  }

  Widget _buildPropertyDetailsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Property Details',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          TextFormField(
            controller: _sizeController,
            decoration: const InputDecoration(
              labelText: 'Size (sq ft)',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            validator: (v) {
              if (v?.isEmpty ?? true) return 'Required';
              final size = double.tryParse(v!);
              if (size == null || size <= 0) return 'Invalid size';
              return null;
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _bedroomsController,
                  decoration: const InputDecoration(
                    labelText: 'Bedrooms',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v?.isEmpty ?? true) return 'Required';
                    final n = int.tryParse(v!);
                    if (n == null || n < 0) return 'Invalid';
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _bathroomsController,
                  decoration: const InputDecoration(
                    labelText: 'Bathrooms',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v?.isEmpty ?? true) return 'Required';
                    final n = int.tryParse(v!);
                    if (n == null || n < 0) return 'Invalid';
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: 'Description',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
        ]),
      ),
    );
  }

  Widget _buildFurnishingSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Furnishing Status',
              style: Theme.of(context).textTheme.titleLarge),
          RadioListTile<String>(
            title: const Text('Unfurnished'),
            value: 'unfurnished',
            groupValue: _furnishingStatus,
            onChanged: (val) => setState(() => _furnishingStatus = val!),
          ),
          RadioListTile<String>(
            title: const Text('Semi-furnished'),
            value: 'semi-furnished',
            groupValue: _furnishingStatus,
            onChanged: (val) => setState(() => _furnishingStatus = val!),
          ),
          RadioListTile<String>(
            title: const Text('Furnished'),
            value: 'furnished',
            groupValue: _furnishingStatus,
            onChanged: (val) => setState(() => _furnishingStatus = val!),
          ),
        ]),
      ),
    );
  }

  Widget _buildAmenitiesSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Amenities', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _amenitiesList.map((amenity) {
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
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Property'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_error != null)
                      Container(
                        padding: const EdgeInsets.all(8),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Text(_error!,
                            style: const TextStyle(color: Colors.red)),
                      ),
                    _buildImageSection(),
                    const SizedBox(height: 16),
                    _buildLocationSection(),
                    const SizedBox(height: 16),
                    _buildRentSection(),
                    const SizedBox(height: 16),
                    _buildPropertyDetailsSection(),
                    const SizedBox(height: 16),
                    _buildFurnishingSection(),
                    const SizedBox(height: 16),
                    _buildAmenitiesSection(),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _saveProperty,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Text(_isLoading ? 'Saving...' : 'Save Property'),
                      ),
                    ),
                  ],
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

class LocationPickerScreen extends StatefulWidget {
  final LatLng initialPosition;

  LocationPickerScreen({required this.initialPosition});

  @override
  _LocationPickerScreenState createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  late GoogleMapController _controller;
  LatLng? _selectedLocation;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pick Location'),
        // If you prefer the top-right approach:
        // actions: [
        //   TextButton(
        //     onPressed: _selectedLocation == null ? null : () {
        //       Navigator.pop(context, {
        //         'latitude': _selectedLocation!.latitude,
        //         'longitude': _selectedLocation!.longitude,
        //       });
        //     },
        //     child: Text('CONFIRM', style: TextStyle(color: Colors.white)),
        //   ),
        // ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: widget.initialPosition,
              zoom: 15,
            ),
            onMapCreated: (controller) {
              _controller = controller;
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
          if (_selectedLocation != null)
            Positioned(
              bottom: 20,
              right: 20,
              left: 20,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context, {
                    'latitude': _selectedLocation!.latitude,
                    'longitude': _selectedLocation!.longitude,
                  });
                },
                child: Text('CONFIRM'),
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 48),
                ),
              ),
            ),
        ],
      ),
    );
  }
}


// class LocationPickerScreen extends StatefulWidget {
//   final LatLng initialPosition;

//   const LocationPickerScreen({required this.initialPosition});

//   @override
//   _LocationPickerScreenState createState() => _LocationPickerScreenState();
// }

// class _LocationPickerScreenState extends State<LocationPickerScreen> {
//   late GoogleMapController _controller;
//   LatLng? _selectedLocation;

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Pick Location'),
//         actions: [
//           if (_selectedLocation != null)
//             TextButton(
//               onPressed: () {
//                 Navigator.pop(context, {
//                   'latitude': _selectedLocation!.latitude,
//                   'longitude': _selectedLocation!.longitude,
//                 });
//               },
//               child: const Text(
//                 'CONFIRM',
//                 style: TextStyle(color: Colors.white),
//               ),
//             ),
//         ],
//       ),
//       body: Stack(
//         children: [
//           GoogleMap(
//             initialCameraPosition: CameraPosition(
//               target: widget.initialPosition,
//               zoom: 15,
//             ),
//             onMapCreated: (controller) {
//               _controller = controller;
//             },
//             onTap: (location) {
//               setState(() {
//                 _selectedLocation = location;
//               });
//             },
//             markers: _selectedLocation == null
//                 ? {}
//                 : {
//                     Marker(
//                       markerId: const MarkerId('selected_location'),
//                       position: _selectedLocation!,
//                     ),
//                   },
//           ),
//           if (_selectedLocation == null)
//             Center(
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: const [
//                   Icon(Icons.touch_app, size: 32),
//                   Text('Tap on the map to select location'),
//                 ],
//               ),
//             ),
//         ],
//       ),
//     );
//   }
// }
