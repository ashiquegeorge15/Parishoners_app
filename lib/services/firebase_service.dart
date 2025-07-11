import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:async';
import 'dart:typed_data';
import '../models/announcement.dart';
import '../models/dues.dart';
import '../models/gallery.dart';
import '../models/user_profile.dart';

class FirebaseService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  static final FirebaseDatabase _realtimeDb = FirebaseDatabase.instance;

  // Authentication Methods
  static User? get currentUser => _auth.currentUser;
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with email and password
  static Future<UserCredential?> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      print('Sign in error: $e');
      return null;
    }
  }

  // Register with email and password
  static Future<UserCredential?> registerWithEmailAndPassword(
      String email, String password) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      print('Registration error: $e');
      return null;
    }
  }

  // Sign out
  static Future<void> signOut() async {
    await _auth.signOut();
  }

  // Firestore Methods

  // Add announcement
  static Future<void> addAnnouncement({
    required String title,
    required String content,
    required String authorId,
  }) async {
    try {
      await _firestore.collection('announcements').add({
        'title': title,
        'content': content,
        'authorId': authorId,
        'timestamp': FieldValue.serverTimestamp(),
        'isActive': true,
      });
    } catch (e) {
      print('Error adding announcement: $e');
    }
  }

  // Get announcements
  static Stream<QuerySnapshot> getAnnouncements() {
    return _firestore
        .collection('announcements')
        .where('isActive', isEqualTo: true)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // Add event
  static Future<void> addEvent({
    required String title,
    required String description,
    required DateTime eventDate,
    required String location,
  }) async {
    try {
      await _firestore.collection('events').add({
        'title': title,
        'description': description,
        'eventDate': Timestamp.fromDate(eventDate),
        'location': location,
        'createdAt': FieldValue.serverTimestamp(),
        'isActive': true,
      });
    } catch (e) {
      print('Error adding event: $e');
    }
  }

  // Get events
  static Stream<QuerySnapshot> getEvents() {
    return _firestore
        .collection('events')
        .where('isActive', isEqualTo: true)
        .orderBy('eventDate', descending: false)
        .snapshots();
  }

  // Add member
  static Future<void> addMember({
    required String name,
    required String email,
    required String phone,
    required String role,
  }) async {
    try {
      await _firestore.collection('members').add({
        'name': name,
        'email': email,
        'phone': phone,
        'role': role,
        'joinedAt': FieldValue.serverTimestamp(),
        'isActive': true,
      });
    } catch (e) {
      print('Error adding member: $e');
    }
  }

  // Get members
  static Stream<QuerySnapshot> getMembers() {
    return _firestore
        .collection('members')
        .where('isActive', isEqualTo: true)
        .orderBy('name')
        .snapshots();
  }

  // Add dues payment
  static Future<void> addDuesPayment({
    required String memberId,
    required double amount,
    required String month,
    required String year,
  }) async {
    try {
      await _firestore.collection('dues_payments').add({
        'memberId': memberId,
        'amount': amount,
        'month': month,
        'year': year,
        'paidAt': FieldValue.serverTimestamp(),
        'status': 'paid',
      });
    } catch (e) {
      print('Error adding dues payment: $e');
    }
  }

  // Get dues payments for a member
  static Stream<QuerySnapshot> getDuesPayments(String memberId) {
    return _firestore
        .collection('dues_payments')
        .where('memberId', isEqualTo: memberId)
        .orderBy('paidAt', descending: true)
        .snapshots();
  }

  // Update user profile
  static Future<void> updateUserProfile({
    required String userId,
    required Map<String, dynamic> data,
  }) async {
    try {
      await _firestore.collection('users').doc(userId).update(data);
    } catch (e) {
      print('Error updating user profile: $e');
    }
  }

  // Get user profile
  static Future<DocumentSnapshot?> getUserProfile(String userId) async {
    try {
      return await _firestore.collection('users').doc(userId).get();
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
    }
  }

  // Storage Methods
  
  // Upload image to Firebase Storage
  static Future<String?> uploadImage({
    required String path,
    required List<int> imageBytes,
  }) async {
    try {
      final ref = _storage.ref().child(path);
      final uploadTask = ref.putData(Uint8List.fromList(imageBytes));
      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  // Delete image from Firebase Storage
  static Future<void> deleteImage(String imageUrl) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
    } catch (e) {
      print('Error deleting image: $e');
    }
  }

  // Realtime Database Methods for Announcements

  // Get announcements stream from Realtime Database
  static Stream<List<Announcement>> getAnnouncementsFromRealtimeDB() {
    return _realtimeDb.ref('Announcements').onValue.map((event) {
      final List<Announcement> announcements = [];
      
      if (event.snapshot.value != null) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        
        data.forEach((key, value) {
          if (value is Map) {
            final announcementData = Map<String, dynamic>.from(value);
            announcements.add(Announcement.fromMap(key, announcementData));
          }
        });
        
        // Sort announcements by date and time (newest first)
        announcements.sort((a, b) => b.dateTimeForSorting.compareTo(a.dateTimeForSorting));
      }
      
      return announcements;
    });
  }

  // Get announcements once from Realtime Database
  static Future<List<Announcement>> getAnnouncementsOnceFromRealtimeDB() async {
    try {
      final snapshot = await _realtimeDb.ref('Announcements').get();
      final List<Announcement> announcements = [];
      
      if (snapshot.value != null) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        
        data.forEach((key, value) {
          if (value is Map) {
            final announcementData = Map<String, dynamic>.from(value);
            announcements.add(Announcement.fromMap(key, announcementData));
          }
        });
        
        // Sort announcements by date and time (newest first)
        announcements.sort((a, b) => b.dateTimeForSorting.compareTo(a.dateTimeForSorting));
      }
      
      return announcements;
    } catch (e) {
      print('Error fetching announcements: $e');
      return [];
    }
  }

  // Dues Management Methods (based on JavaScript implementation)

  // Load dues data for a user
  static Future<List<Due>> loadDuesData(String userId) async {
    try {
      List<Due> duesEntries = [];

      // First, try to get dues from user document's duesHistory array
      final userDoc = await _firestore.collection('users').doc(userId).get();
      
      if (userDoc.exists) {
        final userData = userDoc.data();
        
        if (userData != null && userData['duesHistory'] != null && userData['duesHistory'] is List) {
          final duesHistory = List<Map<String, dynamic>>.from(userData['duesHistory']);
          
          for (var dueData in duesHistory) {
            duesEntries.add(Due.fromMap(dueData));
          }
        }
      }

      // If no dues found in user document, try dues collection as fallback
      if (duesEntries.isEmpty) {
        try {
          final duesQuery = await _firestore
              .collection('dues')
              .where('userId', isEqualTo: userId)
              .get();
          
          for (var doc in duesQuery.docs) {
            duesEntries.add(Due.fromMap(doc.data(), id: doc.id));
          }
        } catch (error) {
          print('Could not access dues collection: $error');
          // Continue with empty dues - we already tried our best
        }
      }

      return duesEntries;
    } catch (error) {
      print('Error loading dues data: $error');
      return [];
    }
  }

  // Get dues as a stream for real-time updates
  static Stream<List<Due>> getDuesStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .asyncMap((userDoc) async {
      List<Due> duesEntries = [];

      if (userDoc.exists) {
        final userData = userDoc.data();
        
        if (userData != null && userData['duesHistory'] != null && userData['duesHistory'] is List) {
          final duesHistory = List<Map<String, dynamic>>.from(userData['duesHistory']);
          
          for (var dueData in duesHistory) {
            duesEntries.add(Due.fromMap(dueData));
          }
        }
      }

      // If no dues found in user document, try dues collection as fallback
      if (duesEntries.isEmpty) {
        try {
          final duesQuery = await _firestore
              .collection('dues')
              .where('userId', isEqualTo: userId)
              .get();
          
          for (var doc in duesQuery.docs) {
            duesEntries.add(Due.fromMap(doc.data(), id: doc.id));
          }
        } catch (error) {
          print('Could not access dues collection: $error');
        }
      }

      return duesEntries;
    });
  }

  // Calculate dues statistics
  static DuesStatistics calculateDuesStatistics(List<Due> dues) {
    double totalAmount = 0;
    double paidAmount = 0;
    double unpaidAmount = 0;
    int totalCount = dues.length;
    int paidCount = 0;
    int unpaidCount = 0;

    for (var due in dues) {
      final amount = due.amount;
      totalAmount += amount;

      if (due.isPaid) {
        paidAmount += amount;
        paidCount++;
      } else {
        unpaidAmount += amount;
        unpaidCount++;
      }
    }

    return DuesStatistics(
      totalAmount: totalAmount,
      paidAmount: paidAmount,
      unpaidAmount: unpaidAmount,
      totalCount: totalCount,
      paidCount: paidCount,
      unpaidCount: unpaidCount,
    );
  }

  // Send message to admin (contact admin functionality)
  static Future<bool> sendMessageToAdmin({
    required String subject,
    required String message,
    required String userId,
    String? dueId,
  }) async {
    try {
      await _firestore.collection('messages').add({
        'subject': subject,
        'message': message,
        'dueId': dueId,
        'userId': userId,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'unread',
      });
      return true;
    } catch (error) {
      print('Error sending message to admin: $error');
      return false;
    }
  }

  // Get outstanding dues (unpaid)
  static List<Due> getOutstandingDues(List<Due> dues) {
    return dues.where((due) => !due.isPaid).toList()
      ..sort((a, b) => b.dueDate.compareTo(a.dueDate));
  }

  // Get payment history (paid dues)
  static List<Due> getPaymentHistory(List<Due> dues) {
    return dues.where((due) => due.isPaid).toList()
      ..sort((a, b) => (b.paymentDate ?? b.dueDate).compareTo(a.paymentDate ?? a.dueDate));
  }

  // Add a new due (for admin use)
  static Future<bool> addDue({
    required String userId,
    required String description,
    required double amount,
    required DateTime dueDate,
    String status = 'unpaid',
  }) async {
    try {
      await _firestore.collection('dues').add({
        'userId': userId,
        'description': description,
        'amount': amount,
        'dueDate': Timestamp.fromDate(dueDate),
        'status': status,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (error) {
      print('Error adding due: $error');
      return false;
    }
  }

  // Update due status (for payment processing)
  static Future<bool> updateDueStatus({
    required String dueId,
    required String status,
    DateTime? paymentDate,
  }) async {
    try {
      final updateData = {
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      if (paymentDate != null) {
        updateData['paymentDate'] = Timestamp.fromDate(paymentDate);
      }
      
      await _firestore.collection('dues').doc(dueId).update(updateData);
      return true;
    } catch (error) {
      print('Error updating due status: $error');
      return false;
    }
  }

  // Gallery Methods

  // Get gallery events stream from Firestore
  static Stream<List<GalleryEvent>> getGalleryEvents() {
    return _firestore
        .collection('events')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => GalleryEvent.fromMap(doc.id, doc.data()))
          .where((event) => event.images.isNotEmpty)
          .toList();
    });
  }

  // Get gallery events once from Firestore
  static Future<List<GalleryEvent>> getGalleryEventsOnce() async {
    try {
      final snapshot = await _firestore
          .collection('events')
          .orderBy('date', descending: true)
          .get();
      
      return snapshot.docs
          .map((doc) => GalleryEvent.fromMap(doc.id, doc.data()))
          .where((event) => event.images.isNotEmpty)
          .toList();
    } catch (error) {
      print('Error fetching gallery events: $error');
      return [];
    }
  }

  // Get all gallery images from all events
  static Future<List<GalleryImage>> getAllGalleryImages() async {
    try {
      final events = await getGalleryEventsOnce();
      final List<GalleryImage> allImages = [];
      
      for (final event in events) {
        allImages.addAll(event.images);
      }
      
      return allImages;
    } catch (error) {
      print('Error fetching all gallery images: $error');
      return [];
    }
  }

  // Get gallery images stream (flattened from all events)
  static Stream<List<GalleryImage>> getGalleryImagesStream() {
    return getGalleryEvents().map((events) {
      final List<GalleryImage> allImages = [];
      for (final event in events) {
        allImages.addAll(event.images);
      }
      return allImages;
    });
  }

  // Check if current user is admin
  static Future<bool> isCurrentUserAdmin() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;
      
      final adminDoc = await _firestore.collection('Admin').doc(user.uid).get();
      return adminDoc.exists;
    } catch (error) {
      print('Error checking admin status: $error');
      return false;
    }
  }

  // Profile Management Methods

  // Get current user profile
  static Future<UserProfile?> getCurrentUserProfile() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      return await getUserProfileById(user.uid);
    } catch (error) {
      print('Error getting current user profile: $error');
      return null;
    }
  }

  // Get user profile by ID
  static Future<UserProfile?> getUserProfileById(String userId) async {
    try {
      // Try users collection first
      final userDoc = await _firestore.collection('users').doc(userId).get();
      
      if (userDoc.exists && userDoc.data() != null) {
        return UserProfile.fromMap(userId, userDoc.data()!);
      }

      // Fallback to Firebase Auth user data
      final user = _auth.currentUser;
      if (user != null && user.uid == userId) {
        return UserProfile(
          id: user.uid,
          name: user.displayName,
          email: user.email,
          profileImageUrl: user.photoURL,
          phone: user.phoneNumber,
          role: 'Member',
        );
      }

      return null;
    } catch (error) {
      print('Error getting user profile: $error');
      return null;
    }
  }

  // Get user profile stream
  static Stream<UserProfile?> getUserProfileStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        return UserProfile.fromMap(userId, snapshot.data()!);
      }
      return null;
    });
  }

  // Get current user profile stream
  static Stream<UserProfile?> getCurrentUserProfileStream() {
    return _auth.authStateChanges().asyncMap((user) async {
      if (user == null) {
        return null;
      }
      return await getUserProfileById(user.uid);
    });
  }

  // Update user profile details (enhanced version)
  static Future<bool> updateUserProfileDetails({
    required String userId,
    String? name,
    String? phone,
    String? address,
    String? dateOfBirth,
    String? emergencyContact,
    String? profileImageUrl,
    Map<String, dynamic>? additionalInfo,
  }) async {
    try {
      final updateData = <String, dynamic>{};
      
      if (name != null) updateData['name'] = name;
      if (phone != null) updateData['phone'] = phone;
      if (address != null) updateData['address'] = address;
      if (dateOfBirth != null) updateData['dateOfBirth'] = dateOfBirth;
      if (emergencyContact != null) updateData['emergencyContact'] = emergencyContact;
      if (profileImageUrl != null) updateData['profileImageUrl'] = profileImageUrl;
      if (additionalInfo != null) updateData['additionalInfo'] = additionalInfo;
      
      updateData['updatedAt'] = FieldValue.serverTimestamp();

      // Update in Firestore
      await _firestore.collection('users').doc(userId).set(
        updateData,
        SetOptions(merge: true),
      );

      // Also update Firebase Auth profile if name or photo changed
      final user = _auth.currentUser;
      if (user != null && user.uid == userId) {
        if (name != null || profileImageUrl != null) {
          await user.updateDisplayName(name);
          if (profileImageUrl != null) {
            await user.updatePhotoURL(profileImageUrl);
          }
        }
      }

      return true;
    } catch (error) {
      print('Error updating user profile: $error');
      return false;
    }
  }

  // Create or initialize user profile
  static Future<bool> createUserProfile({
    required String userId,
    required String email,
    String? name,
    String? phone,
    String? role,
  }) async {
    try {
      final profileData = {
        'email': email,
        'name': name ?? email.split('@').first,
        'phone': phone,
        'role': role ?? 'Member',
        'isActive': true,
        'joinedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('users').doc(userId).set(
        profileData,
        SetOptions(merge: true),
      );

      return true;
    } catch (error) {
      print('Error creating user profile: $error');
      return false;
    }
  }

  // Upload profile image
  static Future<String?> uploadProfileImage({
    required String userId,
    required List<int> imageBytes,
    required String fileName,
  }) async {
    try {
      final path = 'profile_images/$userId/$fileName';
      final downloadURL = await uploadImage(
        path: path,
        imageBytes: imageBytes,
      );

      if (downloadURL != null) {
        // Update user profile with new image URL
        await updateUserProfile(
          userId: userId,
          data: {'profileImageUrl': downloadURL},
        );
      }

      return downloadURL;
    } catch (error) {
      print('Error uploading profile image: $error');
      return null;
    }
  }

  // Delete profile image
  static Future<bool> deleteProfileImage(String userId) async {
    try {
      final userProfile = await getUserProfileById(userId);
      if (userProfile?.profileImageUrl != null) {
        // Delete from storage
        await deleteImage(userProfile!.profileImageUrl!);
        
        // Update profile to remove image URL
        await updateUserProfile(
          userId: userId,
          data: {'profileImageUrl': ''},
        );
      }
      return true;
    } catch (error) {
      print('Error deleting profile image: $error');
      return false;
    }
  }

  // Get user statistics
  static Future<Map<String, dynamic>> getUserStatistics(String userId) async {
    try {
      final statistics = <String, dynamic>{
        'totalDues': 0,
        'paidDues': 0,
        'outstandingDues': 0,
        'totalEvents': 0,
        'joinedDate': null,
        'lastActivity': null,
      };

      // Get user profile for joined date
      final userProfile = await getUserProfileById(userId);
      if (userProfile?.joinedAt != null) {
        statistics['joinedDate'] = userProfile!.joinedAt;
      }

      // Get dues statistics
      final dues = await loadDuesData(userId);
      final duesStats = calculateDuesStatistics(dues);
      
      statistics['totalDues'] = duesStats.totalAmount;
      statistics['paidDues'] = duesStats.paidAmount;
      statistics['outstandingDues'] = duesStats.unpaidAmount;

      return statistics;
    } catch (error) {
      print('Error getting user statistics: $error');
      return {};
    }
  }

  // ADMIN AUTHENTICATION METHODS

  // Enhanced admin login that matches the web version
  static Future<AdminLoginResult> adminSignIn(String email, String password) async {
    try {
      // Sign in with Firebase Auth
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = userCredential.user;
      
      if (user == null) {
        return AdminLoginResult(success: false, message: 'Authentication failed');
      }

      // Check if user is admin by checking Admin collection
      final adminDoc = await _firestore.collection('Admin').doc(user.uid).get();
      
      if (adminDoc.exists) {
        // Update admin last login
        await _firestore.collection('Admin').doc(user.uid).update({
          'lastLogin': FieldValue.serverTimestamp(),
        });
        
        return AdminLoginResult(
          success: true,
          isAdmin: true,
          message: 'Admin login successful',
          user: user,
        );
      }

      // Check if regular user and handle approval status
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      
      if (!userDoc.exists) {
        await _auth.signOut();
        return AdminLoginResult(
          success: false,
          message: 'User account incomplete. Please contact administrator.',
        );
      }

      final userData = userDoc.data()!;
      
      // Update last login for regular user
      await _firestore.collection('users').doc(user.uid).update({
        'lastLogin': FieldValue.serverTimestamp(),
        'emailVerified': user.emailVerified,
      });

      // Check if user is approved
      if (userData['isApproved'] != true) {
        // Create/update access request
        await _firestore.collection('accessRequests').doc(user.uid).set({
          'email': user.email,
          'displayName': userData['name'] ?? user.email?.split('@')[0] ?? 'Unknown',
          'requestedAt': FieldValue.serverTimestamp(),
          'status': 'pending',
          'lastLogin': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        
        // Sign out user
        await _auth.signOut();
        
        return AdminLoginResult(
          success: false,
          isAdmin: false,
          isPendingApproval: true,
          message: 'Your account is pending administrator approval.',
        );
      }

      // User is approved regular user
      return AdminLoginResult(
        success: true,
        isAdmin: false,
        message: 'User login successful',
        user: user,
      );

    } catch (error) {
      String message = 'Login error occurred';
      
      if (error.toString().contains('user-not-found')) {
        message = 'Email not found!';
      } else if (error.toString().contains('wrong-password')) {
        message = 'Incorrect password. Please try again.';
      } else if (error.toString().contains('invalid-email')) {
        message = 'Invalid email format.';
      } else if (error.toString().contains('too-many-requests')) {
        message = 'Too many failed attempts. Please try again later.';
      }
      
      return AdminLoginResult(success: false, message: message);
    }
  }

  // Get admin profile
  static Future<Map<String, dynamic>?> getAdminProfile(String adminId) async {
    try {
      final adminDoc = await _firestore.collection('Admin').doc(adminId).get();
      if (adminDoc.exists) {
        return adminDoc.data();
      }
      return null;
    } catch (error) {
      print('Error getting admin profile: $error');
      return null;
    }
  }

  // ADMIN DASHBOARD METHODS

  // Get pending access requests
  static Stream<List<Map<String, dynamic>>> getPendingAccessRequests() {
    return _firestore
        .collection('accessRequests')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .handleError((error) {
      print('Error in getPendingAccessRequests: $error');
      return [];
    }).map((snapshot) {
      try {
        if (snapshot.docs.isEmpty) {
          return <Map<String, dynamic>>[];
        }
        
        final docs = snapshot.docs.map((doc) {
          try {
            final data = Map<String, dynamic>.from(doc.data());
            data['id'] = doc.id;
            return data;
          } catch (e) {
            print('Error processing document ${doc.id}: $e');
            return <String, dynamic>{'id': doc.id};
          }
        }).where((doc) => doc.isNotEmpty).toList();
        
        // Sort manually to avoid index requirement
        docs.sort((a, b) {
          try {
            final aTime = a['requestedAt'] as Timestamp?;
            final bTime = b['requestedAt'] as Timestamp?;
            if (aTime == null || bTime == null) return 0;
            return bTime.compareTo(aTime);
          } catch (e) {
            return 0;
          }
        });
        
        return docs;
      } catch (e) {
        print('Error in getPendingAccessRequests map: $e');
        return <Map<String, dynamic>>[];
      }
    });
  }

  // Approve user access
  static Future<bool> approveUserAccess(String userId) async {
    try {
      // Update user approval status
      await _firestore.collection('users').doc(userId).update({
        'isApproved': true,
        'approvedAt': FieldValue.serverTimestamp(),
      });

      // Update access request status
      await _firestore.collection('accessRequests').doc(userId).update({
        'status': 'approved',
        'approvedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (error) {
      print('Error approving user access: $error');
      return false;
    }
  }

  // Reject user access
  static Future<bool> rejectUserAccess(String userId, {String? reason}) async {
    try {
      // Update access request status
      final updateData = {
        'status': 'rejected',
        'rejectedAt': FieldValue.serverTimestamp(),
      };
      
      if (reason != null) {
        updateData['rejectionReason'] = reason;
      }

      await _firestore.collection('accessRequests').doc(userId).update(updateData);

      return true;
    } catch (error) {
      print('Error rejecting user access: $error');
      return false;
    }
  }

  // Get all users for admin management (checks both users and members collections)
  static Stream<List<Map<String, dynamic>>> getAllUsers() async* {
    try {
      // First check which collection has more data
      final usersSnapshot = await _firestore.collection('users').limit(1).get();
      final membersSnapshot = await _firestore.collection('members').limit(1).get();
      
      // Determine primary collection based on which has data
      String primaryCollection = 'users';
      if (usersSnapshot.docs.isEmpty && membersSnapshot.docs.isNotEmpty) {
        primaryCollection = 'members';
      }
      
      print('Using collection: $primaryCollection for user data');
      
      // Create stream from the appropriate collection
      yield* _firestore
          .collection(primaryCollection)
          .snapshots()
          .handleError((error) {
        print('Error in getAllUsers: $error');
        return [];
      }).map((snapshot) {
        try {
          if (snapshot.docs.isEmpty) {
            return <Map<String, dynamic>>[];
          }
          
          final docs = <Map<String, dynamic>>[];
          
          for (final doc in snapshot.docs) {
            try {
              final data = Map<String, dynamic>.from(doc.data());
              data['id'] = doc.id;
              
              // Normalize field names between collections
              if (primaryCollection == 'members') {
                // Members collection might use different field names
                data['isApproved'] = data['isApproved'] ?? true; // Default to approved for members
                data['isActive'] = data['isActive'] ?? true;
                data['role'] = data['role'] ?? 'Member';
                // Map common fields
                if (data['phno'] != null) {
                  data['phone'] = data['phno'];
                }
              }
              
              // Ensure essential fields exist
              if (data['email'] != null || data['name'] != null) {
                docs.add(data);
              }
            } catch (e) {
              print('Error processing document ${doc.id}: $e');
              continue;
            }
          }
          
          // Sort manually to avoid index requirement
          docs.sort((a, b) {
            try {
              final aName = (a['name']?.toString() ?? a['email']?.toString() ?? '').toLowerCase();
              final bName = (b['name']?.toString() ?? b['email']?.toString() ?? '').toLowerCase();
              return aName.compareTo(bName);
            } catch (e) {
              return 0;
            }
          });
          
          return docs;
        } catch (e) {
          print('Error in getAllUsers map: $e');
          return <Map<String, dynamic>>[];
        }
      });
    } catch (e) {
      print('Error determining collection: $e');
      // Fallback to users collection
      yield* _firestore
          .collection('users')
          .snapshots()
          .map((snapshot) => <Map<String, dynamic>>[]);
    }
  }
  
  // Get all users/members from both collections and merge them
  static Stream<List<Map<String, dynamic>>> getAllUsersAndMembers() {
    // Use a proper broadcast stream to allow multiple listeners
    late StreamController<List<Map<String, dynamic>>> controller;
    
    controller = StreamController<List<Map<String, dynamic>>>.broadcast(
      onListen: () async {
        try {
          final data = await _getCombinedUsersAndMembers();
          if (!controller.isClosed) {
            controller.add(data);
          }
        } catch (e) {
          if (!controller.isClosed) {
            controller.addError(e);
          }
        }
      },
    );
    
    return controller.stream;
  }
  
  static Future<List<Map<String, dynamic>>> _getCombinedUsersAndMembers() async {
    try {
      final allData = <Map<String, dynamic>>[];
      final processedEmails = <String>{};
      
      // Get data from users collection
      try {
        final usersSnapshot = await _firestore.collection('users').get();
        print('Users collection: Found ${usersSnapshot.docs.length} documents');
        
        for (final doc in usersSnapshot.docs) {
          final data = Map<String, dynamic>.from(doc.data());
          data['id'] = doc.id;
          data['source'] = 'users';
          
          final email = data['email']?.toString();
          final name = data['name']?.toString();
          print('User doc ${doc.id}: name=$name, email=$email');
          
          if (email != null && email.isNotEmpty) {
            processedEmails.add(email.toLowerCase());
            allData.add(data);
          } else if (name != null && name.isNotEmpty) {
            // Add users with name but no email
            allData.add(data);
          }
        }
      } catch (e) {
        print('Error fetching users: $e');
      }
      
      // Get data from members collection (avoid duplicates by email)
      try {
        final membersSnapshot = await _firestore.collection('members').get();
        print('Members collection: Found ${membersSnapshot.docs.length} documents');
        
        for (final doc in membersSnapshot.docs) {
          final data = Map<String, dynamic>.from(doc.data());
          data['id'] = doc.id;
          data['source'] = 'members';
          
          // Normalize field names
          if (data['phno'] != null) {
            data['phone'] = data['phno'];
          }
          data['isApproved'] = data['isApproved'] ?? true;
          data['isActive'] = data['isActive'] ?? true;
          data['role'] = data['role'] ?? 'Member';
          
          final email = data['email']?.toString();
          final name = data['name']?.toString();
          print('Member doc ${doc.id}: name=$name, email=$email');
          
          if (email != null && email.isNotEmpty) {
            // Only add if not already processed from users collection
            if (!processedEmails.contains(email.toLowerCase())) {
              allData.add(data);
            }
          } else if (name != null && name.isNotEmpty) {
            // Add if has name but no email (and no duplicate check needed)
            allData.add(data);
          }
        }
      } catch (e) {
        print('Error fetching members: $e');
      }
      
      // Sort by name
      allData.sort((a, b) {
        final aName = (a['name']?.toString() ?? a['email']?.toString() ?? '').toLowerCase();
        final bName = (b['name']?.toString() ?? b['email']?.toString() ?? '').toLowerCase();
        return aName.compareTo(bName);
      });
      
      print('Combined data: ${allData.length} users/members found');
      for (final item in allData.take(5)) {
        print('Sample: ${item['name']} (${item['email']}) from ${item['source']}');
      }
      
      return allData;
    } catch (e) {
      print('Error in _getCombinedUsersAndMembers: $e');
      return [];
    }
  }

  // Get admin dashboard statistics
  static Future<Map<String, dynamic>> getAdminDashboardStats() async {
    try {
      final stats = <String, dynamic>{
        'totalUsers': 0,
        'approvedUsers': 0,
        'pendingUsers': 0,
        'totalAnnouncements': 0,
        'totalEvents': 0,
        'totalDuesAmount': 0.0,
        'paidDuesAmount': 0.0,
        'unpaidDuesAmount': 0.0,
      };

      // Get user statistics with error handling (using combined data)
      try {
        final combinedData = await _getCombinedUsersAndMembers();
        stats['totalUsers'] = combinedData.length;
        stats['approvedUsers'] = combinedData
            .where((data) => data['isApproved'] == true)
            .length;
      } catch (e) {
        print('Error getting user stats: $e');
      }

      // Get pending access requests with error handling
      try {
        final pendingSnapshot = await _firestore
            .collection('accessRequests')
            .where('status', isEqualTo: 'pending')
            .get();
        stats['pendingUsers'] = pendingSnapshot.docs.length;
      } catch (e) {
        print('Error getting pending users: $e');
      }

      // Get announcements count from Realtime Database with error handling
      try {
        final announcementsSnapshot = await _realtimeDb.ref('Announcements').get();
        if (announcementsSnapshot.exists && announcementsSnapshot.value != null) {
          final announcementsData = Map<String, dynamic>.from(announcementsSnapshot.value as Map);
          stats['totalAnnouncements'] = announcementsData.length;
        }
      } catch (e) {
        print('Error getting announcements count: $e');
      }

      // Get events count with error handling
      try {
        final eventsSnapshot = await _firestore.collection('events').get();
        stats['totalEvents'] = eventsSnapshot.docs.length;
      } catch (e) {
        print('Error getting events count: $e');
      }

      // Skip dues calculation for now to avoid complexity and potential errors
      // This can be implemented later when needed
      
      return stats;
    } catch (error) {
      print('Error getting admin dashboard stats: $error');
      // Return default stats instead of empty map
      return {
        'totalUsers': 0,
        'approvedUsers': 0,
        'pendingUsers': 0,
        'totalAnnouncements': 0,
        'totalEvents': 0,
        'totalDuesAmount': 0.0,
        'paidDuesAmount': 0.0,
        'unpaidDuesAmount': 0.0,
      };
    }
  }

  // Get admin messages/support requests
  static Stream<List<Map<String, dynamic>>> getAdminMessages() {
    return _firestore
        .collection('messages')
        .snapshots()
        .handleError((error) {
      print('Error in getAdminMessages: $error');
      return [];
    }).map((snapshot) {
      try {
        if (snapshot.docs.isEmpty) {
          return <Map<String, dynamic>>[];
        }
        
        final docs = snapshot.docs.map((doc) {
          try {
            final data = Map<String, dynamic>.from(doc.data());
            data['id'] = doc.id;
            return data;
          } catch (e) {
            print('Error processing message document ${doc.id}: $e');
            return <String, dynamic>{'id': doc.id};
          }
        }).where((doc) => doc.isNotEmpty).toList();
        
        // Sort manually to avoid index requirement
        docs.sort((a, b) {
          try {
            final aTime = a['timestamp'] as Timestamp?;
            final bTime = b['timestamp'] as Timestamp?;
            if (aTime == null || bTime == null) return 0;
            return bTime.compareTo(aTime);
          } catch (e) {
            return 0;
          }
        });
        
        return docs;
      } catch (e) {
        print('Error in getAdminMessages map: $e');
        return <Map<String, dynamic>>[];
      }
    });
  }

  // Mark message as read
  static Future<bool> markMessageAsRead(String messageId) async {
    try {
      await _firestore.collection('messages').doc(messageId).update({
        'status': 'read',
        'readAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (error) {
      print('Error marking message as read: $error');
      return false;
    }
  }

  // Create new announcement (admin only)
  static Future<bool> createAnnouncement({
    required String title,
    required String body,
    required String date,
    required String time,
    Map<String, dynamic>? attachment,
  }) async {
    try {
      // Add to Realtime Database (matching the web version structure)
      final announcementRef = _realtimeDb.ref('Announcements').push();
      
      final announcementData = {
        'Title': title,
        'Body': body,
        'Date': date,
        'Time': time,
        'createdAt': ServerValue.timestamp,
      };
      
      if (attachment != null) {
        announcementData['attachment'] = attachment;
      }
      
      await announcementRef.set(announcementData);
      return true;
    } catch (error) {
      print('Error creating announcement: $error');
      return false;
    }
  }

  // Update announcement (admin only)
  static Future<bool> updateAnnouncement({
    required String announcementId,
    required String title,
    required String body,
    required String date,
    required String time,
    Map<String, dynamic>? attachment,
  }) async {
    try {
      final announcementData = {
        'Title': title,
        'Body': body,
        'Date': date,
        'Time': time,
        'updatedAt': ServerValue.timestamp,
      };
      
      if (attachment != null) {
        announcementData['attachment'] = attachment;
      }
      
      await _realtimeDb.ref('Announcements/$announcementId').update(announcementData);
      return true;
    } catch (error) {
      print('Error updating announcement: $error');
      return false;
    }
  }

  // Upload file for announcement attachment
  static Future<Map<String, dynamic>?> uploadAnnouncementAttachment({
    required List<int> fileBytes,
    required String fileName,
    required String fileType,
  }) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final sanitizedFileName = fileName.replaceAll(RegExp(r'[^\w\-_\.]'), '_');
      final path = 'announcements/attachments/$timestamp-$sanitizedFileName';
      
      final ref = _storage.ref().child(path);
      final uploadTask = ref.putData(
        Uint8List.fromList(fileBytes),
        SettableMetadata(contentType: fileType),
      );
      
      final snapshot = await uploadTask;
      final downloadURL = await snapshot.ref.getDownloadURL();
      
      return {
        'fileType': fileType,
        'downloadURL': downloadURL,
        'fileName': fileName,
        'fileSize': fileBytes.length,
        'uploadPath': path,
      };
    } catch (error) {
      print('Error uploading announcement attachment: $error');
      return null;
    }
  }

  // Delete announcement attachment from storage
  static Future<bool> deleteAnnouncementAttachment(String uploadPath) async {
    try {
      await _storage.ref().child(uploadPath).delete();
      return true;
    } catch (error) {
      print('Error deleting announcement attachment: $error');
      return false;
    }
  }

  // Delete announcement (admin only)
  static Future<bool> deleteAnnouncement(String announcementId) async {
    try {
      // First, get the announcement to check for attachments
      final snapshot = await _realtimeDb.ref('Announcements/$announcementId').get();
      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        
        // Delete attachment if exists
        if (data['attachment'] != null && data['attachment']['uploadPath'] != null) {
          await deleteAnnouncementAttachment(data['attachment']['uploadPath']);
        }
      }
      
      // Delete the announcement
      await _realtimeDb.ref('Announcements/$announcementId').remove();
      return true;
    } catch (error) {
      print('Error deleting announcement: $error');
      return false;
    }
  }

  // Update user role/permissions (admin only)
  static Future<bool> updateUserRole(String userId, String role) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'role': role,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (error) {
      print('Error updating user role: $error');
      return false;
    }
  }

  // Deactivate/Activate user (admin only)
  static Future<bool> toggleUserStatus(String userId, bool isActive) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isActive': isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (error) {
      print('Error toggling user status: $error');
      return false;
    }
  }

  // Delete user (admin only) - Soft delete by deactivating
  static Future<bool> deleteUser(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isActive': false,
        'isDeleted': true,
        'deletedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (error) {
      print('Error deleting user: $error');
      return false;
    }
  }

  // Get user by ID
  static Future<Map<String, dynamic>?> getUserById(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        final data = doc.data()!;
        data['id'] = doc.id;
        return data;
      }
      return null;
    } catch (error) {
      print('Error getting user by ID: $error');
      return null;
    }
  }

  // Create user with custom ID (admin only)
  static Future<bool> createUserWithId({
    required String userId,
    required String email,
    required String name,
    String? phone,
    String role = 'Member',
    bool isApproved = false,
    bool isActive = true,
  }) async {
    try {
      final userData = {
        'email': email,
        'name': name,
        'role': role,
        'isApproved': isApproved,
        'isActive': isActive,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      if (phone != null && phone.isNotEmpty) {
        userData['phone'] = phone;
      }

      await _firestore.collection('users').doc(userId).set(userData);
      return true;
    } catch (error) {
      print('Error creating user: $error');
      return false;
    }
  }
}

// Admin Login Result Class
class AdminLoginResult {
  final bool success;
  final bool isAdmin;
  final bool isPendingApproval;
  final String message;
  final User? user;

  AdminLoginResult({
    required this.success,
    this.isAdmin = false,
    this.isPendingApproval = false,
    required this.message,
    this.user,
  });
} 