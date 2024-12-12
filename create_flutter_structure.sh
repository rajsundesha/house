#!/bin/bash

# Create main directories
mkdir -p lib/{models,providers,routes,screens/{admin/{property_management,tenant_management,user_management},auth,manager},services,theme,utils,widgets}

# Create model files
touch lib/models/{payment,property,tenant,user}.dart

# Create provider files
touch lib/providers/{payment,property,tenant,user}_provider.dart

# Create routes file
touch lib/routes/app_routes.dart

# Create admin screen files
touch lib/screens/admin/property_management/{add_property_screen,property_detail_screen,property_list_screen}.dart
touch lib/screens/admin/tenant_management/{add_tenant_screen,tenant_detail_screen,tenant_list_screen}.dart
touch lib/screens/admin/user_management/{add_user_screen,user_list_screen}.dart
touch lib/screens/admin/admin_dashboard.dart

# Create auth screen files
touch lib/screens/auth/{login_screen,otp_verification_screen,phone_number_screen,registration_screen}.dart

# Create manager screen files
touch lib/screens/manager/{assigned_properties_screen,AssignManagerScreen,manager_dashboard,payment_detail_screen,payment_list_screen,record_payment_screen,tenant_list_screen}.dart

# Create service files
touch lib/services/{auth_service,firebase_service,phone_auth_service,storage_service}.dart

# Create utils files
touch lib/utils/{constants,currency_utils,helpers}.dart

# Create widget files
touch lib/widgets/{custom_app_bar,payment_tile,property_tile,tenant_tile}.dart

# Create root files
touch lib/{firebase_options,main}.dart

echo "Directory structure and files created successfully!"

# Make the script executable
chmod +x ./create_flutter_structure.sh