import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../features/auth/data/models/user_model.dart';
import '../../core/database/database_instance.dart';
import '../../features/auth/data/repositories/hybrid_user_repository.dart';

import 'dart:io';

class AuthService {
  FirebaseAuth? _auth;
  FirebaseFirestore? _firestore;
  late final HybridUserRepository _userRepository;

  AuthService() {
    if (!Platform.isWindows && !Platform.isLinux) {
      _auth = FirebaseAuth.instance;
      _firestore = FirebaseFirestore.instance;
    }
    _userRepository = HybridUserRepository(localDb: db, firestore: _firestore);
  }

  // Mevcut kullanıcıyı al
  User? get currentUser => _auth?.currentUser;

  // Kullanıcı durumu stream'i
  Stream<User?> get authStateChanges => _auth?.authStateChanges() ?? Stream.value(null);

  // Email ve şifre ile giriş yapma
  Future<UserModel> signInWithEmailAndPassword(String email, String password) async {
    // Desktop Offline Login Bypass
    if (Platform.isWindows || Platform.isLinux) {
      // Offline modda şimdilik her zaman admin olarak giriş yapılıyor
      // İleride yerel şifre kontrolü eklenebilir
      final offlineUser = UserModel(
        id: 'offline_admin',
        name: 'Offline Admin',
        email: email,
        role: 'admin',
      );
      await _userRepository.saveUser(offlineUser);
      return offlineUser;
    }

    try {
      final UserCredential credential = await _auth!.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Hibrit repository'den kullanıcıyı al (önce local, yoksa firebase)
      // Ancak signIn durumunda Firebase'den taze veriyi çekip locale kaydetmek daha mantıklı olabilir
      // HybridUserRepository listener'ı zaten Firebase değişikliklerini dinliyor.
      // Biz burada manuel olarak da check edebiliriz.
      
      // Önce local'e bak
      var userModel = await _userRepository.getUser(credential.user!.uid);
      
      if (userModel == null) {
        // Localde yoksa Firestore'dan çek
        final userDoc = await _firestore!.collection('users').doc(credential.user!.uid).get();
        if (userDoc.exists) {
           final userData = userDoc.data()!;
           userModel = UserModel(
             id: credential.user!.uid,
             name: userData['name'] ?? credential.user!.displayName ?? 'Kullanıcı',
             email: credential.user!.email ?? email,
             role: userData['role'] ?? 'user',
           );
           // Locale kaydet
           await _userRepository.saveUser(userModel);
        } else {
           // Firestore'da da yoksa oluştur
           userModel = UserModel(
             id: credential.user!.uid,
             name: credential.user!.displayName ?? 'Kullanıcı',
             email: credential.user!.email ?? email,
             role: 'user',
           );
           await _userRepository.saveUser(userModel);
        }
      }
      
      return userModel;

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
      if (_auth == null) throw Exception('Firebase Auth başlatılamadı');
      final UserCredential credential = await _auth!.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Kullanıcı adını güncelle
      await credential.user!.updateDisplayName(name);

      // Kullanıcı modelini oluştur
      final newUser = UserModel(
        id: credential.user!.uid,
        name: name,
        email: email,
        role: 'user',
      );

      // Hibrit repository ile kaydet (hem local hem firebase)
      await _userRepository.saveUser(newUser);

      return newUser;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Kayıt işlemi sırasında bir hata oluştu: $e');
    }
  }

  // Google ile giriş yapma
  Future<UserModel> signInWithGoogle() async {
    if (_auth == null) throw Exception('Google girişi bu platformda desteklenmiyor');
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

      final UserCredential userCredential = await _auth!.signInWithCredential(credential);
      final User user = userCredential.user!;

      // Kullanıcıyı kontrol et veya oluştur
      var userModel = await _userRepository.getUser(user.uid);
      
      if (userModel == null) {
        final userDoc = await _firestore!.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
           final userData = userDoc.data()!;
           userModel = UserModel(
             id: user.uid,
             name: userData['name'] ?? user.displayName ?? 'Kullanıcı',
             email: user.email ?? '',
             role: userData['role'] ?? 'user',
           );
        } else {
           userModel = UserModel(
             id: user.uid,
             name: user.displayName ?? 'Kullanıcı',
             email: user.email ?? '',
             role: 'user',
           );
        }
        await _userRepository.saveUser(userModel);
      }

      return userModel;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Google ile giriş sırasında hata: $e');
    }
  }

  // Şifre sıfırlama
  Future<void> resetPassword(String email) async {
    if (_auth == null) return;
    try {
      await _auth!.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Şifre sıfırlama işlemi sırasında bir hata oluştu: $e');
    }
  }

  // Çıkış yapma
  Future<void> signOut() async {
    try {
      final googleSignIn = GoogleSignIn();
      await googleSignIn.signOut();
      await _auth?.signOut();
    } catch (e) {
      throw Exception('Çıkış işlemi sırasında bir hata oluştu: $e');
    }
  }

  // Kullanıcı bilgilerini Firestore'dan al
  Future<UserModel?> getUserData(String uid) async {
    try {
      // Önce local/hibrit repository'den dene
      final user = await _userRepository.getUser(uid);
      if (user != null) return user;

      // Yoksa Firestore'dan manuel çek (fallback)
      if (_firestore == null) return null;
      final userDoc = await _firestore!.collection('users').doc(uid).get();
      if (userDoc.exists) {
        final userData = userDoc.data()!;
        final userModel = UserModel(
          id: uid,
          name: userData['name'] ?? 'Kullanıcı',
          email: userData['email'] ?? '',
          role: userData['role'] ?? 'user',
        );
        // Locale kaydet
        await _userRepository.saveUser(userModel);
        return userModel;
      }
      return null;
    } catch (e) {
      throw Exception('Kullanıcı bilgileri alınırken bir hata oluştu: $e');
    }
  }

  // Kullanıcı bilgilerini güncelle
  Future<void> updateUserData(String uid, Map<String, dynamic> data) async {
    try {
      await _firestore?.collection('users').doc(uid).update(data);
      // Not: HybridUserRepository listener'ı bunu yakalayıp locale yansıtacaktır.
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
