// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:house_rental_app/presentation/providers/property_provider.dart';
// import 'package:house_rental_app/presentation/providers/user_provider.dart';
// import 'package:house_rental_app/presentation/providers/tenant_provider.dart';
// import 'package:house_rental_app/data/models/property.dart';
// import 'package:house_rental_app/data/models/tenant.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';

// class PropertySetupWizardScreen extends StatefulWidget {
//   @override
//   _PropertySetupWizardScreenState createState() =>
//       _PropertySetupWizardScreenState();
// }

// class _PropertySetupWizardScreenState extends State<PropertySetupWizardScreen> {
//   int _currentStep = 0;

//   // Property info controllers
//   final _addressController = TextEditingController();
//   final _rentAmountController = TextEditingController();
//   final _sizeController = TextEditingController();
//   String _status = 'vacant';
//   // Additional property fields if needed

//   // Manager assignment
//   List<Map<String, dynamic>> _managers = [];
//   String? _selectedManagerId;
//   bool _isLoadingManagers = false;

//   // Tenant addition (optional)
//   bool _addTenantNow = false;
//   final _tenantNameController = TextEditingController();
//   final _tenantPhoneController = TextEditingController();
//   final _tenantEmailController = TextEditingController();
//   final _tenantCategory = 'Family';
//   DateTime _leaseStartDate = DateTime.now();
//   DateTime _leaseEndDate = DateTime.now().add(Duration(days: 365));
//   bool _advancePaid = false;
//   final _advanceAmountController = TextEditingController();
//   final _rentAdjustmentController = TextEditingController();

//   @override
//   void initState() {
//     super.initState();
//     _fetchManagers();
//   }

//   Future<void> _fetchManagers() async {
//     setState(() => _isLoadingManagers = true);
//     try {
//       final userProvider = Provider.of<UserProvider>(context, listen: false);
//       final mgrs = await userProvider.fetchUsersByRole('manager');
//       _managers = mgrs
//           .map((m) => {
//                 'id': m.uid,
//                 'name': m.name,
//                 'email': m.contactInfo['email'] ?? ''
//               })
//           .toList();
//     } catch (e) {
//       print('Error fetching managers: $e');
//     } finally {
//       setState(() => _isLoadingManagers = false);
//     }
//   }

//   Future<void> _selectLeaseStartDate() async {
//     DateTime? picked = await showDatePicker(
//       context: context,
//       initialDate: _leaseStartDate,
//       firstDate: DateTime(2000),
//       lastDate: DateTime(2100),
//     );
//     if (picked != null) {
//       setState(() {
//         _leaseStartDate = picked;
//         if (_leaseEndDate.isBefore(_leaseStartDate)) {
//           _leaseEndDate = _leaseStartDate.add(Duration(days: 365));
//         }
//       });
//     }
//   }

//   Future<void> _selectLeaseEndDate() async {
//     DateTime? picked = await showDatePicker(
//       context: context,
//       initialDate: _leaseEndDate,
//       firstDate: _leaseStartDate,
//       lastDate: DateTime(2100),
//     );
//     if (picked != null) {
//       setState(() {
//         _leaseEndDate = picked;
//       });
//     }
//   }

//   Future<void> _finishSetup() async {
//     // Validate property data
//     if (_addressController.text.trim().isEmpty ||
//         _rentAmountController.text.trim().isEmpty ||
//         double.tryParse(_rentAmountController.text.trim()) == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Please enter valid property details.')));
//       return;
//     }
//     if (_selectedManagerId == null) {
//       ScaffoldMessenger.of(context)
//           .showSnackBar(SnackBar(content: Text('Please select a manager.')));
//       return;
//     }

//     final propertyProvider =
//         Provider.of<PropertyProvider>(context, listen: false);
//     final tenantProvider = Provider.of<TenantProvider>(context, listen: false);

