import 'dart:io';
import 'package:ansicolor/ansicolor.dart';
import 'package:args/args.dart';
import 'package:path/path.dart' as path;

final greenPen = AnsiPen()..green();
final redPen = AnsiPen()..red();
final yellowPen = AnsiPen()..yellow();
late bool dryRun;
const String retouchFileName = '.retouch';

Future<int> main(List<String> arguments) async {
  late bool help;
  var parser = ArgParser();
 
  try {
    parser.addFlag('help', abbr: 'h', negatable: false, help: 'Print this usage information.');
    parser.addFlag('dry-run', negatable: false, help: 'Show what files will be copied without actually copying them');
    var argResults = parser.parse(arguments);
    help = argResults['help'] as bool;
    dryRun = argResults['dry-run'] as bool;
  } catch(e) {
    help = true;
    stderr.writeln(e);
    return(-1);
  }

  if (help) {
    return(await printUsage(parser.usage));
  }

  return(retouch());
}

Future<int> printUsage(String usage) async {
  stdout.writeln('CLI to keep track of files which have been touched');
  stdout.writeln('\nUsage:');
  stdout.writeln('  retouch [--help]');
  stdout.writeln('  retouch [--dry-run]');
  stdout.writeln('\nArguments:\n');
  stdout.writeln(usage);
  return(0);
}

Future<int> retouch() async {
  stdout.write('Scanning folders ... ');
  List<Directory> folders = [];
  var dir = Directory.current;
  await for (var file in dir.list(recursive: true, followLinks: false)) {
    if(file is Directory) {
      folders.add(file);
    }
  }
  stdout.writeln(greenPen("done"));

  for (var folder in folders) {
    stdout.writeln('Retouching files in: ${folder.path.replaceAll(dir.path, '.')}');
    if (fileExists(fileName: retouchFileName, filePath: folder.path)) {
      await processRetouchFile(folder);
    }
    
    stdout.write('Generating retouch file ... ');
    await generateRetouchFile(folder);
    stdout.write('${greenPen("done")}\n');
  }

  return(0);
}

Future<bool> generateRetouchFile(Directory folder) async {
  // Read all files in the folder & write their names with last modified timestamp in retouchFileName
  var retouchFile = File(path.join(folder.path, retouchFileName));
  var retouchFileLines = <String>[];
  await for (var file in folder.list(recursive: false, followLinks: false)) {
    if(file is File && !file.path.endsWith(retouchFileName)) {
      retouchFileLines.add('${path.basename(file.path)}|${file.lastModifiedSync().toIso8601String()}');
    }
  }
  await retouchFile.writeAsString(retouchFileLines.join('\n'));
  return true;
}

Future<void> processRetouchFile(Directory folder) async {
  var retouchFile = File(path.join(folder.path, retouchFileName));
  var retouchFileLines = await retouchFile.readAsLines();
  for (var eachLine in retouchFileLines) {
    var eachLineSplit = eachLine.split('|');
    var fileName = eachLineSplit[0];
    var fileTime = DateTime.parse(eachLineSplit[1]);
    var file = File(path.join(folder.path, fileName));
    if (file.existsSync()) {
      if (file.lastModifiedSync() != fileTime) {
        if (!dryRun) {
          await file.setLastModified(fileTime);
        }
      }
    }
  }
  return;
}

String truncate(String text) {
  var width = stdout.terminalColumns - 4;
  late String returnValue;
  if (text.length > width) {
    returnValue = '\r...${text.substring(text.length - width)}';
  } else {
    returnValue = '\r$text';
  }
  return(returnValue);
}

bool fileExists({ required String fileName, required String filePath }) {
  var f = File(path.join(filePath, fileName));
  return(f.existsSync());
}

