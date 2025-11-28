import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:google_sign_in/google_sign_in.dart'; // Geçici olarak kaldırıldı
import '../../features/auth/data/models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Mevcut kullanıcıyı al
  User? get currentUser => _auth.currentUser;

  // Kullanıcı durumu stream'i
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Email ve şifre ile giriş yapma
  Future<UserModel> signInWithEmailAndPassword(String email, String password) async {
    try {
      final UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Firestore'dan kullanıcı bilgilerini al
      final userDoc = await _firestore
          .collection('users')
          .doc(credential.user!.uid)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data()!;
        return UserModel(
          id: credential.user!.uid,
          name: userData['name'] ?? credential.user!.displayName ?? 'Kullanıcı',
          email: credential.user!.email ?? email,
          role: userData['role'] ?? 'user',
        );
      } else {
        // Kullanıcı Firestore'da yoksa varsayılan oluştur
        final newUser = UserModel(
          id: credential.user!.uid,
          name: credential.user!.displayName ?? 'Kullanıcı',
          email: credential.user!.email ?? email,
          role: 'user',
        );

        // Firestore'a kaydet
        await _firestore.collection('users').doc(credential.user!.uid).set({
          'name': newUser.name,
          'email': newUser.email,
          'role': newUser.role,
          'createdAt': FieldValue.serverTimestamp(),
        });

        return newUser;
      }
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Giriş işlemi sırasında bir hata oluştu: $e');
    }
  }

  // Email ve şifre ile kayıt olma
  Future<UserModel> signUpWithEmailAndPassword(
    String email,
    String password,
    String name,
  ) async {
    try {
      final UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Kullanıcı adını güncelle
      await credential.user!.updateDisplayName(name);

      // Firestore'a kullanıcı bilgilerini kaydet
      final newUser = UserModel(
        id: credential.user!.uid,
        name: name,
        email: email,
        role: 'user',
      );

      await _firestore.collection('users').doc(credential.user!.uid).set({
        'name': name,
        'email': email,
        'role': 'user',
        'createdAt': FieldValue.serverTimestamp(),
      });

      return newUser;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Kayıt işlemi sırasında bir hata oluştu: $e');
    }
  }

  // Google ile giriş yapma - GEÇİCİ OLARAK KALDIRILDI
  /*
  Future<UserModel> signInWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        throw Exception('Google girişi iptal edildi');
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      final User user = userCredential.user!;

      // Firestore'dan kullanıcı bilgilerini al
      final userDoc = await _firestore.collection('users').doc(user.uid).get();

      if (userDoc.exists) {
        final userData = userDoc.data()!;
        return UserModel(
          id: user.uid,
          name: userData['name'] ?? user.displayName ?? 'Kullanıcı',
          email: user.email ?? '',
          role: userData['role'] ?? 'user',
        );
      } else {
        // Kullanıcı Firestore'da yoksa oluştur
        final newUser = UserModel(
          id: user.uid,
          name: user.displayName ?? 'Kullanıcı',
          email: user.email ?? '',
          role: 'user',
        );

        await _firestore.collection('users').doc(user.uid).set({
          'name': newUser.name,
          'email': newUser.email,
          'role': newUser.role,
          'createdAt': FieldValue.serverTimestamp(),
        });

        return newUser;
      }
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Google ile giriş sırasında hata: $e');
    }
  }
  */

  // Şifre sıfırlama
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Şifre sıfırlama işlemi sırasında bir hata oluştu: $e');
    }
  }

  // Çıkış yapma
  Future<void> signOut() async {
    try {
      // await GoogleSignIn().signOut(); // Geçici olarak kaldırıldı
      await _auth.signOut();
    } catch (e) {
      throw Exception('Çıkış işlemi sırasında bir hata oluştu: $e');
    }
  }

  // Kullanıcı bilgilerini Firestore'dan al
  Future<UserModel?> getUserData(String uid) async {
    try {
      final userDoc = await _firestore.collection('users').doc(uid).get();
      if (userDoc.exists) {
        final userData = userDoc.data()!;
        return UserModel(
          id: uid,
          name: userData['name'] ?? 'Kullanıcı',
          email: userData['email'] ?? '',
          role: userData['role'] ?? 'user',
        );
      }
      return null;
    } catch (e) {
      throw Exception('Kullanıcı bilgileri alınırken bir hata oluştu: $e');
    }
  }

  // Kullanıcı bilgilerini güncelle
  Future<void> updateUserData(String uid, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('users').doc(uid).update(data);
    } catch (e) {
      throw Exception('Kullanıcı bilgileri güncellenirken bir hata oluştu: $e');
    }
  }

  // Firebase Auth hatalarını Türkçe'ye çevir
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'Şifre çok zayıf. Daha güçlü bir şifre seçin.';
      case 'email-already-in-use':
        return 'Bu e-posta adresi zaten kullanılıyor.';
      case 'user-not-found':
        return 'Bu e-posta adresine kayıtlı kullanıcı bulunamadı.';
      case 'wrong-password':
        return 'Şifre yanlış. Lütfen tekrar deneyin.';
      case 'invalid-email':
        return 'Geçersiz e-posta adresi.';
      case 'user-disabled':
        return 'Bu kullanıcı hesabı devre dışı bırakılmış.';
      case 'too-many-requests':
        return 'Çok fazla deneme yapıldı. Lütfen daha sonra tekrar deneyin.';
      case 'operation-not-allowed':
        return 'Bu işlem şu anda izin verilmiyor.';
      case 'network-request-failed':
        return 'Ağ bağlantısı hatası. İnternet bağlantınızı kontrol edin.';
      default:
        return 'Bir hata oluştu: ${e.message ?? e.code}';
    }
  }
}
