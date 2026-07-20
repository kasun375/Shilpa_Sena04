import 'package:flutter/services.dart';

class CardNumberInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    var text = newValue.text;

    if (newValue.selection.baseOffset == 0) {
      return newValue;
    }

    var buffer = StringBuffer();
    // Remove all non-digits
    var cleanText = text.replaceAll(RegExp(r'\D'), '');
    
    // Cap at 16 digits
    if (cleanText.length > 16) {
      cleanText = cleanText.substring(0, 16);
    }

    for (int i = 0; i < cleanText.length; i++) {
      buffer.write(cleanText[i]);
      var nonZeroIndex = i + 1;
      if (nonZeroIndex % 4 == 0 && nonZeroIndex != cleanText.length) {
        buffer.write(' ');
      }
    }

    var string = buffer.toString();
    return newValue.copyWith(
        text: string,
        selection: TextSelection.collapsed(offset: string.length));
  }
}

class CardExpiryInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    var text = newValue.text;

    if (newValue.selection.baseOffset == 0) {
      return newValue;
    }

    // Remove all non-digits
    var cleanText = text.replaceAll(RegExp(r'\D'), '');
    
    // Cap at 4 digits (MMYY)
    if (cleanText.length > 4) {
      cleanText = cleanText.substring(0, 4);
    }

    var buffer = StringBuffer();
    for (int i = 0; i < cleanText.length; i++) {
      buffer.write(cleanText[i]);
      var nonZeroIndex = i + 1;
      if (nonZeroIndex == 2 && nonZeroIndex != cleanText.length) {
        buffer.write('/');
      }
    }

    var string = buffer.toString();
    return newValue.copyWith(
        text: string,
        selection: TextSelection.collapsed(offset: string.length));
  }
}
