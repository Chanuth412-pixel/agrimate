import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  ///Create farmer profile with optional GPS (position)
  Future<void> createFarmerProfile(
    String uid,
    String name,
    String location,
    String phone,
    String email, {
    double? latitude,
    double? longitude,
  }) async {
    try {
      final data = {
        'uid': uid,
        'name': name,
        'location': location,
        'phone': phone,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
      };

      if (latitude != null && longitude != null) {
        data['position'] = GeoPoint(latitude, longitude);
      }

      await _db.collection('farmers').doc(uid).set(data);
    } catch (e) {
      print('Error creating farmer profile: $e');
      throw Exception('Error creating farmer profile: $e');
    }
  }

  ///Create customer profile and return the document ID
  Future<String> createCustomerProfile(
    String name,
    String location,
    String phone,
    List<String> preferredCrops,
  ) async {
    try {
      DocumentReference docRef = await _db.collection('Customers').add({
        'name': name,
        'location': location,
        'phone': phone,
        'preferredCrops': preferredCrops,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return docRef.id;
    } catch (e) {
      print('Error creating customer profile: $e');
      throw Exception('Error creating customer profile: $e');
    }
  }

  /// Save customer login location (GeoPoint)
  Future<void> saveLoginLocation(String email, double lat, double lon) async {
    try {
      await _db.collection('customer_locations').doc(email).set({
        'latitude': lat,
        'longitude': lon,
        'position': GeoPoint(lat, lon),
        'timestamp': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error saving login location: $e');
      throw Exception('Error saving login location: $e');
    }
  }

  /// Fetch customer profile by ID
  Future<Map<String, dynamic>?> getCustomerProfile(String customerId) async {
    try {
      DocumentSnapshot doc = await _db.collection('Customers').doc(customerId).get();
      return doc.exists ? doc.data() as Map<String, dynamic> : null;
    } catch (e) {
      print('Error fetching customer profile: $e');
      return null;
    }
  }

  /// Fetch farmer profile by ID
  Future<Map<String, dynamic>?> getFarmerProfile(String farmerId) async {
    try {
      DocumentSnapshot doc = await _db.collection('farmers').doc(farmerId).get();
      return doc.exists ? doc.data() as Map<String, dynamic> : null;
    } catch (e) {
      print('Error fetching farmer profile: $e');
      return null;
    }
  }

  /// Verify customer by ID and name
  Future<bool> verifyCustomerSignIn(String uniqueID, String name) async {
    try {
      DocumentSnapshot doc = await _db.collection('Customers').doc(uniqueID).get();
      return doc.exists && doc['name'] == name;
    } catch (e) {
      print('Error verifying customer profile: $e');
      throw Exception('Error verifying customer profile: $e');
    }
  }

  /// Verify farmer by ID and name
  Future<bool> verifyFarmerSignIn(String uniqueID, String name) async {
    try {
      DocumentSnapshot doc = await _db.collection('farmers').doc(uniqueID).get();
      return doc.exists && doc['name'] == name;
    } catch (e) {
      print('Error verifying farmer profile: $e');
      throw Exception('Error verifying farmer profile: $e');
    }
  }

  /// Query farmers by location and crops (optional)
  Future<QuerySnapshot> getFarmersForCustomer(String location, List<String> preferredCrops) async {
    Query query = _db.collection('farmers').where('location', isEqualTo: location);

    if (preferredCrops.isNotEmpty) {
      query = query.where('crops', arrayContainsAny: preferredCrops);
    }

    return await query.get();
  }

  /// Simple pagination
  Future<QuerySnapshot> getFarmersPaginated(int pageSize) async {
    return await _db.collection('farmers').limit(pageSize).get();
  }

  /// Paginated with startAfter
  Future<QuerySnapshot> getFarmersPaginatedWithStartAfter(
    int pageSize,
    DocumentSnapshot? lastVisible,
  ) async {
    Query query = _db.collection('farmers').limit(pageSize);
    if (lastVisible != null) {
      query = query.startAfterDocument(lastVisible);
    }
    return await query.get();
  }
}