//     double rentAmount = double.parse(_rentAmountController.text.trim());
//     final property = Property(
//       id: '',
//       address: _addressController.text.trim(),
//       rentAmount: rentAmount,
//       status: _status,
//       size: _sizeController.text.trim(),
//       assignedManagerId: null,
//       createdAt: DateTime.now(),
//       updatedAt: DateTime.now(),
//       // add other fields default if needed
//       bedrooms: 0,
//       bathrooms: 0,
//       furnished: false,
//       parking: false,
//       amenities: [],
//     );

//     // Add property
//     await propertyProvider.addProperty(property);
//     if (propertyProvider.error != null) {
//       ScaffoldMessenger.of(context).showSnackBar(SnackBar(
//           content: Text('Error adding property: ${propertyProvider.error}')));
//       return;
//     }

//     // Assign manager
//     await propertyProvider.assignManager(property.id, _selectedManagerId!);
//     if (propertyProvider.error != null) {
//       ScaffoldMessenger.of(context).showSnackBar(SnackBar(
//           content: Text('Error assigning manager: ${propertyProvider.error}')));
//       return;
//     }

//     if (_addTenantNow) {
//       if (_tenantNameController.text.trim().isEmpty ||
//           _tenantPhoneController.text.trim().isEmpty) {
//         ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(content: Text('Please enter tenant details or skip.')));
//         return;
//       }

//       double advanceAmt = 0;
//       if (_advancePaid && _advanceAmountController.text.trim().isNotEmpty) {
//         advanceAmt =
//             double.tryParse(_advanceAmountController.text.trim()) ?? 0.0;
//       }

//       double rentAdjustment = 0.0;
//       if (_rentAdjustmentController.text.trim().isNotEmpty) {
//         rentAdjustment =
//             double.tryParse(_rentAdjustmentController.text.trim()) ?? 0.0;
//       }

//       final tenant = Tenant(
//         id: '',
//         propertyId: property.id,
//         name: _tenantNameController.text.trim(),
//         contactInfo: {
//           'phone': _tenantPhoneController.text.trim(),
//           'email': _tenantEmailController.text.trim()
//         },
//         category: _tenantCategory,
//         leaseStartDate: _leaseStartDate,
//         leaseEndDate: _leaseEndDate,
//         advancePaid: _advancePaid,
//         advanceAmount: advanceAmt,
//         rentAdjustment: rentAdjustment,
//       );

//       await tenantProvider.addTenant(tenant);
//       if (tenantProvider.error != null) {
//         ScaffoldMessenger.of(context).showSnackBar(SnackBar(
//             content: Text('Error adding tenant: ${tenantProvider.error}')));
//         return;
//       }

//       // Update property status to occupied
//       await propertyProvider.updatePropertyStatus(property.id, 'occupied');
//     }

//     ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Property setup completed successfully!')));
//     Navigator.pop(context);
//   }

