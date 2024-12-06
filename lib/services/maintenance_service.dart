class MaintenanceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<void> createRequest(MaintenanceRequest request) async {
    final docRef =
        await _firestore.collection('maintenance').add(request.toMap());

    // Upload images
    List<String> imageUrls = [];
    for (var image in request.images) {
      final ref =
          _storage.ref().child('maintenance/${docRef.id}/${DateTime.now()}');
      await ref.putFile(File(image.path));
      imageUrls.add(await ref.getDownloadURL());
    }

    // Update request with image URLs
    await docRef.update({'imageUrls': imageUrls});
  }

  Stream<List<MaintenanceRequest>> getRequests(String propertyId) {
    return _firestore
        .collection('maintenance')
        .where('propertyId', isEqualTo: propertyId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MaintenanceRequest.fromMap(doc.data(), doc.id))
            .toList());
  }
}
