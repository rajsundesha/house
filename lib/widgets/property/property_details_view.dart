// lib/widgets/property/property_details_view.dart
import 'package:flutter/material.dart';
import 'package:house_rental_app/widgets/property/image_carousel.dart';
import 'package:house_rental_app/widgets/property/status_badge.dart';
import '../../models/property.dart';

class PropertyDetailsView extends StatelessWidget {
  final Property property;
  final bool isEditing;
  final Function(Property)? onEdit;

  const PropertyDetailsView({
    Key? key,
    required this.property,
    this.isEditing = false,
    this.onEdit,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.all(16),
      children: [
        // Images Carousel
        PropertyImageCarousel(
          images: property.images,
          height: 250,
        ),
        SizedBox(height: 16),

        // Status and Actions
        Row(
          children: [
            StatusBadge(status: property.status),
            Spacer(),
            if (onEdit != null)
              IconButton(
                icon: Icon(Icons.edit),
                onPressed: () => onEdit!(property),
              ),
          ],
        ),
        SizedBox(height: 16),

        // Basic Information Card
        Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Basic Information',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Divider(),
                _buildInfoRow(
                  'Address',
                  property.address,
                  Icons.location_on,
                ),
                _buildInfoRow(
                  'Rent',
                  '₹${property.rentAmount}/month',
                  Icons.currency_rupee,
                ),
                _buildInfoRow(
                  'Size',
                  '${property.size} sq ft',
                  Icons.straighten,
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 16),

        // Features Card
        Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Features',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Divider(),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    _buildFeature(
                      'Bedrooms',
                      '${property.bedrooms}',
                      Icons.bed,
                    ),
                    _buildFeature(
                      'Bathrooms',
                      '${property.bathrooms}',
                      Icons.bathroom,
                    ),
                    _buildFeature(
                      'Furnished',
                      property.furnished ? 'Yes' : 'No',
                      Icons.chair,
                    ),
                    _buildFeature(
                      'Parking',
                      property.parking ? 'Available' : 'Not Available',
                      Icons.local_parking,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 16),

        // Amenities Card
        if (property.amenities.isNotEmpty)
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Amenities',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Divider(),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: property.amenities.map((amenity) {
                      return Chip(
                        label: Text(amenity),
                        backgroundColor:
                            Theme.of(context).primaryColor.withOpacity(0.1),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeature(String label, String value, IconData icon) {
    return Container(
      width: 100,
      child: Column(
        children: [
          Icon(icon, size: 24),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
