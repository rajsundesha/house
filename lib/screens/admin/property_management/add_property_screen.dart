import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:house_rental_app/models/property.dart';
import 'package:house_rental_app/providers/property_provider.dart';
import 'package:house_rental_app/utils/currency_utils.dart';
import 'package:provider/provider.dart';

class PropertyFormSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const PropertyFormSection({
    Key? key,
    required this.title,
    required this.children,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        SizedBox(height: 16),
        ...children,
      ],
    );
  }
}

class AddPropertyScreen extends StatefulWidget {
  @override
  _AddPropertyScreenState createState() => _AddPropertyScreenState();
}

class _AddPropertyScreenState extends State<AddPropertyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  final _rentAmountController = TextEditingController();
  final _sizeController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _bedroomsController = TextEditingController();
  final _bathroomsController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  bool _hasFurnished = false;
  bool _hasParking = false;
  List<String> _selectedAmenities = [];

  final List<String> _availableAmenities = [
    'Air Conditioning',
    'Heating',
    'Internet',
    'Cable TV',
    'Security System',
    'Elevator',
    'Swimming Pool',
    'Gym',
    'Laundry',
    'Garden',
  ];

  Future<void> _saveProperty() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final rentAmount =
          CurrencyUtils.parseCurrency(_rentAmountController.text);

      final property = Property(
        id: '',
        address: _addressController.text.trim(),
        rentAmount: rentAmount,
        size: _sizeController.text.trim(),
        status: 'vacant',
        description: _descriptionController.text.trim(),
        bedrooms: int.tryParse(_bedroomsController.text) ?? 0,
        bathrooms: int.tryParse(_bathroomsController.text) ?? 0,
        furnished: _hasFurnished,
        parking: _hasParking,
        amenities: _selectedAmenities,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await Provider.of<PropertyProvider>(context, listen: false)
          .addProperty(property);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Property added successfully')),
      );
      Navigator.pop(context);
    } catch (e) {
      setState(() => _errorMessage = 'Failed to add property: ${e.toString()}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_errorMessage!)),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Property'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_errorMessage != null) _buildErrorBanner(),
                    _buildBasicInformationSection(),
                    SizedBox(height: 24),
                    _buildPropertyDetailsSection(),
                    SizedBox(height: 24),
                    _buildFeaturesSection(),
                    SizedBox(height: 24),
                    _buildAmenitiesSection(),
                    SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _saveProperty,
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Text('Save Property'),
                      ),
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      padding: EdgeInsets.all(8),
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Text(
        _errorMessage!,
        style: TextStyle(color: Colors.red),
      ),
    );
  }

  Widget _buildBasicInformationSection() {
    return PropertyFormSection(
      title: 'Basic Information',
      children: [
        TextFormField(
          controller: _addressController,
          decoration: InputDecoration(
            labelText: 'Address',
            prefixIcon: Icon(Icons.location_on),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          maxLines: 2,
          validator: (val) =>
              val?.isEmpty ?? true ? 'Please enter property address' : null,
        ),
        SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _rentAmountController,
                decoration: InputDecoration(
                  labelText: 'Rent Amount',
                  prefixText: '₹',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                keyboardType: TextInputType.numberWithOptions(
                    decimal: false), // Only integers
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Please enter rent amount';
                  }
                  final number = int.tryParse(value!);
                  if (number == null) {
                    return 'Please enter a valid amount';
                  }
                  if (number <= 0) {
                    return 'Amount must be greater than 0';
                  }
                  return null;
                },
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _sizeController,
                decoration: InputDecoration(
                  labelText: 'Size (sq ft)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: false),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (val) {
                  if (val?.isEmpty ?? true) return 'Please enter property size';
                  final number = int.tryParse(val!);
                  if (number == null || number <= 0)
                    return 'Please enter valid size';
                  return null;
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPropertyDetailsSection() {
    return PropertyFormSection(
      title: 'Property Details',
      children: [
        TextFormField(
          controller: _descriptionController,
          decoration: InputDecoration(
            labelText: 'Description',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          maxLines: 3,
        ),
        SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _bedroomsController,
                decoration: InputDecoration(
                  labelText: 'Bedrooms',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (val) {
                  if (val?.isEmpty ?? true) return 'Required';
                  final number = int.tryParse(val!);
                  if (number == null || number < 0) return 'Invalid number';
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
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (val) {
                  if (val?.isEmpty ?? true) return 'Required';
                  final number = int.tryParse(val!);
                  if (number == null || number < 0) return 'Invalid number';
                  return null;
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFeaturesSection() {
    return PropertyFormSection(
      title: 'Features',
      children: [
        SwitchListTile(
          title: Text('Furnished'),
          value: _hasFurnished,
          onChanged: (value) => setState(() => _hasFurnished = value),
          secondary: Icon(Icons.chair),
        ),
        SwitchListTile(
          title: Text('Parking Available'),
          value: _hasParking,
          onChanged: (value) => setState(() => _hasParking = value),
          secondary: Icon(Icons.local_parking),
        ),
      ],
    );
  }

  Widget _buildAmenitiesSection() {
    return PropertyFormSection(
      title: 'Amenities',
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _availableAmenities.map((amenity) {
            final isSelected = _selectedAmenities.contains(amenity);
            return FilterChip(
              label: Text(amenity),
              selected: isSelected,
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
      ],
    );
  }

  @override
  void dispose() {
    _addressController.dispose();
    _rentAmountController.dispose();
    _sizeController.dispose();
    _descriptionController.dispose();
    _bedroomsController.dispose();
    _bathroomsController.dispose();
    super.dispose();
  }
}
