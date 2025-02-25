import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';


class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;


  // Get current user
  User? get currentUser => _auth.currentUser;

  // Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Method to get current user's email
  String? getCurrentUserEmail() {
    return _auth.currentUser?.email;
  }

  // Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Cek apakah email belum diverifikasi
      if (!userCredential.user!.emailVerified) {
        // Logout dan lempar pengecualian
        await signOut();
        throw FirebaseAuthException(
            code: 'email-not-verified',
            message: 'Silakan verifikasi email Anda terlebih dahulu.'
        );
      }

      // Return UserCredential meskipun email belum diverifikasi
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  Future<bool> waitForEmailVerification({Duration timeout = const Duration(minutes: 3)}) async {
    User? user = _auth.currentUser;
    if (user == null) {
      throw Exception('No user is currently logged in.');
    }

    final Completer<bool> completer = Completer<bool>();
    final Timer timer = Timer(timeout, () {
      if (!completer.isCompleted) completer.complete(false);
    });

    // Listen to user changes
    final subscription = _auth.userChanges().listen((User? updatedUser) {
      if (updatedUser?.emailVerified ?? false) {
        timer.cancel();
        if (!completer.isCompleted) completer.complete(true);
      }
    });

    try {
      final result = await completer.future;
      return result;
    } finally {
      subscription.cancel();
      timer.cancel(); // Ensure the timer is always cancelled
    }
  }

  // Register with email and password
  Future<UserCredential> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Split display name
      List<String> nameParts = displayName.trim().split(' ');
      String firstName = nameParts.first;
      String lastName = nameParts.length > 1
          ? nameParts.sublist(1).join(' ')
          : '';

      // Update display name
      await userCredential.user?.updateDisplayName(displayName);

      // Send verification email
      await userCredential.user?.sendEmailVerification();

      // Save user data to Firestore
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'email': email,
        'displayName': displayName,
        'firstName': firstName,
        'lastName': lastName,
        'timestamp': FieldValue.serverTimestamp(),
        'emailVerified': false,
        'verificationSentAt': FieldValue.serverTimestamp(),
      });

      return userCredential;
    } catch (e) {
      throw Exception('Registration failed: $e');
    }
  }


  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Updated method to retrieve first and last name
  Future<Map<String, String?>> getUserNames() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        var userDoc = await _firestore.collection('users').doc(user.uid).get();
        return {
          'displayName': userDoc.data()?['displayName'],
          'firstName': userDoc.data()?['firstName'],
          'lastName': userDoc.data()?['lastName']
        };
      }
    } catch (e) {
      print('Error retrieving user names: $e');
    }
    return {};
  }

  // Update user profile
  Future<void> updateUserProfile(String displayName) async {
    await _auth.currentUser?.updateDisplayName(displayName);
  }

  // Handle Firebase Auth exceptions
  FirebaseAuthException _handleAuthException(FirebaseAuthException e) {
    return e;
  }
  // Update display name
  Future<void> updateDisplayName(String displayName) async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        await user.updateDisplayName(displayName);
      } else {
        throw 'No authenticated user found';
      }
    } catch (e) {
      print('Error updating display name: $e');
      rethrow;
    }
  }
  // Check if email is verified
  bool isEmailVerified() {
    return _auth.currentUser?.emailVerified ?? false;
  }

  // Resend verification email
  Future<void> resendVerificationEmail() async {
    try {
      await _auth.currentUser?.sendEmailVerification();
    } catch (e) {
      throw Exception('Error sending verification email: $e');
    }
  }
  Future<bool> isFirstTimeLogin() async {
    User? user = _auth.currentUser;
    if (user == null) return true;

    // Menggunakan metadata lastSignInTime untuk mengecek
    return user.metadata.lastSignInTime == user.metadata.creationTime;
  }

  Future<bool> checkUsernameUniqueness(String username) async {
    try {
      // Query Firestore untuk mencari dokumen dengan username yang sama
      final QuerySnapshot result = await FirebaseFirestore.instance
          .collection('users')
          .where('username', isEqualTo: username.toLowerCase())
          .get();

      // Jika tidak ada dokumen yang ditemukan, username tersedia
      return result.docs.isEmpty;
    } catch (e) {
      print('Error checking username uniqueness: $e');
      return false;
    }
  }
}

