import 'package:logger/logger.dart';

final iLog = Logger(
  printer: SimplePrinter(printTime: true),
);

final eLog = Logger(
  printer: PrettyPrinter(methodCount: 2, printTime: true),
);

