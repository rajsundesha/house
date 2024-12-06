import 'package:cloud_firestore/cloud_firestore.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<QuerySnapshot> getMessages(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String content,
    String? type = 'text',
  }) async {
    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add({
      'senderId': senderId,
      'content': content,
      'type': type,
      'timestamp': FieldValue.serverTimestamp(),
      'read': false,
    });

    await _firestore.collection('chats').doc(chatId).set({
      'lastMessage': content,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'lastSenderId': senderId,
    }, SetOptions(merge: true));
  }

  Future<String> createChat({
    required String user1Id,
    required String user2Id,
    String? propertyId,
  }) async {
    final chatDoc = await _firestore.collection('chats').add({
      'participants': [user1Id, user2Id],
      'propertyId': propertyId,
      'createdAt': FieldValue.serverTimestamp(),
      'active': true,
    });

    return chatDoc.id;
  }
}
