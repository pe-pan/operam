import 'package:postgres/postgres.dart';
import 'log.dart';

PostgreSQLConnection connection;
Future<dynamic> opened;
const String tableName = 'phones';

Future<dynamic> connect(String db, String username, password) async {
  iLog.i('Connecting to PSQL...');
  connection = PostgreSQLConnection('localhost', 5432, db,
      username: username, password: password);
  opened = connection.open();
  return opened;
}

void create_db() async {  //not used; table created during build time / startup
  iLog.i('Creating DB table...');
  await opened;
  await connection.query('''
  CREATE TABLE $tableName(
      token VARCHAR(20) PRIMARY KEY,
      operation VARCHAR (1) NOT NULL);
      ''');
}

void insert(String token, String operation) async {
  iLog.i('Inserting $token, $operation...');
  await opened;
  connection.query(
      'INSERT INTO $tableName (token, operation) VALUES (@token, @operation);',
      substitutionValues: {
        'token': token,
        'operation': operation
      });
}

Future<String> get(String token) async {
  iLog.i('Getting $token...');
  await opened;
  List<dynamic> result = await connection.query(
      'SELECT operation FROM $tableName WHERE token = @token;',
      substitutionValues: {'token': token});
  if (result.isEmpty) {
    return null;
  } else {
    return result[0][0];
  }
}

Future<PostgreSQLResult> delete(String token) async {
  iLog.i('Deleting $token...');
  await opened;
  return connection
      .query('DELETE FROM $tableName WHERE token = @token;', substitutionValues: {
    'token': token
  });
}
