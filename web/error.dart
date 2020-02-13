import 'dart:html';

void main() {
  var error = Uri.base.queryParameters['error'];
  var info = Uri.base.queryParameters['info'];
  querySelector('#error').text = error;
  querySelector('#info').text = info;
}
