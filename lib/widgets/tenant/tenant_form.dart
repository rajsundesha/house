import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/tenant.dart';
import '../../utils/input_validators.dart';

class TenantForm extends StatefulWidget {
  final String propertyId;
  final Tenant? tenant;
  final Function(Tenant) onSubmit;

  const TenantForm({
    Key? key,
    required this.propertyId,
    this.tenant,
    required this.onSubmit,
  }) : super(key: key);

  @override
  _TenantFormState createState() => _TenantFormState();
}

class _TenantFormState extends State<TenantForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _advanceController;
  late DateTime _leaseStartDate;
  late DateTime _leaseEndDate;
  bool _advancePaid = false;
  String _selectedCategory = 'Family';

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    final tenant = widget.tenant;
    _nameController = TextEditingController(text: tenant?.name);
    _phoneController = TextEditingController(
      text: tenant?.contactInfo['phone'],
    );
    _emailController = TextEditingController(
      text: tenant?.contactInfo['email'],
    );
    _advanceController = TextEditingController(
      text: tenant?.advanceAmount.toString(),
    );

    _leaseStartDate = tenant?.leaseStartDate ?? DateTime.now();
    _leaseEndDate =
        tenant?.leaseEndDate ?? DateTime.now().add(Duration(days: 365));
    _advancePaid = tenant?.advancePaid ?? false;
    _selectedCategory = tenant?.category ?? 'Family';
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final tenant = Tenant(
        id: widget.tenant?.id ?? '',
        propertyId: widget.propertyId,
        name: _nameController.text,
        contactInfo: {
          'phone': _phoneController.text,
          'email': _emailController.text,
        },
        category: _selectedCategory,
        leaseStartDate: _leaseStartDate,
        leaseEndDate: _leaseEndDate,
        advancePaid: _advancePaid,
        advanceAmount: _advancePaid ? double.parse(_advanceController.text) : 0,
        createdAt: widget.tenant?.createdAt ?? DateTime.now(),
        lastUpdatedAt: DateTime.now(),
      );

      widget.onSubmit(tenant);
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
          _buildSection(
            'Basic Information',
            [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Tenant Name',
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) => InputValidators.validateRequired(
                  value,
                  'Name',
                ),
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
                validator: InputValidators.validatePhone,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: InputValidators.validateEmail,
              ),
            ],
          ),
          SizedBox(height: 24),

          // Lease Information
          _buildSection(
            'Lease Information',
            [
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: InputDecoration(
                  labelText: 'Category',
                  prefixIcon: Icon(Icons.category),
                ),
                items: ['Family', 'Company', 'Student']
                    .map((category) => DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() => _selectedCategory = value!);
                },
              ),
              SizedBox(height: 16),
              InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _leaseStartDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(Duration(days: 365 * 2)),
                  );
                  if (date != null) {
                    setState(() => _leaseStartDate = date);
                  }
                },
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Lease Start Date',
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    DateFormat('MMM dd, yyyy').format(_leaseStartDate),
                  ),
                ),
              ),
              SizedBox(height: 16),
              InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _leaseEndDate,
                    firstDate: _leaseStartDate,
                    lastDate: _leaseStartDate.add(Duration(days: 365 * 2)),
                  );
                  if (date != null) {
                    setState(() => _leaseEndDate = date);
                  }
                },
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Lease End Date',
                    prefixIcon: Icon(Icons.event),
                  ),
                  child: Text(
                    DateFormat('MMM dd, yyyy').format(_leaseEndDate),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 24),

          // Payment Information
          _buildSection(
            'Payment Information',
            [
              SwitchListTile(
                title: Text('Advance Paid'),
                value: _advancePaid,
                onChanged: (value) {
                  setState(() => _advancePaid = value);
                },
              ),
              if (_advancePaid) ...[
                SizedBox(height: 16),
                TextFormField(
                  controller: _advanceController,
                  decoration: InputDecoration(
                    labelText: 'Advance Amount',
                    prefixIcon: Icon(Icons.money),
                    prefixText: '₹',
                  ),
                  keyboardType: TextInputType.number,
                  validator:
                      _advancePaid ? InputValidators.validateAmount : null,
                ),
              ],
            ],
          ),
          SizedBox(height: 32),

          ElevatedButton(
            onPressed: _submitForm,
            child: Text('Save Tenant'),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
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

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _advanceController.dispose();
    super.dispose();
  }
}
