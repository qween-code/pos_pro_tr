class Validators {
  // Email validasyonu
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Opsiyonel alan
    }

    final emailRegExp = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegExp.hasMatch(value)) {
      return 'Geçerli bir e-posta adresi girin';
    }
    return null;
  }

  // Telefon numarası validasyonu
  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Lütfen telefon numarası girin';
    }

    // Sadece rakamlar ve en az 10 karakter
    final phoneRegExp = RegExp(r'^[0-9]{10,15}$');
    if (!phoneRegExp.hasMatch(value)) {
      return 'Geçerli bir telefon numarası girin';
    }
    return null;
  }

  // Boş olmayan alan validasyonu
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return 'Lütfen $fieldName girin';
    }
    return null;
  }

  // Minimum uzunluk validasyonu
  static String? validateMinLength(String? value, int minLength, String fieldName) {
    if (value == null || value.isEmpty) {
      return 'Lütfen $fieldName girin';
    }
    if (value.length < minLength) {
      return '$fieldName en az $minLength karakter olmalıdır';
    }
    return null;
  }

  // Sadece rakam validasyonu
  static String? validateNumber(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return 'Lütfen $fieldName girin';
    }

    if (double.tryParse(value) == null) {
      return 'Geçerli bir $fieldName girin';
    }
    return null;
  }

  // Pozitif sayı validasyonu
  static String? validatePositiveNumber(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return 'Lütfen $fieldName girin';
    }

    final number = double.tryParse(value);
    if (number == null) {
      return 'Geçerli bir $fieldName girin';
    }

    if (number <= 0) {
      return '$fieldName pozitif olmalıdır';
    }
    return null;
  }

  // Yüzde validasyonu (0-100 arası)
  static String? validatePercentage(String? value) {
    if (value == null || value.isEmpty) {
      return 'Lütfen yüzde değeri girin';
    }

    final number = double.tryParse(value);
    if (number == null) {
      return 'Geçerli bir yüzde değeri girin';
    }

    if (number < 0 || number > 100) {
      return 'Yüzde değeri 0-100 arasında olmalıdır';
    }
    return null;
  }

  // Tarih validasyonu (geçmiş tarih kontrolü)
  static String? validateDateNotInPast(DateTime? date, String fieldName) {
    if (date == null) {
      return 'Lütfen $fieldName seçin';
    }

    final now = DateTime.now();
    if (date.isBefore(DateTime(now.year, now.month, now.day))) {
      return '$fieldName geçmiş bir tarih olamaz';
    }
    return null;
  }

  // Tarih aralığı validasyonu
  static String? validateDateRange(DateTime? startDate, DateTime? endDate) {
    if (startDate == null || endDate == null) {
      return 'Lütfen tarih aralığını seçin';
    }

    if (startDate.isAfter(endDate)) {
      return 'Başlangıç tarihi bitiş tarihinden sonra olamaz';
    }
    return null;
  }
}