import 'dart:io';
import 'package:ansicolor/ansicolor.dart';

final greenPen = AnsiPen()..green();
final redPen = AnsiPen()..red();
final yellowPen = AnsiPen()..yellow();
final String clearLine = '\r';
final String aboveLine = '\x1b[1A\r';

Future<void> main(List<String> arguments) async {
  stdout.writeln('This line is written to stdout');
  stdout.write('Line1:');
  stdout.write('\x1b[1A\r');
  // stdout.write('\r');
  stdout.write('***');
}
