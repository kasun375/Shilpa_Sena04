import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/stripe_config.dart';

class StripePaymentResult {
  final bool success;
  final String? errorMessage;
  final String? paymentIntentId;

  StripePaymentResult({
    required this.success,
    this.errorMessage,
    this.paymentIntentId,
  });
}

class StripeService {
  static const String _baseUrl = 'https://api.stripe.com/v1';

  /// Process payment from start to finish:
  /// 1. Create Payment Method using the Card details.
  /// 2. Create & Confirm Payment Intent with the Payment Method.
  static Future<StripePaymentResult> processPayment({
    required String cardNumber,
    required String expMonth,
    required String expYear,
    required String cvc,
    required double amount,
    String? currency,
  }) async {
    try {
      // Clean inputs
      final cleanCardNumber = cardNumber.replaceAll(RegExp(r'\s+\b|\b\s+'), '').replaceAll(' ', '');
      final cleanExpMonth = expMonth.trim();
      // Ensure expYear is 4 digits. If 2 digits (e.g. "28"), convert to "2028"
      var cleanExpYear = expYear.trim();
      if (cleanExpYear.length == 2) {
        cleanExpYear = '20$cleanExpYear';
      }
      final cleanCvc = cvc.trim();
      final payCurrency = currency ?? StripeConfig.defaultCurrency;
      final amountInCents = (amount * 100).round();

      final String token;

      if (!StripeConfig.useLiveMode) {
        // In test mode, use Stripe's predefined test tokens directly to bypass
        // raw card API restrictions and publishable key tokenization restrictions.
        if (cleanCardNumber.startsWith('4')) {
          token = 'tok_visa';
        } else if (cleanCardNumber.startsWith('5')) {
          token = 'tok_mastercard';
        } else if (cleanCardNumber.startsWith('37') || cleanCardNumber.startsWith('34')) {
          token = 'tok_amex';
        } else if (cleanCardNumber.startsWith('6')) {
          token = 'tok_discover';
        } else {
          token = 'tok_visa';
        }
        debugPrint('Stripe (Test Mode): Mapping card to test token $token');
      } else {
        // In live mode, tokenize the card details using the publishable key first
        debugPrint('Stripe (Live Mode): Tokenizing card details...');
        final tokenResponse = await http.post(
          Uri.parse('$_baseUrl/tokens'),
          headers: {
            'Authorization': 'Bearer ${StripeConfig.publishableKey}',
            'Content-Type': 'application/x-www-form-urlencoded',
          },
          body: {
            'card[number]': cleanCardNumber,
            'card[exp_month]': cleanExpMonth,
            'card[exp_year]': cleanExpYear,
            'card[cvc]': cleanCvc,
          },
        );

        final tokenData = jsonDecode(tokenResponse.body);
        if (tokenResponse.statusCode != 200) {
          final errorMsg = tokenData['error']?['message'] ?? 'Failed to tokenize card.';
          return StripePaymentResult(success: false, errorMessage: errorMsg);
        }
        token = tokenData['id'] as String;
      }

      debugPrint('Stripe: Creating Payment Method from token...');
      
      // Step 1: Create Payment Method using the token
      final pmResponse = await http.post(
        Uri.parse('$_baseUrl/payment_methods'),
        headers: {
          'Authorization': 'Bearer ${StripeConfig.secretKey}',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'type': 'card',
          'card[token]': token,
        },
      );

      final pmData = jsonDecode(pmResponse.body);
      
      if (pmResponse.statusCode != 200) {
        final errorMsg = pmData['error']?['message'] ?? 'Failed to create payment method.';
        return StripePaymentResult(success: false, errorMessage: errorMsg);
      }

      final paymentMethodId = pmData['id'] as String;
      debugPrint('Stripe: Payment Method created: $paymentMethodId');

      // Step 2: Create and Confirm Payment Intent
      debugPrint('Stripe: Creating and Confirming Payment Intent...');
      final piResponse = await http.post(
        Uri.parse('$_baseUrl/payment_intents'),
        headers: {
          'Authorization': 'Bearer ${StripeConfig.secretKey}',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'amount': amountInCents.toString(),
          'currency': payCurrency.toLowerCase(),
          'payment_method': paymentMethodId,
          'confirm': 'true',
          'automatic_payment_methods[enabled]': 'true',
          'automatic_payment_methods[allow_redirects]': 'never',
        },
      );

      final piData = jsonDecode(piResponse.body);

      if (piResponse.statusCode != 200) {
        final errorMsg = piData['error']?['message'] ?? 'Payment authorization failed.';
        return StripePaymentResult(success: false, errorMessage: errorMsg);
      }

      final status = piData['status'] as String;
      final intentId = piData['id'] as String;

      if (status == 'succeeded') {
        debugPrint('Stripe: Payment Succeeded! Intent: $intentId');
        return StripePaymentResult(
          success: true,
          paymentIntentId: intentId,
        );
      } else {
        debugPrint('Stripe: Payment Status was $status, expected succeeded.');
        return StripePaymentResult(
          success: false,
          errorMessage: 'Payment status is: $status. Complete authentication if required.',
        );
      }
    } catch (e) {
      debugPrint('Stripe Service Exception: $e');
      return StripePaymentResult(
        success: false,
        errorMessage: 'An unexpected error occurred while communicating with Stripe: $e',
      );
    }
  }
}
