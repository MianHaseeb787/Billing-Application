import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with email and password
  Future<AppUser?> signIn(String email, String password) async {
    try {
      final UserCredential userCredential = await _auth
          .signInWithEmailAndPassword(email: email.trim(), password: password);

      if (userCredential.user != null) {
        // Get user data from Firestore
        final userDoc = await _firestore
            .collection('users')
            .doc(userCredential.user!.uid)
            .get();

        if (userDoc.exists) {
          final userData = AppUser.fromFirestore(userDoc.data()!);

          // Update last login
          await _firestore.collection('users').doc(userDoc.id).update({
            'lastLogin': FieldValue.serverTimestamp(),
          });

          return userData;
        }
      }
      return null;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }

  // Sign up new user
  Future<AppUser?> signUp(
    String email,
    String password,
    String name,
    UserRole role,
  ) async {
    try {
      final UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(
            email: email.trim(),
            password: password,
          );

      if (userCredential.user != null) {
        final user = AppUser(
          uid: userCredential.user!.uid,
          email: email.trim(),
          name: name,
          role: role,
        );

        // Save user data to Firestore
        await _firestore
            .collection('users')
            .doc(userCredential.user!.uid)
            .set(user.toFirestore());

        return user;
      }
      return null;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Get user data from Firestore
  Future<AppUser?> getUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return AppUser.fromFirestore(doc.data()!);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Update user data
  Future<void> updateUserData(String uid, Map<String, dynamic> data) async {
    await _firestore.collection('users').doc(uid).update(data);
  }

  // Get all users (admin only)
  Stream<List<AppUser>> getAllUsers() {
    return _firestore
        .collection('users')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => AppUser.fromFirestore(doc.data()))
              .toList(),
        );
  }

  // Handle authentication errors
  String _handleAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'user-disabled':
        return 'This user has been disabled.';
      case 'too-many-requests':
        return 'Too many requests. Please try again later.';
      case 'operation-not-allowed':
        return 'Email/password accounts are not enabled.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'weak-password':
        return 'Password is too weak. Please use a stronger password.';
      default:
        return 'An error occurred. Please try again.';
    }
  }
}
