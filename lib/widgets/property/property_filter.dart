import 'package:flutter/material.dart';

class PropertyFilter extends StatefulWidget {
  final String? selectedStatus;
  final double? minRent;
  final double? maxRent;
  final bool? furnished;
  final int? minBedrooms;
  final Function(Map<String, dynamic>) onApplyFilters;

  const PropertyFilter({
    Key? key,
    this.selectedStatus,
    this.minRent,
    this.maxRent,
    this.furnished,
    this.minBedrooms,
    required this.onApplyFilters,
  }) : super(key: key);

  @override
  _PropertyFilterState createState() => _PropertyFilterState();
}

class _PropertyFilterState extends State<PropertyFilter> {
  late String? _status;
  late double? _minRent;
  late double? _maxRent;
  late bool? _furnished;
  late int? _minBedrooms;

  @override
  void initState() {
    super.initState();
    _status = widget.selectedStatus;
    _minRent = widget.minRent;
    _maxRent = widget.maxRent;
    _furnished = widget.furnished;
    _minBedrooms = widget.minBedrooms;
  }

  void _applyFilters() {
    widget.onApplyFilters({
      'status': _status,
      'minRent': _minRent,
      'maxRent': _maxRent,
      'furnished': _furnished,
      'minBedrooms': _minBedrooms,
    });
    Navigator.pop(context);
  }

  void _resetFilters() {
    setState(() {
      _status = null;
      _minRent = null;
      _maxRent = null;
      _furnished = null;
      _minBedrooms = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Filter Properties',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          SizedBox(height: 16),

          // Status Filter
          DropdownButtonFormField<String>(
            decoration: InputDecoration(
              labelText: 'Status',
              border: OutlineInputBorder(),
            ),
            value: _status,
            items: ['All', 'Vacant', 'Occupied']
                .map((status) => DropdownMenuItem(
                      value: status == 'All' ? null : status.toLowerCase(),
                      child: Text(status),
                    ))
                .toList(),
            onChanged: (value) => setState(() => _status = value),
          ),
          SizedBox(height: 16),

          // Rent Range
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Min Rent',
                    border: OutlineInputBorder(),
                    prefixText: '₹',
                  ),
                  keyboardType: TextInputType.number,
                  initialValue: _minRent?.toString(),
                  onChanged: (value) =>
                      setState(() => _minRent = double.tryParse(value)),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Max Rent',
                    border: OutlineInputBorder(),
                    prefixText: '₹',
                  ),
                  keyboardType: TextInputType.number,
                  initialValue: _maxRent?.toString(),
                  onChanged: (value) =>
                      setState(() => _maxRent = double.tryParse(value)),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),

          // Other Filters
          CheckboxListTile(
            title: Text('Furnished Only'),
            value: _furnished ?? false,
            onChanged: (value) => setState(() => _furnished = value),
          ),

          // Bedrooms
          DropdownButtonFormField<int>(
            decoration: InputDecoration(
              labelText: 'Minimum Bedrooms',
              border: OutlineInputBorder(),
            ),
            value: _minBedrooms,
            items: [null, 1, 2, 3, 4, 5]
                .map((beds) => DropdownMenuItem(
                      value: beds,
                      child: Text(beds == null ? 'Any' : beds.toString()),
                    ))
                .toList(),
            onChanged: (value) => setState(() => _minBedrooms = value),
          ),
          SizedBox(height: 24),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _resetFilters,
                  child: Text('Reset'),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _applyFilters,
                  child: Text('Apply'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
