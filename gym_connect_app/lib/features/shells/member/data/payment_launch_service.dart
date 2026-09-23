import 'package:url_launcher/url_launcher.dart';

class PaymentLaunchService {
  static Future<bool> launchPaymentMethod({
    required String method,
    required double amount,
    required String invoiceNumber,
  }) async {
    final cleanMethod = method.toLowerCase();
    Uri appUri;
    Uri webUri;

    if (cleanMethod.contains('jazz')) {
      appUri = Uri.parse('jazzcash://pay?amount=${amount.toInt()}&invoice=$invoiceNumber');
      webUri = Uri.parse('https://payments.jazzcash.com.pk/');
    } else if (cleanMethod.contains('easy')) {
      appUri = Uri.parse('easypaisa://pay?amount=${amount.toInt()}&invoice=$invoiceNumber');
      webUri = Uri.parse('https://easypay.easypaisa.com.pk/');
    } else {
      appUri = Uri.parse('https://checkout.stripe.com/pay');
      webUri = Uri.parse('https://checkout.stripe.com/pay');
    }

    try {
      if (await canLaunchUrl(appUri)) {
        return await launchUrl(appUri, mode: LaunchMode.externalApplication);
      }
      return await launchUrl(webUri, mode: LaunchMode.externalApplication);
    } catch (_) {
      try {
        return await launchUrl(webUri, mode: LaunchMode.externalApplication);
      } catch (_) {
        return false;
      }
    }
  }

  static Future<bool> launchWebPortal(String method) async {
    final clean = method.toLowerCase();
    final url = clean.contains('jazz')
        ? 'https://payments.jazzcash.com.pk/'
        : (clean.contains('easy')
            ? 'https://easypay.easypaisa.com.pk/'
            : 'https://checkout.stripe.com/');
    try {
      return await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }
}
