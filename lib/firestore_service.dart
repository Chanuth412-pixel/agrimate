/* import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Method to create farmer profile
  Future<void> createFarmerProfile(String name, String location, String phone) async {
    try {
      // Create a new document in the 'farmers' collection with a unique ID
      await _db.collection('Farmers').add({
        'name': name,
        'location': location,
        'phone': phone,
        'createdAt': Timestamp.now(),  // Optionally track when the profile was created
      });
    } catch (e) {
      print('Error creating farmer profile: $e');
      throw Exception('Error creating farmer profile: $e');
    }
  }

  // Method to create customer profile and return the document ID
  Future<String> createCustomerProfile(String name, String location, String phone, List<String> preferredCrops) async {
    try {
      CollectionReference customers = _db.collection('Customers');

      DocumentReference docRef = await customers.add({
        'name': name,
        'location': location,
        'phone': phone,  // Add phone to the customer profile
        'preferredCrops': preferredCrops,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Return the unique document ID
      return docRef.id;  // Customer unique ID
    } catch (e) {
      print('Error creating customer profile: $e');
      throw Exception('Error creating customer profile: $e');
    }
  }

  // Method to fetch customer profile data from Firestore
  Future<Map<String, dynamic>?> getCustomerProfile(String customerId) async {
    try {
      DocumentSnapshot docSnapshot = await _db.collection('Customers').doc(customerId).get();

      if (docSnapshot.exists) {
        // Return customer data as a map
        return docSnapshot.data() as Map<String, dynamic>;
      } else {
        return null; // Customer not found
      }
    } catch (e) {
      print('Error fetching customer profile: $e');
      return null;
    }
  }

  // Method to fetch farmer profile data from Firestore
  Future<Map<String, dynamic>?> getFarmerProfile(String farmerId) async {
    try {
      DocumentSnapshot docSnapshot = await _db.collection('Farmers').doc(farmerId).get();

      if (docSnapshot.exists) {
        // Return farmer data as a map
        return docSnapshot.data() as Map<String, dynamic>;
      } else {
        return null; // Farmer not found
      }
    } catch (e) {
      print('Error fetching farmer profile: $e');
      return null;
    }
  }

  // Method to verify the customer sign-in using unique ID and name
  Future<bool> verifyCustomerSignInByEmailAndPassword(String email, String password) async {
  try {
    final querySnapshot = await _db
        .collection('Customers')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      final doc = querySnapshot.docs.first;
      String storedPassword = doc['password'];
      return storedPassword == password;
    } else {
      return false; // Email not found
    }
  } catch (e) {
    print('Error verifying customer login: $e');
    throw Exception('Error verifying customer login: $e');
  }
}


  // Method to verify the farmer sign-in using unique ID and name
  Future<bool> verifyFarmerSignInByEmailAndPassword(String email, String password) async {
  try {
    // Search for farmer with matching email
    final querySnapshot = await _db
        .collection('Farmers')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      final doc = querySnapshot.docs.first;
      final storedPassword = doc['password'];

      // Check if password matches
      return storedPassword == password;
    } else {
      return false; // Email not found
    }
  } catch (e) {
    print('Error verifying farmer sign-in: $e');
    throw Exception('Error verifying farmer sign-in: $e');
  }
}


  // Method to query farmers for a customer based on location and preferred crops
  Future<QuerySnapshot> getFarmersForCustomer(String location, List<String> preferredCrops) async {
    Query farmersQuery = _db.collection('Farmers')
        .where('location', isEqualTo: location);  // Filter by location

    // If preferred crops are provided, filter by them
    if (preferredCrops.isNotEmpty) {
      // Assuming the 'crops' field is a list of crop names or types
      farmersQuery = farmersQuery.where('crops', arrayContainsAny: preferredCrops);
    }

    return await farmersQuery.get();
  }

  // Method for paginated querying of Farmers
  Future<QuerySnapshot> getFarmersPaginated(int pageSize) async {
    QuerySnapshot snapshot = await _db.collection('Farmers')
        .limit(pageSize)  // Limit to specified number of results per query
        .get();

    return snapshot;
  }

  // Method for paginated querying of Farmers with support for 'startAfter' (to fetch next page)
  Future<QuerySnapshot> getFarmersPaginatedWithStartAfter(int pageSize, DocumentSnapshot? lastVisible) async {
    Query query = _db.collection('Farmers').limit(pageSize);

    if (lastVisible != null) {
      query = query.startAfterDocument(lastVisible);  // Start after the last visible document
    }

    return await query.get();
  }
}
 */


 /* import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance; */

  /// ✅ Create farmer profile with optional GPS location
  /* Future<void> createFarmerProfile(String name, String locationName, String phone,
      {double? latitude, double? longitude}) async {
    try {
      Map<String, dynamic> data = {
        'name': name,
        'location': locationName,
        'phone': phone,
        'createdAt': Timestamp.now(),
      };

      if (latitude != null && longitude != null) {
        data['position'] = GeoPoint(latitude, longitude); // For location-based queries
      }

      await _db.collection('Farmers').add(data);
    } catch (e) {
      print('Error creating farmer profile: $e');
      throw Exception('Error creating farmer profile: $e');
    }
    */

    

    /* // Method to create farmer profile
    Future<void> createFarmerProfile(String name, String location, String phone) async {
    try {
      // Create a new document in the 'farmers' collection with a unique ID
      await _db.collection('Farmers').add({
        'name': name,
        'location': location,
        'phone': phone,
        'createdAt': Timestamp.now(),  // Optionally track when the profile was created
      });
    } catch (e) {
      print('Error creating farmer profile: $e');
      throw Exception('Error creating farmer profile: $e');
      }
    }

  /// ✅ Create customer profile and return the document ID
  Future<String> createCustomerProfile(String name, String location, String phone, List<String> preferredCrops) async {
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

  /// ✅ Save customer login location (to be used for nearby farmer matching)
  Future<void> saveLoginLocation(String email, double lat, double lon) async {
    try {
      await _db.collection('customer_locations').doc(email).set({
        'latitude': lat,
        'longitude': lon,
        'position': GeoPoint(lat, lon),
        'timestamp': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)); // Merge to update if exists
    } catch (e) {
      print('Error saving login location: $e');
      throw Exception('Error saving login location: $e');
    }
  }

  /// Fetch customer profile by document ID
  Future<Map<String, dynamic>?> getCustomerProfile(String customerId) async {
    try {
      DocumentSnapshot docSnapshot = await _db.collection('Customers').doc(customerId).get();

      if (docSnapshot.exists) {
        return docSnapshot.data() as Map<String, dynamic>;
      } else {
        return null;
      }
    } catch (e) {
      print('Error fetching customer profile: $e');
      return null;
    }
  }

  /// Fetch farmer profile by document ID
  Future<Map<String, dynamic>?> getFarmerProfile(String farmerId) async {
    try {
      DocumentSnapshot docSnapshot = await _db.collection('Farmers').doc(farmerId).get();

      if (docSnapshot.exists) {
        return docSnapshot.data() as Map<String, dynamic>;
      } else {
        return null;
      }
    } catch (e) {
      print('Error fetching farmer profile: $e');
      return null;
    }
  }

  /// Verify customer by ID and name
  Future<bool> verifyCustomerSignIn(String uniqueID, String name) async {
    try {
      DocumentSnapshot docSnapshot = await _db.collection('Customers').doc(uniqueID).get();

      if (docSnapshot.exists) {
        return docSnapshot['name'] == name;
      } else {
        return false;
      }
    } catch (e) {
      print('Error verifying customer profile: $e');
      throw Exception('Error verifying customer profile: $e');
    }
  }

  /// Verify farmer by ID and name
  Future<bool> verifyFarmerSignIn(String uniqueID, String name) async {
    try {
      DocumentSnapshot docSnapshot = await _db.collection('Farmers').doc(uniqueID).get();

      if (docSnapshot.exists) {
        return docSnapshot['name'] == name;
      } else {
        return false;
      }
    } catch (e) {
      print('Error verifying farmer profile: $e');
      throw Exception('Error verifying farmer profile: $e');
    }
  }

  /// Get farmers for customer by location name + preferred crops (text match only)
  Future<QuerySnapshot> getFarmersForCustomer(String location, List<String> preferredCrops) async {
    Query query = _db.collection('Farmers').where('location', isEqualTo: location);

    if (preferredCrops.isNotEmpty) {
      query = query.where('crops', arrayContainsAny: preferredCrops);
    }

    return await query.get();
  }

  /// Pagination support (simple version)
  Future<QuerySnapshot> getFarmersPaginated(int pageSize) async {
    return await _db.collection('Farmers').limit(pageSize).get();
  }

  /// Pagination with 'startAfter'
  Future<QuerySnapshot> getFarmersPaginatedWithStartAfter(int pageSize, DocumentSnapshot? lastVisible) async {
    Query query = _db.collection('Farmers').limit(pageSize);
    if (lastVisible != null) {
      query = query.startAfterDocument(lastVisible);
    }
    return await query.get();
  }
} */







import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// ✅ Create farmer profile with optional GPS (position)
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

  /// ✅ Create customer profile and return the document ID
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

  /// ✅ Save customer login location (GeoPoint)
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
