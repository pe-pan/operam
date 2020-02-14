import 'dart:convert';
import 'dart:io';
import 'log.dart';

class Secrets {
  var _data;

  //Loads the secret values out of the provided file and removes it afterwards
  Secrets(String file_name, bool remove) {
    _loadFile(file_name, remove);
  }

  //waits until it reads the file (it does not have to exist)
  void _loadFile(String file_name, bool remove) {
    iLog.i('Loading secrets from $file_name');
    var success = false;
    do {
      try {
        var content = File(file_name).readAsStringSync();
        _data = json.decode(content);
        if (remove) {
          iLog.i('Removing file $file_name');
          File(file_name).delete();
        }
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