//   List<Step> get _steps => [
//         Step(
//           title: Text('Property Details'),
//           content: Column(
//             children: [
//               TextFormField(
//                 controller: _addressController,
//                 decoration: InputDecoration(labelText: 'Address'),
//               ),
//               SizedBox(height: 16),
//               TextFormField(
//                 controller: _rentAmountController,
//                 decoration: InputDecoration(labelText: 'Rent Amount'),
//                 keyboardType: TextInputType.number,
//               ),
//               SizedBox(height: 16),
//               TextFormField(
//                 controller: _sizeController,
//                 decoration: InputDecoration(labelText: 'Size (sq ft)'),
//               ),
//               // Add more fields if needed
//             ],
//           ),
//           isActive: _currentStep == 0,
//           state: _currentStep > 0 ? StepState.complete : StepState.indexed,
//         ),
//         Step(
//           title: Text('Assign Manager'),
//           content: _isLoadingManagers
//               ? Center(child: CircularProgressIndicator())
//               : Column(
//                   children: [
//                     if (_managers.isEmpty) Text('No managers available'),
//                     ..._managers
//                         .map((m) => RadioListTile<String>(
//                               title: Text(m['name']),
//                               subtitle: Text(m['email']),
//                               value: m['id'],
//                               groupValue: _selectedManagerId,
//                               onChanged: (val) =>
//                                   setState(() => _selectedManagerId = val),
//                             ))
//                         .toList()
//                   ],
//                 ),
//           isActive: _currentStep == 1,
//           state: _currentStep > 1 ? StepState.complete : StepState.indexed,
//         ),
//         Step(
//           title: Text('Add Tenant (Optional)'),
//           content: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               SwitchListTile(
//                 title: Text('Add a tenant now?'),
//                 value: _addTenantNow,
//                 onChanged: (val) => setState(() => _addTenantNow = val),
//               ),
//               if (_addTenantNow)
//                 Column(
//                   children: [
//                     TextFormField(
//                       controller: _tenantNameController,
//                       decoration: InputDecoration(labelText: 'Tenant Name'),
//                     ),
//                     SizedBox(height: 16),
//                     TextFormField(
//                       controller: _tenantPhoneController,
//                       decoration: InputDecoration(labelText: 'Phone'),
//                       keyboardType: TextInputType.phone,
//                     ),
//                     SizedBox(height: 16),
//                     TextFormField(
//                       controller: _tenantEmailController,
//                       decoration: InputDecoration(labelText: 'Email'),
//                     ),
//                     SizedBox(height: 16),
//                     Row(
//                       children: [
//                         Expanded(
//                           child: InkWell(
//                             onTap: _selectLeaseStartDate,
//                             child: InputDecorator(
//                               decoration: InputDecoration(
//                                 labelText: 'Lease Start Date',
//                                 border: OutlineInputBorder(),
//                               ),
//                               child: Text(
//                                 '${_leaseStartDate.toLocal()}'.split(' ')[0],
//                               ),
//                             ),
//                           ),
//                         ),
//                         SizedBox(width: 16),
//                         Expanded(
//                           child: InkWell(
//                             onTap: _selectLeaseEndDate,
//                             child: InputDecorator(
//                               decoration: InputDecoration(
//                                 labelText: 'Lease End Date',
//                                 border: OutlineInputBorder(),
//                               ),
//                               child: Text(
//                                 '${_leaseEndDate.toLocal()}'.split(' ')[0],
//                               ),
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                     SizedBox(height: 16),
//                     SwitchListTile(
//                       title: Text('Advance Paid?'),
//                       value: _advancePaid,
//                       onChanged: (val) => setState(() => _advancePaid = val),
//                     ),
//                     if (_advancePaid)
//                       TextFormField(
//                         controller: _advanceAmountController,
//                         decoration:
//                             InputDecoration(labelText: 'Advance Amount'),
//                         keyboardType: TextInputType.number,
//                       ),
//                     SizedBox(height: 16),
//                     TextFormField(
//                       controller: _rentAdjustmentController,
//                       decoration: InputDecoration(
//                           labelText: 'Rent Adjustment (if any)'),
//                       keyboardType: TextInputType.number,
//                     ),
//                   ],
//                 )
//             ],
//           ),
//           isActive: _currentStep == 2,
//           state: StepState.indexed,
//         ),
//       ];

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Property Setup Wizard'),
//       ),
//       body: Stepper(
//         steps: _steps,
//         currentStep: _currentStep,
//         onStepContinue: () {
//           if (_currentStep < _steps.length - 1) {
//             setState(() => _currentStep += 1);
//           } else {
//             // Finish
//             _finishSetup();
//           }
//         },
//         onStepCancel: () {
//           if (_currentStep > 0) {
//             setState(() => _currentStep -= 1);
//           } else {
//             Navigator.pop(context);
//           }
//         },
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     _addressController.dispose();
//     _rentAmountController.dispose();
//     _sizeController.dispose();
//     _tenantNameController.dispose();
//     _tenantPhoneController.dispose();
//     _tenantEmailController.dispose();
//     _advanceAmountController.dispose();
//     _rentAdjustmentController.dispose();
//     super.dispose();
//   }
// }
