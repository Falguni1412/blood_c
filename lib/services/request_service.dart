import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:blood_c/models/request_model.dart';

class RequestService {
  final CollectionReference _requestsCollection = FirebaseFirestore.instance
      .collection('blood_requests');

  // Create a new request
  Future<void> createRequest(RequestModel request) async {
    await _requestsCollection.add(request.toMap());
  }

  Stream<List<RequestModel>> getLiveRequests({String? bloodGroup}) {
    Query query = _requestsCollection.where('status', isEqualTo: 'pending');
    if (bloodGroup != null && bloodGroup != 'All') {
      query = query.where('bloodGroup', isEqualTo: bloodGroup);
    }
    return query
        .snapshots() // Removed orderBy to avoid requiring composite index
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return RequestModel.fromMap(
              doc.id,
              doc.data() as Map<String, dynamic>,
            );
          }).toList();
        });
  }

  Stream<List<RequestModel>> getMyRequests(String userId) {
    return _requestsCollection
        .where('senderId', isEqualTo: userId)
        .snapshots() // Removed orderBy to avoid requiring composite index
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return RequestModel.fromMap(
              doc.id,
              doc.data() as Map<String, dynamic>,
            );
          }).toList();
        });
  }

  // Accept a request
  Future<void> acceptRequest(String requestId, String userId) async {
    await _requestsCollection.doc(requestId).update({
      'status': 'accepted',
      'acceptedBy': userId,
    });
  }

  // Delete a request
  Future<void> deleteRequest(String requestId) async {
    await _requestsCollection.doc(requestId).delete();
  }

  Stream<List<RequestModel>> getDonationHistory(String userId) {
    return _requestsCollection
        .where('acceptedBy', isEqualTo: userId)
        .where('status', isEqualTo: 'accepted')
        .snapshots() // Removed orderBy to avoid requiring composite index
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return RequestModel.fromMap(
              doc.id,
              doc.data() as Map<String, dynamic>,
            );
          }).toList();
        });
  }
}
