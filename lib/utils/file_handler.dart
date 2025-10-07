import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:http/http.dart' as http;

import 'package:updat/utils/global_options.dart';
import 'package:updat/utils/open_link.dart';

Future<File?> getCustomDownloadFileLocation(String release, String appName) async {
  final downloadDir = await getDownloadsDirectory();
  if (downloadDir == null) {
    throw Exception('Unable to get downloads directory, release: $release');
  }
  final filePath = p.join(
    downloadDir.absolute.path,
    '$appName-$release',
  );
  return File(filePath);
}

Future<File> getDownloadFileLocation(String release, String appName, String extension) async {
  final downloadDir = await getDownloadsDirectory();
  if (downloadDir == null) {
    throw Exception('Unable to get downloads directory');
  }
  final filePath = p.join(
    downloadDir.absolute.path,
    '$appName-$release.$extension',
  );
  // print('$appName-$release.$extension');
  return File(filePath);
}

Future<File> downloadRelease(File file, String url, String appName) async {
  var res = await http.get(
    Uri.parse(url),
    headers: {
      ...UpdatGlobalOptions.downloadReleaseHeaders,
    },
  );
  if (res.statusCode == 200) {
    // print("autoupdate: download res.statusCode 200");
    await file.writeAsBytes(res.bodyBytes);
    if (file.path.endsWith("zip")) {
      final outDir = Directory(p.join(p.dirname(file.path), appName));
      outDir.createSync(recursive: true);
      extractFileToDisk(file.absolute.path, outDir.absolute.path);
    }
    // Return with new installed status
    return file;
  } else {
    // print(
    //   'There was an issue downloading the file, plese try again later.\n'
    //   'Code ${res.statusCode}',
    // );
    throw Exception(
      'There was an issue downloading the file, please try again later.\n'
      'Code ${res.statusCode}',
    );
  }
}

Future<void> openInstaller(File file, String appName) async {
  if (file.existsSync()) {
    if (file.path.endsWith("zip")) {
      final outDir = Directory(p.join(p.dirname(file.path), appName));
      file = File(
          outDir.listSync().firstWhere((e) {
            if (Platform.isWindows) {
              return e.path.endsWith("exe");
            } else {
              return true;
            }
          }).path
      );
    }
    await openUri(Uri(path: file.absolute.path, scheme: 'file'));
  } else {
    // print('Installer does not exists, you have to download it first');
    throw Exception(
      'Installer does not exists, you have to download it first',
    );
  }
}
