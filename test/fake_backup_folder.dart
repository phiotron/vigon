import 'package:flutter/services.dart';
import 'package:vigon/src/data/backup_folder_service.dart';

/// Thư mục giả trong bộ nhớ.
class FakeFolder implements BackupFolderService {
  final files = <String, Uint8List>{};
  final released = <String>[];
  int writes = 0;
  BackupFolderError? failWith;
  PickedFolder? pickResult;

  @override
  MethodChannel get channel => throw UnimplementedError();

  void _check() {
    final e = failWith;
    if (e != null) throw BackupFolderException(e);
  }

  @override
  Future<PickedFolder?> pickFolder() async {
    _check();
    return pickResult;
  }

  @override
  Future<void> writeFile(String treeUri, String name, Uint8List bytes) async {
    _check();
    writes++;
    files[name] = bytes;
  }

  @override
  Future<List<String>> listFiles(String treeUri) async {
    _check();
    return files.keys.toList();
  }

  @override
  Future<void> deleteFile(String treeUri, String name) async {
    _check();
    files.remove(name);
  }

  @override
  Future<void> releaseFolder(String treeUri) async => released.add(treeUri);
}
