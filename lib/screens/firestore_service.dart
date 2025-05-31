import 'package:cloud_firestore/cloud_firestore.dart';

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
  Future<bool> verifyCustomerSignIn(String uniqueID, String name) async {
    try {
      DocumentSnapshot docSnapshot = await _db.collection('Customers').doc(uniqueID).get();

      if (docSnapshot.exists) {
        String storedName = docSnapshot['name'];
        return storedName == name; // Compare the stored name with the entered name
      } else {
        return false; // Profile not found
      }
    } catch (e) {
      print('Error verifying customer profile: $e');
      throw Exception('Error verifying customer profile: $e');
    }
  }

  // Method to verify the farmer sign-in using unique ID and name
  Future<bool> verifyFarmerSignIn(String uniqueID, String name) async {
    try {
      DocumentSnapshot docSnapshot = await _db.collection('Farmers').doc(uniqueID).get();

      if (docSnapshot.exists) {
        String storedName = docSnapshot['name'];
        return storedName == name; // Compare the stored name with the entered name
      } else {
        return false; // Profile not found
      }
    } catch (e) {
      print('Error verifying farmer profile: $e');
      throw Exception('Error verifying farmer profile: $e');
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
