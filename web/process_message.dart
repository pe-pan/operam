import 'dart:html';
import 'constants.dart' as con;

void main() {
  var id = Uri.base.queryParameters['id'];
  var phone = Uri.base.queryParameters['phone'];
  var title = 'Wrong parameters';
  var submit = 'Nope!';
  var link = 'http://panuska.net';
  var innerHtml = "<a id='linkId'>tweeted or e-mailed</a>";
  var warning;
  switch (id) {
    case con.email:
      title = 'Send an e-mail';
      innerHtml = 'sent to <a id="linkId">operam@yopmail.com</a>';
      link = 'http://www.yopmail.com/en/?login=operam';
      submit = 'Email!';
      warning = true;
      break;
    case con.tweet:
      title = 'Tweet your status';
      innerHtml = 'tweeted to <a id="linkId">operam</a>';
      link = 'https://twitter.com/operam14';
      submit = 'Tweet!';
      warning = false;
      break;
  }
  document.title = title;
  querySelector('#operationId').innerHtml = innerHtml;
  querySelector('#linkId').setAttribute('href', link);
  querySelector('#linkId').setAttribute('target', '_blank'); //open in a new tab
  querySelector('#phoneId').text = phone;
  querySelector("input[type='submit']").setAttribute('value', submit);
  !warning
      ? querySelector('#tweet_warning').removeAttribute('hidden')
      : querySelector('#tweet_warning').setAttribute('hidden', '');
}
