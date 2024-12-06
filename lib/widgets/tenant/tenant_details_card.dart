import 'package:flutter/material.dart';
import 'package:house_rental_app/utils/string_utils.dart';
import 'package:intl/intl.dart';
import '../../models/tenant.dart';
import '../../utils/date_utils.dart';

class TenantDetailsCard extends StatelessWidget {
  final Tenant tenant;
  final VoidCallback? onEdit;

  const TenantDetailsCard({
    Key? key,
    required this.tenant,
    this.onEdit,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isLeaseEnding = DateUtils.isLeaseEnding(tenant.leaseEndDate);
    final bool isLeaseExpired = DateUtils.isLeaseExpired(tenant.leaseEndDate);

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  child: Text(
                    StringUtils.getInitials(tenant.name),
                    style: TextStyle(fontSize: 20),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tenant.name,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(
                        tenant.category,
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                if (onEdit != null)
                  IconButton(
                    icon: Icon(Icons.edit),
                    onPressed: onEdit,
                  ),
              ],
            ),
            Divider(height: 32),

            // Contact Information
            _buildSection(
              context,
              'Contact Information',
              [
                _buildInfoRow(
                  'Phone',
                  tenant.contactInfo['phone'] ?? 'N/A',
                  Icons.phone,
                ),
                _buildInfoRow(
                  'Email',
                  tenant.contactInfo['email'] ?? 'N/A',
                  Icons.email,
                ),
              ],
            ),
            SizedBox(height: 16),

            // Lease Information
            _buildSection(
              context,
              'Lease Details',
              [
                _buildInfoRow(
                  'Start Date',
                  DateFormat('MMM dd, yyyy').format(tenant.leaseStartDate),
                  Icons.calendar_today,
                ),
                _buildInfoRow(
                  'End Date',
                  DateFormat('MMM dd, yyyy').format(tenant.leaseEndDate),
                  Icons.event,
                  isAlert: isLeaseEnding || isLeaseExpired,
                ),
                if (isLeaseEnding || isLeaseExpired)
                  Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isLeaseExpired
                            ? Colors.red.withOpacity(0.1)
                            : Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        isLeaseExpired ? 'Lease Expired' : 'Lease ending soon',
                        style: TextStyle(
                          color: isLeaseExpired ? Colors.red : Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 16),

            // Payment Information
            _buildSection(
              context,
              'Payment Details',
              [
                _buildInfoRow(
                  'Advance Paid',
                  tenant.advancePaid ? 'Yes' : 'No',
                  Icons.check_circle,
                ),
                if (tenant.advancePaid)
                  _buildInfoRow(
                    'Advance Amount',
                    '₹${tenant.advanceAmount}',
                    Icons.money,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    List<Widget> children,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildInfoRow(
    String label,
    String value,
    IconData icon, {
    bool isAlert = false,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: isAlert ? Colors.orange : Colors.grey,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Column(
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
                    color: isAlert ? Colors.orange : null,
                    fontWeight: isAlert ? FontWeight.bold : null,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
