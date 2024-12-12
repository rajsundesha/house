import 'package:flutter/material.dart';
import 'package:house_rental_app/presentation/shared/widgets/custom_dropdown.dart';
import 'package:house_rental_app/presentation/shared/widgets/dialog_components.dart';
import 'package:house_rental_app/presentation/shared/widgets/loading_overlay.dart';
import 'package:provider/provider.dart';
import 'package:house_rental_app/presentation/providers/property_provider.dart';
import 'package:house_rental_app/data/models/property.dart';
// import 'package:house_rental_app/presentation/shared/widgets/custom_components.dart';
import 'package:house_rental_app/utils/currency_utils.dart';

class PropertySearchScreen extends StatefulWidget {
  @override
  _PropertySearchScreenState createState() => _PropertySearchScreenState();
}

class _PropertySearchScreenState extends State<PropertySearchScreen> {
  final _searchController = TextEditingController();
  RangeValues _priceRange = RangeValues(0, 100000);
  RangeValues _areaRange = RangeValues(0, 5000);
  String _selectedLocation = 'All';
  String _furnishingStatus = 'All';
  List<String> _selectedAmenities = [];
  bool _isLoading = false;

  // Filters
  String _selectedStatus = 'All';
  int _selectedBedrooms = 0;
  int _selectedBathrooms = 0;
  bool _hasParking = false;
  String _sortBy = 'rentAmount';
  bool _sortAscending = true;

  final List<String> _locations = [
    'All',
    'North',
    'South',
    'East',
    'West',
    'Central',
  ];

  final List<String> _furnishingTypes = [
    'All',
    'Unfurnished',
    'Semi-furnished',
    'Furnished',
  ];

  final List<String> _amenitiesList = [
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
  ];

  @override
  void initState() {
    super.initState();
    _loadProperties();
  }

