import 'dart:io';
import 'dart:math';
import 'dart:convert';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:shortid/shortid.dart';
import 'package:twitter/twitter.dart';
import 'package:http/http.dart' as http;
import 'db.dart' as db;
import '../web/constants.dart' as con;
import '../web/normalize.dart';
import 'secrets.dart';
import 'log.dart';

Secrets _secrets;

Future main(List<String> secretsFile) async {
  if (secretsFile.length != 1) {
    eLog.e(
        'Provide a single argument pointing to a json file with all secret keys');
    exit(-1);
  }
  iLog.i('Server initialization...');

  _secrets = Secrets(secretsFile[0]);

  final dbProps = _secrets.getCategory('db');
  await db.connect(
      dbProps['username'], dbProps['username'], dbProps['password']);

//  await db.create_db();

  final server = await HttpServer.bind(
    InternetAddress.loopbackIPv4,
    4041,
  );
  await for (final request in server) {
    iLog.i('Handling request: $request');
    handleRequest(request);
  }
  iLog.i('Server started...');
}

void handleRequest(HttpRequest request) {
  try {
    if (request.method == 'POST') {
      handlePost(request);
    } else {
      _handleError(request, HttpStatus.methodNotAllowed, 'Unsupported method',
          request.method);
    }
    iLog.i('Request handled.');
  } catch (e) {
    eLog.e('Exception in handleRequest: $e');
  }
}

void handlePost(HttpRequest request) async {
  final content = await utf8.decoder.bind(request).join();
  Map params = Uri.splitQueryString(content);
  final operation = request.uri.pathSegments?.first;
  switch (operation) {
    case 'register_phone':
      final id = params['id'];
      final number = params['phone'];
      final normalizedPhone = NormalizedPhone(number);
      normalizedPhone.normalize();
      final error = normalizedPhone.error;
      final normNumber = normalizedPhone.normalized;
      if (normNumber == null || normNumber.isEmpty) {
        _handleError(request, HttpStatus.notAcceptable, error, number);
      } else {
        final displayable = Uri.encodeFull(normalizedPhone.displayable);
        final token = getToken();
        storeData(token, id);
        final error = await sendSMS('Type this token: $token', normNumber);
        if (error == null) {
          request.response
            ..statusCode = HttpStatus.accepted
            ..redirect(Uri.parse(
                'http://localhost:8080/process_message.html?phone=$displayable&id=$id'))
            ..close();
        } else {
          _handleError(
              request, HttpStatus.internalServerError, error, normNumber);
        }
      }
      break;
    case 'process_message':
      final token = params['token'];
      final id = await db.get(token);
      if (id == null) {
        _handleError(request, HttpStatus.notAcceptable, 'Invalid token', token);
      } else {
        dynamic error;
        dynamic info;
        final messageText = params['message'];
        switch (id) {
          case con.email:
            error = await sendEmail(messageText);
            info = messageText;
            break;
          case con.tweet:
            error = await tweet(messageText);
            info = messageText;
            break;
          default:
            error = 'Unknown operation';
            info = id;
        }
        removeData(token);
        if (error != null) {
          _handleError(request, HttpStatus.methodNotAllowed, error, info);
        } else {
          final message_enc = Uri.encodeComponent(messageText);
          request.response
            ..statusCode = HttpStatus.accepted
            ..redirect(Uri.parse(
                'http://localhost:8080/message_sent.html?id=$id&message=$message_enc'))
            ..close();
        }
      }
      break;
    default:
      _handleError(request, HttpStatus.methodNotAllowed, 'Unknown operation', operation);
  }
}

void _handleError(
    HttpRequest request, int httpStatus, String error, String info) {
  final error_enc = Uri.encodeComponent(error);
  final info_enc = Uri.encodeComponent(info);
  request.response
    ..statusCode = httpStatus
    ..redirect(Uri.parse(
        'http://localhost:8080/error.html?error=$error_enc&info=$info_enc'))
    ..close();
}

void storeData(String token, String id) {
  iLog.d('Storing $token, $id');
  db.insert(token, id);
}

void removeData(String token) {
  iLog.d('Deleting $token');
  db.delete(token);
}

Future<String> sendSMS(String message, String phone) async {
  iLog.i('Sending SMS: $message to: $phone');
  final url = 'https://gatewayapi.com/rest/mtsms';
  try {
    final response = await http.post(url, body: {
      'token': _secrets.get('sms', 'token'),
      'sender': 'Info',
      'message': message,
      'recipients.0.msisdn': phone
    });
    iLog.i('Response status: ${response.statusCode}');
    iLog.i('Response body: ${response.body}');
    if (response.statusCode > 299) {
      return response.body;
    }
    return null;
  } catch (e) {
    eLog.e('SMS not sent', e);
    return e.toString();
  }
}

dynamic sendEmail(String messageText) async {
  iLog.i('Sending e-mail: ' + messageText);
  final host = _secrets.get('aws', 'host');
  final username = _secrets.get('aws', 'username');
  final password = _secrets.get('aws', 'password');
  final from = 'petr.panuska@microfocus.com';
  final fromName = 'Petr Panuska';
  final recipient = 'operam@yopmail.com';

  final smtpServer = SmtpServer(host, username: username, password: password);

  final message = Message()
    ..from = Address(from, fromName)
    ..recipients.add(recipient)
    ..subject = 'Operam demo :: 😀 :: ${DateTime.now()}'
    ..text = messageText
    ..html = '<p>$messageText</p>';

  try {
    final sendReport = await send(message, smtpServer);
    iLog.i('Message sent: ' + sendReport.toString());
  } on MailerException catch (e) {
    eLog.e('Message not sent.', e);
    return e.toString();
  }
}

dynamic tweet(String message) async {
  iLog.i('Tweeting: ' + message);
  final consumer_key = _secrets.get('twitter', 'consumer_key');
  final consumer_secret = _secrets.get('twitter', 'consumer_secret');
  final access_token = _secrets.get('twitter', 'access_token');
  final access_secret = _secrets.get('twitter', 'access_secret');
  final twitter =
      Twitter(consumer_key, consumer_secret, access_token, access_secret);
  final body = {
    'status': message,
  };
  try {
    final response =
        await twitter.request('POST', 'statuses/update.json', body: body);
    iLog.i(response.body);
    if (response.statusCode > 299) {
      return response.body;
    }
    return null;
  } catch (e) {
    eLog.e('Exception', e);
    return e.toString();
  } finally {
    twitter.close();
  }
}

const tokenCharacters =
    '23456789abcdefghijkmnopqrstuvwxyzABCDEFGHIJKLMNPRSTUVWXYZ'; //do not use 0, 1, l, O and Q (might be confusing)
final random = Random();

String getToken() {
  shortid.characters(tokenCharacters);
  final shortId = shortid.generate();
  iLog.d('shid: $shortId');
  final b = random.nextInt(tokenCharacters.length);
  final e = random.nextInt(tokenCharacters.length);

  final token = tokenCharacters[b] +
      shortId.substring(0, 2) +
      '.' +
      shortId.substring(3, 6) +
      '.' +
      shortId.substring(7) +
      tokenCharacters[e];
  iLog.i('token: $token');
  return token;
}
