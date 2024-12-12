
import 'package:flutter/material.dart';
import 'package:house_rental_app/data/models/property.dart';
import 'package:house_rental_app/data/models/tenant.dart';
import 'package:house_rental_app/presentation/shared/widgets/dialog_components.dart';
import 'package:house_rental_app/presentation/shared/widgets/loading_overlay.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:house_rental_app/presentation/providers/tenant_provider.dart';
import 'package:house_rental_app/presentation/providers/property_provider.dart';
// import 'package:house_rental_app/presentation/shared/widgets/custom_components.dart';
import 'package:intl/intl.dart';

class CalendarEvent {
  final String id;
  final String title;
  final String description;
  final DateTime date;
  final String type; // 'lease_expiry', 'payment_due', 'maintenance', etc.
  final String? propertyId;
  final String? tenantId;
  final bool isCompleted;

  CalendarEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.type,
    this.propertyId,
    this.tenantId,
    this.isCompleted = false,
  });

  factory CalendarEvent.fromMap(Map<String, dynamic> map, String id) {
    return CalendarEvent(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      date: (map['date'] as Timestamp).toDate(),
      type: map['type'] ?? '',
      propertyId: map['propertyId'],
      tenantId: map['tenantId'],
      isCompleted: map['isCompleted'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'date': Timestamp.fromDate(date),
      'type': type,
      'propertyId': propertyId,
      'tenantId': tenantId,
      'isCompleted': isCompleted,
    };
  }
}

