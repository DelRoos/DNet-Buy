class Validators {
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'L\'adresse email est requise.';
    }
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!emailRegex.hasMatch(value)) {
      return 'Veuillez entrer une adresse email valide.';
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Le mot de passe est requis.';
    }
    if (value.length < 6) {
      return 'Le mot de passe doit contenir au moins 6 caractères.';
    }
    return null;
  }

  static String? validateNotEmpty(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return 'Le champ "$fieldName" ne peut pas être vide.';
    }
    return null;
  }

  static String? validateCameroonianPhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Le numéro de téléphone est requis.';
    }

    // 1. On nettoie le numéro en enlevant les espaces, les parenthèses et les tirets.
    String cleanedNumber = value.replaceAll(RegExp(r'[\s\-\(\)]'), '');

    // 2. On gère le préfixe international (+237 ou 237)
    if (cleanedNumber.startsWith('+237')) {
      cleanedNumber = cleanedNumber.substring(4);
    } else if (cleanedNumber.startsWith('237')) {
      cleanedNumber = cleanedNumber.substring(3);
    }

    // 3. Après nettoyage, le numéro doit commencer par 6 et avoir 9 chiffres au total.
    //    On utilise une expression régulière pour vérifier ce format.
    //    ^      : début de la chaîne
    //    6      : doit commencer par le chiffre 6
    //    \d{8}  : doit être suivi par exactement 8 autres chiffres
    //    $      : fin de la chaîne
    final phoneRegex = RegExp(r'^6\d{8}$');

    if (!phoneRegex.hasMatch(cleanedNumber)) {
      return 'Veuillez entrer un numéro camerounais valide (ex: 699123456).';
    }

    // Si toutes les vérifications passent, le numéro est valide.
    return null;
  }
}
