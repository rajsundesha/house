class MaintenanceRequestForm extends StatefulWidget {
  @override
  _MaintenanceRequestFormState createState() => _MaintenanceRequestFormState();
}

class _MaintenanceRequestFormState extends State<MaintenanceRequestForm> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  late String _priority;
  late String _category;
  List<XFile> _images = [];

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          DropdownButtonFormField<String>(
            value: _category,
            decoration: InputDecoration(labelText: 'Category'),
            items: [
              'Plumbing',
              'Electrical',
              'HVAC',
              'Structural',
              'Other',
            ]
                .map((category) => DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    ))
                .toList(),
            onChanged: (value) => setState(() => _category = value!),
          ),
          TextFormField(
            controller: _descriptionController,
            decoration: InputDecoration(
              labelText: 'Description',
              hintText: 'Describe the issue...',
            ),
            maxLines: 3,
          ),
          ImagePickerGrid(
            images: _images,
            onImagesChanged: (images) => setState(() => _images = images),
          ),
          PrioritySelector(
            priority: _priority,
            onChanged: (value) => setState(() => _priority = value),
          ),
        ],
      ),
    );
  }
}
