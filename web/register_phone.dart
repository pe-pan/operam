import 'dart:html';
import 'normalize.dart';

void main() {
  querySelector('input[name="phone"]')
      .addEventListener('input', validate_phone);
}

void validate_phone(Event event) {
  InputElement input = querySelector('input[name="phone"]');
  var value = input.value.trim();

  var phone = NormalizedPhone(value);

  phone.normalize();

  querySelector('#validation').text = phone.error;
  querySelector('#normalized').text = phone.displayable.isNotEmpty
      ? 'Message will be sent to +420 ' + phone.displayable
      : '';
}
