/// Detects and flags contact/payment bypass attempts in chat messages.
class AntiBypassService {
  AntiBypassService._();

  static final _phonePattern = RegExp(
    r'(\+?\d{1,3}[\s\-]?)?(\(?\d{2,4}\)?[\s\-]?)?\d{3,4}[\s\-]?\d{3,4}',
  );
  static final _emailPattern = RegExp(
    r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}',
  );
  static final _whatsappPattern = RegExp(
    r'(whatsapp|wa\.me|wasap|w\.a\.p)',
    caseSensitive: false,
  );
  static final _externalPaymentPattern = RegExp(
    r'(bank transfer|bank in|maybank|cimb|touch n go|tng|duitnow|paynow|gopay|ovo|dana|direct payment|pay outside|pay me directly)',
    caseSensitive: false,
  );

  static BypassScanResult scan(String message) {
    final flags = <BypassFlag>[];

    if (_phonePattern.hasMatch(message)) {
      flags.add(BypassFlag(type: BypassType.phoneNumber, severity: BypassSeverity.high));
    }
    if (_emailPattern.hasMatch(message)) {
      flags.add(BypassFlag(type: BypassType.email, severity: BypassSeverity.medium));
    }
    if (_whatsappPattern.hasMatch(message)) {
      flags.add(BypassFlag(type: BypassType.whatsapp, severity: BypassSeverity.high));
    }
    if (_externalPaymentPattern.hasMatch(message)) {
      flags.add(BypassFlag(type: BypassType.externalPayment, severity: BypassSeverity.critical));
    }

    return BypassScanResult(
      originalMessage: message,
      flags: flags,
      maskedMessage: flags.isEmpty ? message : _maskSensitiveContent(message),
      shouldFlag: flags.any((f) => f.severity.index >= BypassSeverity.medium.index),
    );
  }

  static String _maskSensitiveContent(String message) {
    var result = message.replaceAllMapped(_emailPattern, (_) => '[email hidden]');
    result = result.replaceAllMapped(_phonePattern, (_) => '[phone hidden]');
    return result;
  }
}

enum BypassType { phoneNumber, email, whatsapp, externalPayment }

enum BypassSeverity { low, medium, high, critical }

class BypassFlag {
  final BypassType type;
  final BypassSeverity severity;

  const BypassFlag({required this.type, required this.severity});
}

class BypassScanResult {
  final String originalMessage;
  final String maskedMessage;
  final List<BypassFlag> flags;
  final bool shouldFlag;

  const BypassScanResult({
    required this.originalMessage,
    required this.maskedMessage,
    required this.flags,
    required this.shouldFlag,
  });
}
