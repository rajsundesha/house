// class NotificationSettingsScreen extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text('Notifications')),
//       body: ListView(
//         children: [
//           NotificationCategory(
//             title: 'Payment Notifications',
//             settings: [
//               NotificationSetting(
//                 title: 'Payment Due Reminders',
//                 description: 'Get notified when payments are due',
//                 value: true,
//               ),
//               NotificationSetting(
//                 title: 'Payment Received',
//                 description: 'Get notified when payments are received',
//                 value: true,
//               ),
//             ],
//           ),
//           NotificationCategory(
//             title: 'Lease Notifications',
//             settings: [
//               NotificationSetting(
//                 title: 'Lease Expiry',
//                 description: 'Get notified when leases are about to expire',
//                 value: true,
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
// }
