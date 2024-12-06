import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/tenant.dart';
import '../providers/tenant_provider.dart';

class AddTenantScreen extends ConsumerStatefulWidget {
  const AddTenantScreen({super.key});

  @override
  ConsumerState<AddTenantScreen> createState() => _AddTenantScreenState();
}

class _AddTenantScreenState extends ConsumerState<AddTenantScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _idNumberController = TextEditingController();
  DateTime? _dateOfBirth;
  final _emergencyContactController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _idNumberController.dispose();
    _emergencyContactController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState?.validate() ?? false) {
      final tenant = Tenant(
        id: '',
        name: _nameController.text,
        phone: _phoneController.text,
        email: _emailController.text,
        idNumber: _idNumberController.text,
        dateOfBirth: _dateOfBirth,
        emergencyContact: _emergencyContactController.text,
      );

      await ref.read(tenantProvider.notifier).addTenant(tenant);
      if (mounted) Navigator.pop(context);
    }
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      setState(() => _dateOfBirth = date);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Tenant')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Full Name'),
              validator: (value) =>
                  value?.isEmpty ?? true ? 'Please enter tenant name' : null,
            ),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(labelText: 'Phone Number'),
              keyboardType: TextInputType.phone,
              validator: (value) =>
                  value?.isEmpty ?? true ? 'Please enter phone number' : null,
            ),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
              validator: (value) =>
                  value?.isEmpty ?? true ? 'Please enter email' : null,
            ),
            TextFormField(
              controller: _idNumberController,
              decoration: const InputDecoration(labelText: 'ID Number'),
            ),
            ListTile(
              title: const Text('Date of Birth'),
              subtitle: Text(_dateOfBirth?.toString().split(' ')[0] ?? 'Not set'),
              trailing: const Icon(Icons.calendar_today),
              onTap: _selectDate,
            ),
            TextFormField(
              controller: _emergencyContactController,
              decoration: const InputDecoration(labelText: 'Emergency Contact'),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _submitForm,
              child: const Text('Add Tenant'),
            ),
          ],
        ),
      ),
    );
  }
}