  Future<void> _loadProperties() async {
    setState(() => _isLoading = true);
    try {
      await Provider.of<PropertyProvider>(context, listen: false).fetchProperties(
        status: _selectedStatus == 'All' ? null : _selectedStatus.toLowerCase(),
        furnishingStatus: _furnishingStatus == 'All'
            ? null
            : _furnishingStatus.toLowerCase(),
        minPrice: _priceRange.start,
        maxPrice: _priceRange.end,
        minArea: _areaRange.start,
        maxArea: _areaRange.end,
        amenities: _selectedAmenities.isEmpty ? null : _selectedAmenities,
        location:
            _selectedLocation == 'All' ? null : _selectedLocation.toLowerCase(),
      );
    } catch (e) {
      showErrorDialog(context, 'Error loading properties: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) => SingleChildScrollView(
            controller: scrollController,
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Filters', style: Theme.of(context).textTheme.headlineSmall),
                SizedBox(height: 16),
                
                // Price Range
                Text('Price Range',
                    style: Theme.of(context).textTheme.titleMedium),
                RangeSlider(
                  values: _priceRange,
                  min: 0,
                  max: 100000,
                  divisions: 100,
                  labels: RangeLabels(
                    CurrencyUtils.formatCurrency(_priceRange.start),
                    CurrencyUtils.formatCurrency(_priceRange.end),
                  ),
                  onChanged: (values) =>
                      setState(() => _priceRange = values),
                ),

                // Area Range
                Text('Area Range (sq ft)',
                    style: Theme.of(context).textTheme.titleMedium),
                RangeSlider(
                  values: _areaRange,
                  min: 0,
                  max: 5000,
                  divisions: 50,
                  labels: RangeLabels(
                    '${_areaRange.start.round()} sq ft',
                    '${_areaRange.end.round()} sq ft',
                  ),
                  onChanged: (values) =>
                      setState(() => _areaRange = values),
                ),

                // Location
                CustomDropdown<String>(
                  label: 'Location',
                  value: _selectedLocation,
                  items: _locations,
                  onChanged: (val) =>
                      setState(() => _selectedLocation = val!),
                  getLabel: (val) => val,
                ),
                SizedBox(height: 16),

                // Furnishing Status
                CustomDropdown<String>(
                  label: 'Furnishing Status',
                  value: _furnishingStatus,
                  items: _furnishingTypes,
                  onChanged: (val) =>
                      setState(() => _furnishingStatus = val!),
                  getLabel: (val) => val,
                ),
                SizedBox(height: 16),

                // Bedrooms & Bathrooms
                Row(
                  children: [
                    Expanded(
                      child: CustomDropdown<int>(
                        label: 'Bedrooms',
                        value: _selectedBedrooms,
                        items: List.generate(6, (i) => i),
                        onChanged: (val) =>
                            setState(() => _selectedBedrooms = val!),
                        getLabel: (val) => val == 0 ? 'Any' : val.toString(),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: CustomDropdown<int>(
                        label: 'Bathrooms',
                        value: _selectedBathrooms,
                        items: List.generate(6, (i) => i),
                        onChanged: (val) =>
                            setState(() => _selectedBathrooms = val!),
                        getLabel: (val) => val == 0 ? 'Any' : val.toString(),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),

                // Amenities
                Text('Amenities',
                    style: Theme.of(context).textTheme.titleMedium),
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
                SizedBox(height: 24),

                // Apply & Reset Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() {
                            _priceRange = RangeValues(0, 100000);
                            _areaRange = RangeValues(0, 5000);
                            _selectedLocation = 'All';
                            _furnishingStatus = 'All';
                            _selectedAmenities = [];
                            _selectedBedrooms = 0;
                            _selectedBathrooms = 0;
                            _hasParking = false;
                          });
                        },
                        child: Text('Reset'),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _loadProperties();
                        },
                        child: Text('Apply'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final propertyProvider = Provider.of<PropertyProvider>(context);
    final properties = propertyProvider.properties;

    return Scaffold(
      appBar: AppBar(
        title: Text('Property Search'),
        actions: [
          IconButton(
            icon: Icon(Icons.sort),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                builder: (context) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      title: Text('Sort by Price (Low to High)'),
                      onTap: () {
                        setState(() {
                          _sortBy = 'rentAmount';
                          _sortAscending = true;
                        });
                        Navigator.pop(context);
                        _loadProperties();
                      },
                    ),
                    ListTile(
                      title: Text('Sort by Price (High to Low)'),
                      onTap: () {
                        setState(() {
                          _sortBy = 'rentAmount';
                          _sortAscending = false;
                        });
                        Navigator.pop(context);
                        _loadProperties();
                      },
                    ),
                    ListTile(
                      title: Text('Sort by Area (Low to High)'),
                      onTap: () {
                        setState(() {
                          _sortBy = 'size';
                          _sortAscending = true;
                        });
                        Navigator.pop(context);
                        _loadProperties();
                      },
                    ),
                    ListTile(
                      title: Text('Sort by Area (High to Low)'),
                      onTap: () {
                        setState(() {
                          _sortBy = 'size';
                          _sortAscending = false;
                        });
                        Navigator.pop(context);
                        _loadProperties();
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search properties...',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onChanged: (value) {
                        // Implement search functionality
                      },
                    ),
                  ),
                  SizedBox(width: 8),
                  IconButton(
                    icon: Icon(Icons.filter_list),
                    onPressed: _showFilterSheet,
                  ),
                ],
              ),
            ),
            if (properties.isEmpty)
              Expanded(
                child: Center(
                  child: Text('No properties found'),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: properties.length,
                  itemBuilder: (context, index) {
                    final property = properties[index];
                    return Card(
                      margin: EdgeInsets.only(bottom: 16),
                      child: InkWell(
                        onTap: () => Navigator.pushNamed(
                          context,
                          '/property_detail',
                          arguments: property,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (property.images.isNotEmpty)
                              Image.network(
                                property.images.first,
                                height: 200,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            Padding(
                              padding: EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    property.address,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge,
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    property.location,
                                    style: TextStyle(
                                        color: Colors.grey[600]),
                                  ),
                                  SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Text(
                                        CurrencyUtils.formatCurrency(
                                            property.currentRentAmount),
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium!
                                            .copyWith(
                                              color: Theme.of(context)
                                                  .primaryColor,
                                            ),
                                      ),
                                      Spacer(),
                                      Chip(
                                        label: Text(
                                          property.status.toUpperCase(),
                                          style:
                                              TextStyle(fontSize: 12),
                                        ),
                                        backgroundColor: property
                                                    .status
                                                    .toLowerCase() ==
                                                'vacant'
                                            ? Colors.green.shade100
                                            : Colors.red.shade100,
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 8),
                                  Row(
                                    children: [
                                      _buildFeatureItem(
                                        Icons.king_bed,
                                        '${property.bedrooms} Beds',
                                      ),
                                      SizedBox(width: 16),
                                      _buildFeatureItem(
                                        Icons.bathtub,
                                        '${property.bathrooms} Baths',
                                      ),
                                      SizedBox(width: 16),
                                      _buildFeatureItem(
                                        Icons.square_foot,
                                        '${property.size} sq ft',
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
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

        Widget _buildFeatureItem(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}