import 'package:flutter/material.dart';
import '../../models/property.dart';
import '../../utils/input_validators.dart';

class PropertyForm extends StatefulWidget {
  final Property? property;
  final Function(Property) onSubmit;

  const PropertyForm({
    Key? key,
    this.property,
    required this.onSubmit,
  }) : super(key: key);

  @override
  _PropertyFormState createState() => _PropertyFormState();
}

class _PropertyFormState extends State<PropertyForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _addressController;
  late TextEditingController _rentController;
  late TextEditingController _sizeController;
  late TextEditingController _descriptionController;
  List<String> _selectedAmenities = [];
  bool _furnished = false;
  bool _parking = false;
  int _bedrooms = 1;
  int _bathrooms = 1;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    final property = widget.property;
    _addressController = TextEditingController(text: property?.address);
    _rentController = TextEditingController(
      text: property?.rentAmount.toString(),
    );
    _sizeController = TextEditingController(text: property?.size);
    _descriptionController = TextEditingController(
      text: property?.description,
    );

    if (property != null) {
      _selectedAmenities = List.from(property.amenities);
      _furnished = property.furnished;
      _parking = property.parking;
      _bedrooms = property.bedrooms;
      _bathrooms = property.bathrooms;
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final property = Property(
        id: widget.property?.id ?? '',
        address: _addressController.text,
        rentAmount: double.parse(_rentController.text),
        size: _sizeController.text,
        status: widget.property?.status ?? 'vacant',
        description: _descriptionController.text,
        bedrooms: _bedrooms,
        bathrooms: _bathrooms,
        furnished: _furnished,
        parking: _parking,
        amenities: _selectedAmenities,
        createdAt: widget.property?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      widget.onSubmit(property);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: EdgeInsets.all(16),
        children: [
          // Basic Information
          Text(
            'Basic Information',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          SizedBox(height: 16),

          TextFormField(
            controller: _addressController,
            decoration: InputDecoration(
              labelText: 'Address',
              prefixIcon: Icon(Icons.location_on),
            ),
            validator: (value) => InputValidators.validateRequired(
              value,
              'Address',
            ),
          ),
          SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _rentController,
                  decoration: InputDecoration(
                    labelText: 'Rent Amount',
                    prefixIcon: Icon(Icons.currency_rupee),
                  ),
                  keyboardType: TextInputType.number,
                  validator: InputValidators.validateAmount,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _sizeController,
                  decoration: InputDecoration(
                    labelText: 'Size (sq ft)',
                    prefixIcon: Icon(Icons.straighten),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) => InputValidators.validateRequired(
                    value,
                    'Size',
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 24),

          // Features
          Text(
            'Features',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Bedrooms'),
                    SizedBox(height: 8),
                    NumberPicker(
                      value: _bedrooms,
                      onChanged: (value) => setState(() => _bedrooms = value),
                      min: 1,
                      max: 5,
                    ),
                  ],
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Bathrooms'),
                    SizedBox(height: 8),
                    NumberPicker(
                      value: _bathrooms,
                      onChanged: (value) => setState(() => _bathrooms = value),
                      min: 1,
                      max: 4,
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16),

          SwitchListTile(
            title: Text('Furnished'),
            value: _furnished,
            onChanged: (value) => setState(() => _furnished = value),
          ),
          SwitchListTile(
            title: Text('Parking Available'),
            value: _parking,
            onChanged: (value) => setState(() => _parking = value),
          ),
          SizedBox(height: 24),

          // Amenities
          Text(
            'Amenities',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          SizedBox(height: 16),

          AmenitySelector(
            selectedAmenities: _selectedAmenities,
            onChanged: (amenities) =>
                setState(() => _selectedAmenities = amenities),
          ),
          SizedBox(height: 32),

          ElevatedButton(
            onPressed: _submitForm,
            child: Text('Save Property'),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _addressController.dispose();
    _rentController.dispose();
    _sizeController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
