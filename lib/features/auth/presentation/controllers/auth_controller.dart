import 'package:get/get.dart';
import '../../../../core/utils/error_handler.dart';
import '../../../../core/services/state_service.dart';
import '../../../../core/services/auth_service.dart';

class AuthController extends GetxController {
  // Kullanıcı girişi için email ve şifre
  final email = ''.obs;
  final password = ''.obs;

  // Giriş durumu
  final isLoading = false.obs;
  final isLoggedIn = false.obs;

  // Servisler
  StateService? _stateService;
  final AuthService _authService = AuthService();

  @override
  void onReady() {
    super.onReady();
    // StateService'i güvenli şekilde al
    if (Get.isRegistered<StateService>()) {
      _stateService = Get.find<StateService>();
    }
  }

  @override
  void onInit() {
    super.onInit();
    // Kullanıcı durumunu dinle
    _authService.authStateChanges.listen((user) {
      if (user != null) {
        _loadUserData(user.uid);
      } else {
        _stateService?.currentUser = null;
        isLoggedIn.value = false;
      }
    });
  }

  Future<void> _loadUserData(String uid) async {
    try {
      final userData = await _authService.getUserData(uid);
      if (userData != null) {
        _stateService?.currentUser = userData;
        isLoggedIn.value = true;
      }
    } catch (e) {
      ErrorHandler.handleApiError(e);
    }
  }

  Future<void> login() async {
    if (email.value.isEmpty || password.value.isEmpty) {
      ErrorHandler.handleValidationError('E-posta ve şifre alanları zorunludur');
      return;
    }

    isLoading.value = true;
    try {
      final user = await _authService.signInWithEmailAndPassword(
        email.value.trim(),
        password.value,
      );

      // Kullanıcıyı state servisine kaydet
      _stateService?.currentUser = user;

      isLoggedIn.value = true;
      ErrorHandler.showSuccessMessage('Giriş başarılı');
      Get.offAllNamed('/home');
    } catch (e) {
      ErrorHandler.handleApiError(e, customMessage: e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  // Google ile giriş yapma
  Future<void> signInWithGoogle() async {
    isLoading.value = true;
    try {
      final user = await _authService.signInWithGoogle();

      // Kullanıcıyı state servisine kaydet
      _stateService?.currentUser = user;

      isLoggedIn.value = true;
      ErrorHandler.showSuccessMessage('Google ile giriş başarılı');
      Get.offAllNamed('/home');
    } catch (e) {
      if (e.toString().contains('iptal edildi')) {
        // Kullanıcı iptal ettiyse sessizce geç
      } else {
        ErrorHandler.handleApiError(e, customMessage: e.toString());
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> signUp(String name) async {
    if (email.value.isEmpty || password.value.isEmpty || name.isEmpty) {
      ErrorHandler.handleValidationError('Tüm alanlar zorunludur');
      return;
    }

    if (password.value.length < 6) {
      ErrorHandler.handleValidationError('Şifre en az 6 karakter olmalıdır');
      return;
    }

    isLoading.value = true;
    try {
      final user = await _authService.signUpWithEmailAndPassword(
        email.value.trim(),
        password.value,
        name,
      );

      // Kullanıcıyı state servisine kaydet
      _stateService?.currentUser = user;

      isLoggedIn.value = true;
      ErrorHandler.showSuccessMessage('Kayıt başarılı');
      Get.offAllNamed('/home');
    } catch (e) {
      ErrorHandler.handleApiError(e, customMessage: e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> resetPassword() async {
    if (email.value.isEmpty) {
      ErrorHandler.handleValidationError('E-posta adresi gerekli');
      return;
    }

    isLoading.value = true;
    try {
      await _authService.resetPassword(email.value.trim());
      ErrorHandler.showSuccessMessage('Şifre sıfırlama e-postası gönderildi');
    } catch (e) {
      ErrorHandler.handleApiError(e, customMessage: e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> logout() async {
    try {
      await _authService.signOut();
      
      // Kullanıcıyı state servisinden temizle
      _stateService?.currentUser = null;
      _stateService?.clearCart();

      isLoggedIn.value = false;
      ErrorHandler.showInfoMessage('Çıkış yapıldı');
      Get.offAllNamed('/login');
    } catch (e) {
      ErrorHandler.handleApiError(e, customMessage: 'Çıkış işlemi sırasında hata oluştu');
    }
  }

  // Kullanıcı durumunu kontrol et
  bool get isAdmin {
    // TEST İÇİN HER ZAMAN TRUE DÖN
    return true; 
    // return _stateService?.currentUser?.role == 'admin' ?? false;
  }

  // Mevcut kullanıcıyı al
  Rx<dynamic> get currentUser {
    return Rx(_stateService?.currentUser);
  }
}