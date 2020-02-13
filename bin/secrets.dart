import 'dart:convert';
import 'dart:io';
import 'log.dart';

class Secrets {
  var _data;

  Secrets(String file_name) {
    _loadFile(file_name);
  }

  //waits until it reads the file (it does not have to exist)
  void _loadFile(String file_name) {
    iLog.i('Loading secrets from $file_name');
    var success = false;
    do {
      try {
        var content = File(file_name).readAsStringSync();
        _data = json.decode(content);
        success = true;
      } catch (e) {
        iLog.i('No file found; waiting 5 sec: $file_name');
        sleep(Duration(seconds: 5));
      }
    } while (!success);
  }

  String get(String category, String key) {
    return _data[category][key];
  }

  Map<String, dynamic> getCategory(String category) {
    return _data[category];
  }
}
