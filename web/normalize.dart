const String czechArea = '420';
const String intArea = '00';
const int phoneLength = 9; //length of a valid phone number
const String plusChar = '+'; //international phone area prefix

class NormalizedPhone {
  NormalizedPhone(String number) {
    this.number = number;
  }

  String number; //original number typed by user
  String error; //error showing what's wrong in the typed number
  String displayable; //nicely formatted number (if typed well); otherwise empty
  String normalized; //number that can be used to send SMS to (if typed well)

  void normalize() {
    var value = number.trim();
    String error_message;
    var norm_message = '';

    if (value.startsWith(plusChar)) {
      // normalize + -> 00
      value = intArea + value.substring(plusChar.length);
    }
    value = value.replaceAll(RegExp('\\D'), ''); // remove all non-digits
    if ((intArea + czechArea).startsWith(value)) {
      // if typing 00420 or 0042 or 004 or 00 or 0, do nothing
      error_message = '';
    } else {
      if (value.startsWith(intArea)) {
        if (!value.substring(intArea.length).startsWith(czechArea)) {
          error_message =
              'Only Czech code area ($plusChar$czechArea) is supported';
        } else {
          value = value.substring(intArea.length + czechArea.length);
        }
      }

      if (error_message == null) {
        if (!value.startsWith(RegExp('6|7'))) {
          error_message =
              'Only mobile phone numbers starting with 6 or 7 digits are supported';
        } else if (value.length < phoneLength - 1) {
          error_message = '${phoneLength - value.length} more digits to type';
        } else if (value.length == phoneLength - 1) {
          error_message = 'last digit to type';
        } else if (value.length > phoneLength) {
          error_message = 'too many digits';
        } else {
          error_message = '';
          norm_message = value.substring(0, phoneLength ~/ 3) +
              ' ' +
              value.substring(phoneLength ~/ 3, 2 * phoneLength ~/ 3) +
              ' ' +
              value.substring(2 * phoneLength ~/ 3, phoneLength);
        }
      }
    }

    error = error_message;
    displayable = norm_message;
    if (error_message.isEmpty && value.length == phoneLength) {
      normalized = czechArea + value;
    } else {
      normalized = '';
    }
  }
}
