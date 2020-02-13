import 'dart:html';
import 'constants.dart' as con;

/*
void main() {
  var where = Uri.base.queryParameters['where'];
  var message = Uri.base.queryParameters['message'];
  var title = Uri.base.queryParameters['title'];
  querySelector('#where').text = where;
  querySelector('#message').text = message;
  document.title = title;


}
*/

void main() {
  var id = Uri.base.queryParameters['id'];
  var message = Uri.base.queryParameters['message'];
  var title ='Wrong parameters';
  var what = 'You';
  var link = 'http://panuska.net';
  var innerHtml ="<a id='linkId'>tweeted or e-mailed</a>";
  switch (id) {
    case con.email:
      title = 'Emailed!';
      innerHtml = 'Your message has been sent to <a id="linkId">operam@yopmail.com</a>';
      link = 'http://www.yopmail.com/en/?login=operam';
      what = 'Your message: $message';
      break;
    case con.tweet:
      title = 'Tweeted!';
      innerHtml = 'Your status has been tweeted to <a id="linkId">operam</a>';
      link = 'https://twitter.com/operam14';
      what = 'Your status: $message';
      break;
  }
  document.title = title;
  querySelector('#where').innerHtml = innerHtml;
  querySelector('#linkId').setAttribute('href',link);
  querySelector('#linkId').setAttribute('target','_blank');  //open in a new tab
  querySelector('#message').text = what;
}