class CalendarScreen extends StatefulWidget {
  @override
  _CalendarScreenState createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  bool _isLoading = false;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<CalendarEvent>> _events = {};
  final _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadEvents();
  }

 Future<void> _loadEvents() async {
  setState(() => _isLoading = true);
  try {
    final tenantProvider = Provider.of<TenantProvider>(context, listen: false);
    final propertyProvider = Provider.of<PropertyProvider>(context, listen: false);
    
    // Now this will work correctly
    List<Tenant> tenants = await tenantProvider.fetchTenants();
    await propertyProvider.fetchProperties();
    List<Property> properties = propertyProvider.properties;


      // Create events map
      _events = {};

      // Add lease expiry events
      for (var tenant in tenants) {
        Property? property = properties.firstWhere(
          (p) => p.id == tenant.propertyId,
          orElse: () =>
              throw Exception('Property not found for tenant ${tenant.id}'),
        );

        final leaseExpiryEvent = CalendarEvent(
          id: 'lease_${tenant.id}',
          title: 'Lease Expiry',
          description:
              'Lease expires for ${tenant.name} at ${property.address}',
          date: tenant.leaseEndDate,
          type: 'lease_expiry',
          propertyId: tenant.propertyId,
          tenantId: tenant.id,
        );

        final eventDate = DateTime(
          tenant.leaseEndDate.year,
          tenant.leaseEndDate.month,
          tenant.leaseEndDate.day,
        );

        if (_events[eventDate] == null) {
          _events[eventDate] = [];
        }
        _events[eventDate]!.add(leaseExpiryEvent);

        // Add reminder 30 days before
        final reminderDate = DateTime(
          tenant.leaseEndDate.year,
          tenant.leaseEndDate.month,
          tenant.leaseEndDate.day,
        ).subtract(Duration(days: 30));

        final reminderEvent = CalendarEvent(
          id: 'reminder_${tenant.id}',
          title: 'Lease Expiry Reminder',
          description:
              'Lease will expire in 30 days for ${tenant.name} at ${property.address}',
          date: reminderDate,
          type: 'lease_reminder',
          propertyId: tenant.propertyId,
          tenantId: tenant.id,
        );

        if (_events[reminderDate] == null) {
          _events[reminderDate] = [];
        }
        _events[reminderDate]!.add(reminderEvent);
      }

      // Load custom events from Firestore
      final eventsSnapshot =
          await _firestore.collection('calendar_events').get();
      for (var doc in eventsSnapshot.docs) {
        final event = CalendarEvent.fromMap(doc.data(), doc.id);
        final eventDate = DateTime(
          event.date.year,
          event.date.month,
          event.date.day,
        );

        if (_events[eventDate] == null) {
          _events[eventDate] = [];
        }
        _events[eventDate]!.add(event);
      }
    } catch (e) {
      showErrorDialog(context, 'Error loading events: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _addEvent() async {
    final newEvent = await showDialog<CalendarEvent>(
      context: context,
      builder: (context) => AddEventDialog(selectedDate: _selectedDay!),
    );

    if (newEvent != null) {
      setState(() => _isLoading = true);
      try {
        final docRef = await _firestore.collection('calendar_events').add(
          newEvent.toMap(),
        );

        final eventDate = DateTime(
          newEvent.date.year,
          newEvent.date.month,
          newEvent.date.day,
        );

        setState(() {
          if (_events[eventDate] == null) {
            _events[eventDate] = [];
          }
          _events[eventDate]!.add(
            CalendarEvent.fromMap(newEvent.toMap(), docRef.id),
          );
        });
      } catch (e) {
        showErrorDialog(context, 'Error adding event: $e');
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  List<CalendarEvent> _getEventsForDay(DateTime day) {
    return _events[day] ?? [];
  }

  Color _getEventColor(String type) {
    switch (type) {
      case 'lease_expiry':
        return Colors.red;
      case 'lease_reminder':
        return Colors.orange;
      case 'payment_due':
        return Colors.green;
      case 'maintenance':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Calendar'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadEvents,
          ),
        ],
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: Column(
          children: [
            TableCalendar(
              firstDay: DateTime.now().subtract(Duration(days: 365)),
              lastDay: DateTime.now().add(Duration(days: 365)),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              eventLoader: _getEventsForDay,
              calendarFormat: CalendarFormat.month,
              startingDayOfWeek: StartingDayOfWeek.monday,
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
              calendarStyle: CalendarStyle(
                markersMaxCount: 3,
                markerDecoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Expanded(
              child: _selectedDay == null
                  ? Center(child: Text('Select a day'))
                  : ListView(
                      padding: EdgeInsets.all(16),
                      children: _getEventsForDay(_selectedDay!)
                          .map((event) => Card(
                                margin: EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  leading: Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: _getEventColor(event.type),
                                    ),
                                  ),
                                  title: Text(event.title),
                                  subtitle: Text(event.description),
                                  trailing: event.type == 'lease_expiry' ||
                                          event.type == 'lease_reminder'
                                      ? IconButton(
                                          icon: Icon(Icons.arrow_forward),
                                          onPressed: () {
                                            // Navigate to tenant details
                                            Navigator.pushNamed(
                                              context,
                                              '/tenant_detail',
                                              arguments: event.tenantId,
                                            );
                                          },
                                        )
                                      : null,
                                ),
                              ))
                          .toList(),
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _selectedDay == null ? null : _addEvent,
        child: Icon(Icons.add),
      ),
    );
  }
}

class AddEventDialog extends StatefulWidget {
  final DateTime selectedDate;

  AddEventDialog({required this.selectedDate});

  @override
  _AddEventDialogState createState() => _AddEventDialogState();
}

class _AddEventDialogState extends State<AddEventDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _eventType = 'maintenance';
  DateTime? _selectedTime;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Add Event'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _eventType,
                decoration: InputDecoration(
                  labelText: 'Event Type',
                  border: OutlineInputBorder(),
                ),
                items: [
                  DropdownMenuItem(
                    value: 'maintenance',
                    child: Text('Maintenance'),
                  ),
                  DropdownMenuItem(
                    value: 'payment_due',
                    child: Text('Payment Due'),
                  ),
                  DropdownMenuItem(
                    value: 'other',
                    child: Text('Other'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _eventType = value);
                  }
                },
              ),
              SizedBox(height: 16),
              ListTile(
                title: Text('Time'),
                subtitle: Text(_selectedTime == null
                    ? 'Select time'
                    : DateFormat.Hm().format(_selectedTime!)),
                trailing: Icon(Icons.access_time),
                onTap: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );
                  if (time != null) {
                    setState(() {
                      _selectedTime = DateTime(
                        widget.selectedDate.year,
                        widget.selectedDate.month,
                        widget.selectedDate.day,
                        time.hour,
                        time.minute,
                      );
                    });
                  }
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('CANCEL'),
        ),
        TextButton(
          onPressed: () {
            if (_formKey.currentState?.validate() ?? false) {
              final event = CalendarEvent(
                id: '',
                title: _titleController.text,
                description: _descriptionController.text,
                date: _selectedTime ?? widget.selectedDate,
                type: _eventType,
              );
              Navigator.pop(context, event);
            }
          },
          child: Text('ADD'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
